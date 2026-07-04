from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import relationship

from ..database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_admin = Column(Boolean, nullable=False, default=False)
    avatar_id = Column(Integer, nullable=True, default=None)

    # Relationships
    # cascade="all, delete-orphan" means if a user is deleted, delete their chosen genres too
    user_genre = relationship("UserGenre", back_populates="user", cascade="all, delete-orphan")
    reading_list = relationship("ReadingList", back_populates="user", cascade="all, delete-orphan")

'''
A Model represents what your data looks like inside the database. 
This defines the exact structure of the users table in PostgreSQL.
'''

