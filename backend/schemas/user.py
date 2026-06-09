from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    email: EmailStr
    username: str
    password: str

class UserOut(BaseModel):
    id: int
    email: EmailStr
    username: str

    class Config:
        from_attributes = True

'''
from_attributes = True is a Pydantic configuration setting 
(formerly known as orm_mode = True in Pydantic v1) that allows 
a schema to read and validate data directly from object 
attributes using dot notation—such as user.username from a 
SQLAlchemy model—instead of strictly requiring a standard Python 
dictionary format like user["username"]. By enabling this rule, 
Pydantic can seamlessly intercept database query results, automatically 
trigger lazy-loaded database relationships (like pulling a book's 
connected quotes array), and serialize those complex database objects 
into nested JSON payloads for your Flutter frontend without requiring 
you to write manual data-parsing or database join logic.
'''

class UserLogin(BaseModel):
    username_or_email: str
    password: str