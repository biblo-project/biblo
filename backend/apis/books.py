from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy.sql import func
from typing import List
from backend.database import get_db
from backend.models.book import Book
from backend.schemas.book import BookOut
from backend.core.auth import get_current_user
from backend.models.user import User
from typing import Dict, Any
from backend.models.reading_list import ReadingList, ReadingStatus

# ML related libraries
'''
import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.neighbors import NearestNeighbors

# Include the models used by the ML engine
from backend.models.user_genre import UserGenre
from backend.models.book_genre import BookGenre
'''

router = APIRouter(prefix="/books", tags=["Books"])

@router.get("/random", response_model=List[BookOut])
def get_random_books(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user) # Removed underscore to use the variable
):
    # 1. Fetch only the IDs of books this user has already liked
    liked_book_ids = (
        db.query(ReadingList.book_id)
        .filter(ReadingList.user_id == current_user.id)
        .all()
    )
    # Flatten the list of tuples [(1,), (3,)] into a flat list of integers [1, 3]
    excluded_ids = [b_id[0] for b_id in liked_book_ids]

    # 2. Start the query on the Book catalog
    query = db.query(Book)

    # 3. Minimal Filter: If the user has liked books, exclude them from the pool
    if excluded_ids:
        query = query.filter(~Book.id.in_(excluded_ids))

    # 4. Pull the random sample from the remaining unliked items
    books = query.order_by(func.random()).limit(5).all()

    if not books:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No new books available in the catalog right now."
        )

    return books

'''
@router.get("/curated")
def get_ml_recommendations(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    # 1. Fetch User preferences
    user_genres = db.query(UserGenre.genre).filter(UserGenre.user_id == current_user.id).all()
    user_genre_list = [g[0] for g in user_genres]

    if not user_genre_list:
        return db.query(Book).limit(10).all() # Fallback if user profile is empty

    # 2. Extract catalog data into a Pandas DataFrame for ML training
    books = db.query(Book).all()
    if len(books) < 2:
        return books # Not enough data points to train a neighborhood map yet

    book_data = []
    for b in books:
        # Pull all genres mapped to this specific book
        bg_rows = db.query(BookGenre.genre).filter(BookGenre.book_id == b.id).all()
        genre_string = " ".join([row[0] for row in bg_rows])

        # Combine text fields into a single "feature soup" text block
        feature_soup = f"{b.title} {b.author} {b.description} {genre_string}"

        book_data.append({
            "id": b.id,
            "object": b, # Keep the SQLAlchemy instance to return later
            "features": feature_soup
        })

    df = pd.DataFrame(book_data)

    # 3. Vectorize the Text Metadata (TF-IDF Matrix construction)
    tfidf = TfidfVectorizer(stop_words='english')
    tfidf_matrix = tfidf.fit_transform(df['features'])

    # 4. Train the K-Nearest Neighbors Engine in-memory
    # We use Cosine metric because it measures the directional angle of text profiles rather than raw size
    knn = NearestNeighbors(n_neighbors=min(10, len(df)), metric='cosine', algorithm='brute')
    knn.fit(tfidf_matrix)

    # 5. Represent the logged in User as a text profile vector
    user_profile_text = " ".join(user_genre_list)
    user_vector = tfidf.transform([user_profile_text])

    # 6. Calculate spatial distance coordinates
    distances, indices = knn.kneighbors(user_vector)

    # 7. Map the closest indices back to our original database objects
    recommended_books = []
    for idx in indices[0]:
        recommended_books.append(df.iloc[idx]['object'])

    return recommended_books
'''

@router.get("/search")
def search_books(
        q: str = Query(..., description="The search string"),
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    if not q.strip():
        return []

    search_term = f"%{q.strip()}%"

    # 1. Fetch matching books
    books = db.query(Book).filter(
        (Book.title.ilike(search_term)) |
        (Book.author.ilike(search_term))
    ).limit(20).all()

    # 2. Get a set of book IDs this specific user has already liked
    liked_book_ids = set(
        db.query(ReadingList.book_id)
        .filter(ReadingList.user_id == current_user.id)
        .all()
    )
    # Flatten tuple list [(1,), (5,)] into a clean set: {1, 5}
    liked_book_ids = {b_id[0] for b_id in liked_book_ids}

    # 3. Dynamically map the results into a dict payload that sets 'isLiked' correctly
    output = []
    for book in books:
        output.append({
            "id": book.id,
            "title": book.title,
            "author": book.author,
            "description": book.description,
            "isLiked": book.id in liked_book_ids # True if it exists in their reading list
        })

    return output

@router.post("/{book_id}/toggle-like", status_code=status.HTTP_200_OK)
def toggle_like_book(
        book_id: int,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Toggles a book's presence in the current user's reading list.
    If the book is not on the list, it adds it with 'to_read' status.
    If it is already on the list, it deletes the record ('unlikes' it).
    """

    # 1. Verify the book exists in the database
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Book with id {book_id} does not exist."
        )

    # 2. Check if this record already exists for the logged-in user
    existing_entry = db.query(ReadingList).filter(
        ReadingList.user_id == current_user.id,
        ReadingList.book_id == book_id
    ).first()

    # 3. Toggle Logic
    if existing_entry:
        # User is unliking the book -> Delete the row from the table
        db.delete(existing_entry)
        db.commit()
        return {
            "liked": False,
            "message": f"Successfully removed '{book.title}' from your reading list."
        }
    else:
        # User is liking the book -> Insert a new record defaulting to 'to_read'
        new_reading_list_entry = ReadingList(
            user_id=current_user.id,
            book_id=book_id,
            status=ReadingStatus.to_read
        )
        db.add(new_reading_list_entry)
        db.commit()
        return {
            "liked": True,
            "message": f"Successfully added '{book.title}' to your reading list as to_read."
        }