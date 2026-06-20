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

import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.neighbors import NearestNeighbors

# Include the models used by the ML engine
from backend.models.user_genre import UserGenre
from backend.models.book_genre import BookGenre

from backend.schemas.book import BookCreate, BookOut, BookUpdate
from backend.models.book import Book # Your SQLAlchemy Model
from backend.database import get_db   # Your DB Session Yield hook

router = APIRouter(prefix="/books", tags=["Books"])

#_____________________________________________________________________________________________________
# ADMINISTRATOR ROUTES
#_____________________________________________________________________________________________________
#_____________________________________________________________________________________________________
# ADD BOOKS   

@router.post("/admin", response_model=BookOut, status_code=status.HTTP_201_CREATED)
def create_book(book_in: BookCreate, db: Session = Depends(get_db)) -> Any:
    """
    Creates a new book entry in the PostgreSQL database.
    This action will serve as our future upstream event source for Kafka syncing.
    """
    # 1. Optional business logic check: Prevent duplicate ISBNs if provided
    if book_in.isbn and book_in.isbn.strip():
        existing_book = db.query(Book).filter(Book.isbn == book_in.isbn.strip()).first()
        if existing_book:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A book record with this ISBN code already exists."
            )

    try:
        # 2. Map the validated incoming Pydantic payload to your SQLAlchemy model instance
        new_book = Book(
            title=book_in.title.strip(),
            author=book_in.author.strip(),
            description=book_in.description.strip() if book_in.description else None,
            isbn=book_in.isbn.strip() if book_in.isbn else None
        )

        # 3. Commit the entity to your transactional PostgreSQL database
        db.add(new_book)
        db.commit()
        db.refresh(new_book) # Hydrates the instance with its new generated database 'id'

        # 4. Return the database record (FastAPI automatically transforms this to your BookOut schema shape)
        return new_book

    except Exception as e:
        db.rollback() # Safely roll back transaction context on fault
        import logging
        logger = logging.getLogger("uvicorn.error")
        logger.error(f"Database write crash inside POST /books: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database write operation failed."
        )

#_____________________________________________________________________________________________________
# UPDATE BOOKS

@router.put("/admin/{book_id}", response_model=BookOut)
def update_book(book_id: int, book_in: BookUpdate, db: Session = Depends(get_db)) -> Any:
    """
    Updates an existing book record in PostgreSQL.
    This will serve as our future Kafka event source for 'UPDATE' mutations.
    """
    # 1. Locate the targeted record in the database
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Book with id {book_id} does not exist."
        )

    # 2. Safety Check: Prevent duplicate ISBNs across different books
    if book_in.isbn and book_in.isbn.strip():
        clean_isbn = book_in.isbn.strip()
        # Find if *another* book is already using this updated ISBN code
        existing_isbn = db.query(Book).filter(Book.isbn == clean_isbn, Book.id != book_id).first()
        if existing_isbn:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Another book record is already using this ISBN code."
            )

    try:
        # 3. Extract the incoming data payload, ignoring fields that weren't sent
        update_data = book_in.model_dump(exclude_unset=True)
        
        # 4. Dynamically loop through and apply the updates to the database model instance
        for key, value in update_data.items():
            if isinstance(value, str):
                setattr(book, key, value.strip())
            else:
                setattr(book, key, value)

        # 5. Commit change context to your transactional PostgreSQL database
        db.commit()
        db.refresh(book)
        
        return book

    except Exception as e:
        db.rollback()
        import logging
        logger = logging.getLogger("uvicorn.error")
        logger.error(f"Database update crash inside PUT /books/{book_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database update operation failed."
        )
    
# _____________________________________________________________________________________________________
# SEARCH BOOKS

from backend.core.opensearch import get_opensearch_client

@router.get("/admin/search", response_model=List[BookOut])
def admin_search_books(q: str = "", db: Session = Depends(get_db)):
    """
    Searches books using OpenSearch multi_match with fuzziness enabled.
    Falls back to a clean list if no matches or cluster errors occur.
    """
    if not q.strip():
        return []

    # 1. Define the OpenSearch Fuzzy Query Payload
    search_body = {
        "size": 20,
        "query": {
            "multi_match": {
                "query": q.strip(),
                "fields": ["title", "author"],
                "fuzziness": "AUTO",  # Automatically allows 1-2 character typos based on string length
                "prefix_length": 1,  # Prevents fuzziness on the very first character for better speed
            }
        },
    }

    try:
        # 2. Query your OpenSearch 'books' index safely using an instantiated client
        client = get_opensearch_client()  # Added parentheses to fix the bug
        response = client.search(body=search_body, index="biblo_books")

        # 3. Extract the document IDs from the OpenSearch search hits
        hits = response["hits"]["hits"]
        book_ids = [int(hit["_id"]) for hit in hits]

        if not book_ids:
            return []

        # 4. Fetch the rich, complete records from PostgreSQL using the retrieved IDs
        books = db.query(Book).filter(Book.id.in_(book_ids)).all()

        # Sort PostgreSQL results to match OpenSearch's precise score sequence
        book_map = {book.id: book for book in books}
        ordered_books = [book_map[b_id] for b_id in book_ids if b_id in book_map]

        return ordered_books

    except Exception as opensearch_error:
        # Fallback Strategy
        import logging

        logger = logging.getLogger("uvicorn.error")
        logger.warning(
            f"OpenSearch failed ({opensearch_error}). Falling back to database ILIKE."
        )

        search_term = f"%{q.strip()}%"
        return (
            db.query(Book)
            .filter(
                (Book.title.ilike(search_term))
                | (Book.author.ilike(search_term))
            )
            .limit(20)
            .all()
        )
    
# _____________________________________________________________________________________________________
# DELETE BOOKS
    
@router.delete("/admin/{book_id}", status_code=status.HTTP_200_OK)
def delete_book(book_id: int, db: Session = Depends(get_db)):
    """
    Deletes a book record from PostgreSQL and removes it 
    from the OpenSearch search index instantly.
    """
    # 1. Locate the book record in PostgreSQL
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Book with id {book_id} does not exist in the database."
        )

    try:
        # 2. Extract the title before purging for logging/success details
        book_title = book.title

        # 3. Delete the record from your transactional PostgreSQL database
        db.delete(book)
        db.commit()

        # 4. Immediately remove it from OpenSearch to prevent "ghost" results
        try:
            from backend.core.opensearch import get_opensearch_client
            client = get_opensearch_client()
            
            client.delete(
                index="books",
                id=str(book_id),
                refresh=True # Forces OpenSearch to apply the deletion immediately
            )
        except Exception as os_delete_error:
            # Wrap in a sub-try/catch so that if OpenSearch fails, 
            # the primary database deletion doesn't get messed up.
            import logging
            logger = logging.getLogger("uvicorn.error")
            logger.error(f"Postgres deleted book {book_id}, but OpenSearch removal failed: {os_delete_error}")

        return {"message": f"Successfully deleted '{book_title}' from the catalog."}

    except Exception as e:
        db.rollback() # Safe rollback on structural database faults
        import logging
        logger = logging.getLogger("uvicorn.error")
        logger.error(f"Database deletion crash inside DELETE /books/admin/{book_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database deletion operation failed."
        )

#_____________________________________________________________________________________________________
# USER ROUTES
#_____________________________________________________________________________________________________
#_____________________________________________________________________________________________________
# GET RANDOM RECS

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

#_____________________________________________________________________________________________________
# GET CURATED RECS

@router.get("/curated")
def get_curated_books(
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
    knn = NearestNeighbors(n_neighbors=min(5, len(df)), metric='cosine', algorithm='brute')
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

#_____________________________________________________________________________________________________
# SEARCH BOOKS

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

#_____________________________________________________________________________________________________
# LIKE/UNLIKE BOOKS

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

