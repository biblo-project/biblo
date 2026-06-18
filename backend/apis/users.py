from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.database import get_db
from backend.models.user import User
from backend.schemas.user import UserOut
from backend.models.book import Book
from backend.models.reading_list import ReadingList
from backend.core.auth import get_current_user
from typing import List, Dict, Any

router = APIRouter(prefix="/user", tags=["User"])

@router.get("/me", response_model=UserOut)
def get_my_profile(current_user: User = Depends(get_current_user)):
    return current_user

@router.get("/to-read", response_model=List[Dict[str, Any]])
def get_to_read_list(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    """
    Fetches all books currently in the logged-in user's reading list.
    """
    # Query the Book table joined against the ReadingList rows for this user
    results = db.query(Book).join(
        ReadingList, ReadingList.book_id == Book.id
    ).filter(
        ReadingList.user_id == current_user.id
    ).all()

    # Map the output data so 'isLiked' is hardcoded to True
    # (since they are actively pulling from their liked list)
    output = []
    for book in results:
        output.append({
            "id": book.id,
            "title": book.title,
            "author": book.author,
            "description": book.description,
            "isLiked": True
        })

    return output


