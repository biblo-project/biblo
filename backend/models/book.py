from sqlalchemy import Column, Integer, String
from ..database import Base
from sqlalchemy.orm import relationship

class Book(Base):
    __tablename__ = "books"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    author = Column(String, index=True, nullable=False)
    description = Column(String)

    # Relationships
    book_genre = relationship("BookGenre", back_populates="book", cascade="all, delete-orphan")
    quote = relationship("Quote", back_populates="book", cascade="all, delete-orphan")
    reading_list = relationship("ReadingList", back_populates="book")

'''
A Model represents what your data looks like inside the database. 
This defines the exact structure of the books table in PostgreSQL.

Unless you are actively filtering queries by the exact full text of 
a quote (where quote_text == '...'), indexing massive strings slows 
down database insertions. Leave indexing for IDs, emails, usernames, 
and statuses.
'''

