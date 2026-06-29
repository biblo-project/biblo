import sys
import os
from sqlalchemy.orm import Session
from sqlalchemy.sql import func

# Ensure project root is in the system path for script execution stability
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from backend.database import SessionLocal
from backend.models.user import User
from backend.models.book import Book
from backend.models.user_genre import UserGenre
from backend.models.book_genre import BookGenre
from backend.models.reading_list import ReadingList
from backend.core.email_recommendation import send_recommendation_email

import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.neighbors import NearestNeighbors


def _book_to_dict(book: Book) -> dict:
    """Small helper so every tier returns the same shape for the email template."""
    return {
        "title": book.title,
        "author": book.author,
        "description": book.description,
    }


# ---------------------------------------------------------------------------
# TIER 1 - Primary: TF-IDF + cosine similarity, same approach as get_curated_books
# ---------------------------------------------------------------------------
def get_ml_recommendations(user_id: int, db: Session, limit: int = 3) -> list:
    """
    Real recommendation engine: builds a TF-IDF "feature soup" per book
    (title + author + description + genres) and finds the books closest
    to the user's preferred-genre profile using cosine similarity.

    Returns an empty list (not an exception) if there isn't enough data
    to make a meaningful recommendation - that's what triggers Tier 2.
    """
    user_genre_rows = db.query(UserGenre.genre).filter(UserGenre.user_id == user_id).all()
    user_genre_list = [g[0] for g in user_genre_rows]

    if not user_genre_list:
        # No preferences set - nothing for TF-IDF to match against
        return []

    books = db.query(Book).all()
    if len(books) < 2:
        # Not enough books to build a meaningful neighborhood
        return []

    book_rows = []
    for b in books:
        genre_rows = db.query(BookGenre.genre).filter(BookGenre.book_id == b.id).all()
        genre_string = " ".join([row[0] for row in genre_rows])
        feature_soup = f"{b.title} {b.author} {b.description or ''} {genre_string}"
        book_rows.append({"id": b.id, "object": b, "features": feature_soup})

    df = pd.DataFrame(book_rows)

    tfidf = TfidfVectorizer(stop_words="english")
    tfidf_matrix = tfidf.fit_transform(df["features"])

    knn = NearestNeighbors(n_neighbors=min(limit, len(df)), metric="cosine", algorithm="brute")
    knn.fit(tfidf_matrix)

    user_profile_text = " ".join(user_genre_list)
    user_vector = tfidf.transform([user_profile_text])

    _, indices = knn.kneighbors(user_vector)

    recommended_books = [df.iloc[idx]["object"] for idx in indices[0]]
    return [_book_to_dict(b) for b in recommended_books]


# ---------------------------------------------------------------------------
# TIER 2 - Fallback: plain SQL joins (no ML), based on reading-list overlap
# ---------------------------------------------------------------------------
def get_sql_join_recommendations(user_id: int, db: Session, limit: int = 3) -> list:
    """
    If the ML tier returns nothing (no preferences, or too few books to
    train on), fall back to a simpler relational approach:

    "Find books that other users with similar reading lists also added,
    that this user hasn't already added themselves."

    Uses your actual ReadingList table - not the 'user_books' table from
    the earlier draft, which doesn't exist in your schema.
    """
    try:
        # Book ids this user has already added, so we don't recommend them again
        already_added = db.query(ReadingList.book_id).filter(
            ReadingList.user_id == user_id
        ).subquery()

        # Other users who share at least one book with this user's reading list
        similar_user_ids = (
            db.query(ReadingList.user_id)
            .filter(
                ReadingList.book_id.in_(db.query(already_added.c.book_id)),
                ReadingList.user_id != user_id,
            )
            .distinct()
        )

        if similar_user_ids.count() == 0:
            return []

        # Books those similar users added, that THIS user hasn't added,
        # ranked by how many similar users added them
        recommended = (
            db.query(Book, func.count(ReadingList.id).label("strength"))
            .join(ReadingList, ReadingList.book_id == Book.id)
            .filter(
                ReadingList.user_id.in_(similar_user_ids),
                ~Book.id.in_(db.query(already_added.c.book_id)),
            )
            .group_by(Book.id)
            .order_by(func.count(ReadingList.id).desc())
            .limit(limit)
            .all()
        )

        return [_book_to_dict(book) for book, strength in recommended]

    except Exception as sql_error:
        print(f"SQL join fallback failed for user {user_id}: {sql_error}")
        return []


# ---------------------------------------------------------------------------
# TIER 3 - Final fallback: random books
# ---------------------------------------------------------------------------
def get_random_recommendations(user_id: int, db: Session, limit: int = 3) -> list:
    """
    Last resort: the user has no preferences AND no reading-list overlap
    with anyone else. Just send them random books rather than nothing.
    """
    books = db.query(Book).order_by(func.random()).limit(limit).all()
    return [_book_to_dict(b) for b in books]


# ---------------------------------------------------------------------------
# The 3-tier chain - this is what the batch loop actually calls
# ---------------------------------------------------------------------------
def get_recommendations_with_fallback(user_id: int, db: Session, limit: int = 3) -> list:
    """
    Tries each tier in order and returns the first one that produces results.
    """
    books = get_ml_recommendations(user_id, db, limit)
    if books:
        return books

    print(f"  Tier 1 (ML) had nothing for user {user_id}, trying Tier 2 (SQL join)...")
    books = get_sql_join_recommendations(user_id, db, limit)
    if books:
        return books

    print(f"  Tier 2 (SQL join) had nothing for user {user_id}, falling back to Tier 3 (random)...")
    return get_random_recommendations(user_id, db, limit)


def run_recommendation_batch_pipeline():
    """
    Queries every user, generates a personalized recommendation set with
    fallback, and emails it.
    """
    print("Initiating global recommendation distribution run...")
    db: Session = SessionLocal()

    try:
        users = db.query(User).all()

        if not users:
            print("Batch execution halted: no users found in the database.")
            return

        print(f"Processing recommendations for {len(users)} registered users...")
        success_count = 0

        for user in users:
            print(f"Computing recommendations for: {user.username} (ID: {user.id})")

            personalized_books = get_recommendations_with_fallback(user.id, db)

            if not personalized_books:
                # Should be very rare - only happens if the books table itself is empty
                print(f"  Skipping {user.username}: no books available in the catalog at all.")
                continue

            email_dispatched = send_recommendation_email(
                receiver_email=user.email,
                username=user.username,
                books=personalized_books,
            )

            if email_dispatched:
                success_count += 1

        print(f"Distribution run complete. Dispatched {success_count}/{len(users)} emails successfully.")

    except Exception as batch_error:
        print(f"Critical failure during recommendation batch loop: {batch_error}")

    finally:
        db.close()
        print("Database connection closed.")


if __name__ == "__main__":
    run_recommendation_batch_pipeline()