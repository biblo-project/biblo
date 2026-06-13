from sqlalchemy import Column, Integer, String, ForeignKey
from ..database import Base
from sqlalchemy.orm import relationship

class BookGenre(Base):
    __tablename__ = "book_genres"

    id = Column(Integer, primary_key=True, index=True)
    book_id = Column(Integer, ForeignKey("books.id"), nullable=False)
    genre = Column(String, nullable=False)

    # relationship back to parent
    book = relationship("Book", back_populates="book_genre")
