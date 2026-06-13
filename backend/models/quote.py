from sqlalchemy import Column, Integer, String, ForeignKey
from ..database import Base
from sqlalchemy.orm import relationship

class Quote(Base):
    __tablename__ = "quotes"

    id = Column(Integer, primary_key=True, index=True)
    book_id = Column(Integer, ForeignKey("books.id"))
    quote_text = Column(String)

    # Relationship back to parent
    book = relationship("Book", back_populates="quote")
'''
A Model represents what your data looks like inside the database. 
This defines the exact structure of the quotes table in PostgreSQL.

Unless you are actively filtering queries by the exact full text of 
a quote (where quote_text == '...'), indexing massive strings slows 
down database insertions. Leave indexing for IDs, emails, usernames, 
and statuses.
'''

