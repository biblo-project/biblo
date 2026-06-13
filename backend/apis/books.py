from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.sql import func
from typing import List
from backend.database import get_db
from backend.models.book import Book
from backend.schemas.book import BookOut
from backend.core.auth import get_current_user
from backend.models.user import User

router = APIRouter(prefix="/books", tags=["Books"])

@router.get("/random", response_model=List[BookOut])
def get_random_books(
        db: Session = Depends(get_db),
        _current_user: User = Depends(get_current_user)
):
    books = db.query(Book).order_by(func.random()).limit(5).all()

    # Optional Safety Check: If the DB is completely empty,
    # you can choose to raise a 404 or return an empty list.
    if not books:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No books available in the catalog right now."
        )

    return books

'''
        To clear the IDE warning cleanly without breaking 
        your security, you can tell your editor that the 
        omission is intentional by prefixing the variable name 
        with an underscore 
        '''