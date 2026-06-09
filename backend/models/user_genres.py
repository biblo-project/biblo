from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from ..database import Base

class UserGenre(Base):
    __tablename__ = "user_genres"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    genre = Column(String)

'''
A Model represents what your data looks like inside the database. 
This defines the exact structure of the user_genres table in PostgreSQL.
'''

# relationship back to parent
user = relationship("User", back_populates="user_genre")