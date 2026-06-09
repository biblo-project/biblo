from pydantic import BaseModel
'''
Every schema you create must inherit from this. 
It gives your Python classes the superpower to 
automatically validate incoming JSON data from 
Flutter and parse outgoing Python database objects 
into JSON.
'''

from enum import Enum
'''
Enums allow you to define a strict list of allowed 
options for a variable, preventing typos (like a user 
accidentally sending "reead" instead of "read").
'''

from .book import BookOut
'''
This allows you to nest a book's full details (like title 
and author) directly inside the reading list response data.
'''

class ReadingStatus(str, Enum):
    to_read = "to_read"
    reading = "reading"
    read = "read"

'''
Defines a strict text-based Enum. By inheriting from both str 
and Enum, Pydantic knows that the incoming JSON values must 
match these exact strings.

If a user tries to pass an invalid status string like "finished", 
Pydantic will instantly block the request and return a clear 
validation error to Flutter before it ever touches your database.
'''

class ReadingListBase(BaseModel):
    book_id: int
    status: ReadingStatus = ReadingStatus.to_read

'''
This is a base configuration class. It outlines the bare minimum 
fields that almost every reading list action shares.

book_id: int: Guarantees that an integer ID for the book must be 
provided.

status: ReadingStatus = ReadingStatus.to_read: Sets up the status 
field using your enum, and automatically defaults it to "to_read" 
if the app doesn't explicitly send a status value.
'''

class ReadingListCreate(BaseModel):
    """Payload required when a user adds a new book to their list."""
    pass
    # The keyword pass just means "don't add any extra code here,
    # leave it exactly as its parent."

class ReadingListUpdate(BaseModel):
    """
    Payload used to change a book's status.
    When a book is 'Reviewed', the frontend sends status='read'.
    """
    status: ReadingStatus

    '''
    When a user finishes/reviews a book, you don't need to change the 
    book_id or user_id—you only want to change the status. Flutter will 
    send {"status": "read"} to your endpoint, and this schema validates 
    that payload securely.
    '''

class ReadingListOut(BaseModel):
    """
    The data returned to the frontend.
    Includes the database entry IDs and nests the full book details
    so the UI can display titles and authors seamlessly.
    """
    id: int
    user_id: int
    book_id: int
    status: ReadingStatus
    book: BookOut # Nested Pydantic schema relational magic

    # Defines exactly what your API sends back to Flutter when
    # fetching reading list data.

'''
If you didn't have that line, your API response for a reading list 
item would look like a flat list of numbers:

```
{
  "id": 1,
  "user_id": 4,
  "book_id": 99,
  "status": "reading"
}
```
If your Flutter app receives only this data, your UI can't display the 
book's title or author. Your phone would have to make a second, 
completely separate network call to /books/99 just to find out what the 
book is named. That slows your app down.

Nested Data Structures
By writing book: BookOut, you are telling Pydantic:
"Don't just give the frontend raw numbers. Look at the database 
relationship, grab the book attached to this reading list item, and pack 
its entire profile inside this payload."

Because you set up a relationship in your SQLAlchemy model (book = 
relationship("Book")), Pydantic can follow that link. It takes the 
database object and formats it perfectly.

Now, your API response automatically transforms into a rich, nested 
structure:

```
{
  "id": 1,
  "user_id": 4,
  "book_id": 99,
  "status": "reading",
  
  "book": {
    "id": 99,
    "title": "The Great Gatsby",
    "author": "F. Scott Fitzgerald",
    "description": "A story of ambition and love in the roaring twenties."
  }
}
```

How this looks in your Flutter Code:
Because Pydantic nests the data this way, it makes writing your Dart 
classes and Flutter UI incredibly clean. In your Flutter app, you can 
parse this JSON directly into an object structure and build your layout 
widgets using simple dot-notation:

Dart
// Inside your Flutter Widget tree:
Text(readingListItem.status);             // Displays: "reading"
Text(readingListItem.book.title);         // Displays: "The Great Gatsby"
Text(readingListItem.book.author);        // Displays: "F. Scott Fitzgerald"

In short, it saves your app from making multiple backend network queries 
by grouping your matching database relations together into a single, clean 
JSON transmission.
    '''

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