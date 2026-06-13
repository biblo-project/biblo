# backend/models/__init__.py

from backend.database import Base
from backend.models.user import User
from backend.models.book import Book
from backend.models.user_genre import UserGenre
from backend.models.book_genre import BookGenre
from backend.models.reading_list import ReadingList
from backend.models.quote import Quote

__all__ = ["Base", "User", "Book", "UserGenre", "BookGenre", "ReadingList", "Quote"]