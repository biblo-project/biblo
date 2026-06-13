import enum
from sqlalchemy import Column, Integer, ForeignKey, Enum
from ..database import Base
from sqlalchemy.orm import relationship

class ReadingStatus(str, enum.Enum):
    to_read = "to_read"
    reading = "reading"
    read = "read"

class ReadingList(Base):
    __tablename__ = "reading_lists"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    book_id = Column(Integer, ForeignKey("books.id"))
    status = Column(Enum(ReadingStatus), index=True, nullable=False, default=ReadingStatus.to_read)

    # Relationships to tie everything together
    user = relationship("User", back_populates="reading_list")
    book = relationship("Book", back_populates="reading_list")

'''
A Model represents what your data looks like inside the database. 
This defines the exact structure of the reading_lists table in PostgresSQL.
'''

