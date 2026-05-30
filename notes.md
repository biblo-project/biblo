# NOTES

## 1. Problem: Flutter Build Failing Due to File Locking 
<strong>Error message:</strong>
Execution failed for task ':app:cleanMergeDebugAssets'.
```
> java.io.IOException: Unable to delete directory '...\build\app\intermediates\assets\debug\mergeDebugAssets'
Failed to delete some children. This might happen because a process has files open or has its working directory set in the target directory.
```
<br>

<strong>Root cause:</strong>
The Flutter project was stored inside a OneDrive-synced folder (C:\Users\srish\OneDrive\Documents\). OneDrive syncs files in the background by holding them open, which prevents Flutter's build tool (Gradle) from deleting and rebuilding temporary files in the build/ folder as it needs to. <br>

<strong>Solutions tried:</strong>
a. Pausing OneDrive sync — did not work because the files were already locked from previous sync activity <br>
b. Restarting the laptop — did not work, files remained locked <br>
c. Moving project to C:\Users\srish\Documents\ — did not work because Documents is still inside OneDrive's watch zone on Windows by default <br>
d. Moving project to C:\Projects\biblo\ — correct move, fully outside OneDrive's reach, but old locked build files came along with the move <br>
e. Force deleting the locked folders using PowerShell — this worked:

```
Remove-Item -Recurse -Force "C:\Projects\biblo\frontend\build"
Remove-Item -Recurse -Force "C:\Projects\biblo\frontend\.dart_tool"
Remove-Item -Recurse -Force "C:\Projects\biblo\frontend\ios\Flutter\ephemeral"
Remove-Item -Recurse -Force "C:\Projects\biblo\frontend\macos\Flutter\ephemeral"
```
<br>

<strong>Final resolution:</strong>
Project moved to C:\Projects\biblo\ and locked build folders force deleted. Flutter can now build successfully. <br>

<strong>Lesson learned:</strong>
Never store a Flutter project inside a cloud-synced folder (OneDrive, Google Drive, Dropbox). Always keep Flutter projects in a plain local directory like C:\Projects\.

## 2. Not able to start or "cold boot" the Android emulator due to the pop-up message "Medium Phone API 36.1 is already running as process 26564."

If the Android emulator is stuck, and you're not able to reboot it and seeing the above error message, then run the following command in your Window terminal to kill the process:
```
taskkill /F /PID 26564
```
Expected output:
```
SUCCESS: The process with PID 26564 has been terminated.
```
## 3. Explanation of the initial bare minimum backend code being used

### a. main.py
```
from fastapi import FastAPI app = FastAPI() @app.get("/") def root(): return {"message": "Biblo backend running"}
```

Here, this is what the different lines actually mean: <br>
#### i. Importing the FastAPI class from the FastAPI framework 
```
from fastapi import FastAPI
```
* FastAPI is the core object that represents your web application
* Without this, you have no server, no routes, nothing

#### ii. Creating an instance of your web application
```
app = FastApi()
```
* ```app``` is now your entire backend
* Every route, middleware, config → attaches to this object

#### iii. Using a decorator
```
@app.get("/")
```
* Translation: “When someone sends a GET request to /, run the function below”
* Break it down: 
  * @ → modifies the function below it 
  * app.get(...) → defines an HTTP GET endpoint 
  * "/" → root URL (homepage of your API) 

#### iv. Defining the function that runs when / is hit
```
def root():
    return {"message": "Biblo backend running"}
```
* Function name (root)
  * Doesn’t matter to the user
  * Only used internally
* Return value
```
{"message": "Biblo backend running"}
```
This is a Python dictionary → FastAPI automatically converts it to JSON

Response sent to browser:
```
{
"message": "Biblo backend running"
}
```
This is powerful because you didn’t:

* Write JSON manually ❌
* Handle headers ❌
* Convert data ❌

FastAPI does it for you. ✅

#### v. Full Flow (what actually happens)

* You run:
```
python -m uvicorn main:app --reload
```
* Uvicorn starts your server

* A request comes in:
```
GET /
```
* FastAPI:
  * Matches ```/```
  * Sees it’s a ```GET``` route
  * Calls ```root()```

* ```root()``` returns a dictionary

* FastAPI:
  * Converts it to JSON
  * Sends it back

## 4. How to generate a secret key
To generate a secret key, run the following command:
```
python -c "import secrets; print(secrets.secrets.token_hex(32))"
```

In the command:
1. That command is a quick, secure way to generate a long, random string of characters directly from your terminal. 
2. Developers often use strings like this as secret keys, passwords, or authentication tokens for their Python backends.
3. What the command is breaking down: 
   * <strong> python -c </strong>: The -c flag tells Python, "Don't wait for me to open a script file. Just execute the code I'm about to type inside these quotation marks right now." 
   * <strong> import secrets; </strong>: This imports Python's built-in secrets module, which is specifically designed for generating securely random numbers and tokens (much safer for security than the standard random module). 
   * <strong> token_hex(32) </strong>: This generates a random string of hexadecimal characters (0-9 and a-f). The 32 tells it to generate 32 bytes of randomness, which results in a 64-character long string.

It will print something like:
```
3f7a2c1e8b4d6f9a0e2c5b7d1f4a8e3c6b9d2f5a8e1c4b7d0f3a6e9c2b5d8f1a
```
Copy that and paste it into your .env file as:
```
SECRET_KEY=3f7a2c1e8b4d6f9a0e2c5b7d1f4a8e3c6b9d2f5a8e1c4b7d0f3a6e9c2b5d8f1a
```

## 5. Updates to config.py
```
from pydantic_settings import BaseSettings
from pydantic import Field

class Settings(BaseSettings):
    DATABASE_URL: str = Field(default=None)
    SECRET_KEY:str = Field(default=None)

    class Config:
        env_file = ".env"

settings = Settings()

'''
Added " = Field(default=None)" to clear up the IDE's warning that says that 
class Settings expects two arguments (DATABASE_URL, SECRET_KEY) but I'm not 
passing  them directly into the parentheses, because Pydantic knows to look 
at my class Config, find the .env file and automatically fill those parameters 
for me at runtime. 
'''

'''
Alternative approach to get rid of the warnings:

settings = Settings(_env_file=".env")

'''

'''
If your config file is in another folder then use this:

class Config:
env_file = "../.env"
# Adjust path relative to where this script runs

'''
```

## 6. Updates to database.py
```
from sqlalchemy import create_engine
from sqlalchemy.orm import  sessionmaker, declarative_base
from .config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency to inject DB session into API endpoints
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```
This code is the backbone of your database communication. It sets up SQLAlchemy (Python's most popular Object-Relational Mapper, or ORM) to connect your FastAPI application to your PostgreSQL database.

Instead of writing raw SQL commands by hand, this file sets up the machinery that allows Python to talk to your database smoothly.

Here is a line-by-line breakdown of exactly what is happening and why:

### 1. The imports
```
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from .config import settings
```
* <strong> create_engine </strong>: The tool that actually handles the raw connection to your database.
* <strong> sessionmaker </strong>: A factory that creates "sessions" (temporary conversations) with your database.
* <strong> declarative_base </strong>: A base class that your database tables (models) will inherit from later.
* <strong> settings </strong>: This imports the code you wrote earlier, which grabs your DATABASE_URL safely from the hidden .env file.

### 2. The engine
```
engine = create_engine(settings.DATABASE_URL)
```

Think of the engine as a physical water pipeline connecting your code to your database. It knows where the database is (from your URL) and manages a pool of connections so your app doesn't have to constantly log in and out of the database every time a user clicks something.

### 3. The Session Factory 
```
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
```

If the engine is the pipeline, a Session is like a bucket of water you draw from it. Every time a user interacts with your app (like signing up), a new session is created to handle that specific request.

* <strong> autocommit=False </strong>: Tells SQLAlchemy not to save data immediately. It waits for you to explicitly type db.commit(). This is safer because if something crashes halfway through a transaction, nothing gets corrupted.
* <strong> autoflush=False </strong>: Prevents SQLAlchemy from sending premature queries to the database before you are ready.
* <strong> bind=engine </strong>: Connects this session factory directly to the pipeline (engine) we built above.

### 4. The Base Class
```
Base = declarative_base()
```

This creates a magic Python class called Base. Later, when you create your User model, you will make it inherit from this Base. It tells SQLAlchemy: "Hey, look at this Python class, track its variables, and map them directly to a SQL table columns."

However, to understand ```Base = declarative_base()``` technically, we need to look under the hood of how SQLAlchemy bridges the gap between two completely different programming paradigms: Object-Oriented Programming (Python) and Relational Databases (SQL).

Technically, Base is a metaclass constructor.

Here is the deep dive into what it is doing behind the scenes.

1. <strong> The Core Definition: What is a Metaclass Constructor? </strong>

In standard Python, a class defines how an object is created. A metaclass, however, defines how a class itself is constructed.

When you run ```Base = declarative_base()```, SQLAlchemy dynamically constructs a new Python class. This class maintains a private registry (called a Mapper) of every class that inherits from it.

```
# You write this:
class User(Base):
__tablename__ = "users"
id = Column(Integer, primary_key=True)
```

The moment Python parses your code and sees ```User(Base)```, Base intercepts the class creation process. It reads your Python code, extracts properties like ```__tablename__```, and maps them to SQLAlchemy's internal table-representation engine.

2. <strong> The Mechanics: The "Declarative" System </strong>

Historically in SQLAlchemy, you had to define tables and Python classes completely separately, and manually map them together using a function called ```mapper()```. It looked like this:

```
# Old, Imperial Way (Imperative Mapping)
users_table = Table('users', metadata, Column('id', Integer, primary_key=True))
class User(object): pass
mapper(User, users_table) # <-- Manual mapping step
```
The Declarative system combines these steps. declarative_base() automates this boilerplate. It allows you to declare the SQL table structure and the Python class properties simultaneously in a single location.

3. <strong> The MetaData Container (The Catalog) </strong>

Every Base instance contains a hidden catalog property called ```Base.metadata```.

Think of metadata as an invisible ledger. Every time you create a new model (like User, Book, or Order) inheriting from Base, that model registers its database schema configuration inside this ledger.

This ledger is exactly what allows other tools to inspect your entire application structure. 

For example, when you run Alembic migrations later, Alembic imports your Base, looks inside ```Base.metadata```, reads everything written in the ledger, and tells PostgreSQL: "Hey, look at this list of tables, make the physical database look exactly like this."

<strong> Summary of its Technical Lifecycle: </strong>
* <strong> At Initialization</strong>: Base = declarative_base() initializes a central registry and a blank metadata ledger.
* <strong> At Import Time</strong>: As Python imports your files inside models/, each class inheriting from Base auto-registers its SQL columns, relationships, and constraints into that ledger.
* <strong> At Runtime</strong>: When you run database queries via a session (e.g., db.query(User)), SQLAlchemy inspects Base to translate your Python syntax into standard SELECT, INSERT, or UPDATE SQL strings targeted precisely at your database engine.

<strong> Note</strong>: In newer versions of SQLAlchemy 2.0+, this is often written using a class-based approach inheriting from DeclarativeBase, but functionally it performs the exact same mechanical registry role under the hood!

## 7. Updates user.py under 'models/' and 'schemas/'

### Updated ```models/user.py```:
```
from sqlalchemy import Column, Integer, String
from ..database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)

'''
A Model represents what your data looks like inside the database. This defines the exact structure of the users table in PostgreSQL.
'''
```

### Updated ```schemas/user.py```:
```
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    email: EmailStr
    password: str

class UserOut(BaseModel):
    id: int
    email: EmailStr

    class Config:
        from_attributes = True
```

<strong> NOTE:</strong> While database models (like SQLAlchemy) define how data is stored in your PostgreSQL tables, Pydantic schemas define how data moves into and out of your FastAPI endpoints. They act as gatekeepers, validating incoming data and filtering outgoing data.

Here is the line-by-line breakdown of what this code does and why it is written this way:

#### 1. The imports

```
from pydantic import BaseModel, EmailStr
```
* <strong>BaseModel:</strong> The core class from Pydantic. Any class that inherits from this automatically gains data validation, type checking, and serialization powers.
* <strong>EmailStr:</strong> A special type provided by Pydantic. It doesn't just check if the data is a string; it automatically runs a validation check to ensure the string is a format-correct email address (e.g., contains an @ and a valid domain). If a user tries to sign up with "not-an-email", Pydantic will instantly reject the request with a 422 Unprocessable Entity error before it ever touches your database.

#### 2. The input gatekeeper: ```UserCreate```
```
class UserCreate(BaseModel):
    email: EmailStr
    password: str
```

This schema handles incoming data. When a user wants to register or log in, they must send a JSON payload that matches this exact blueprint:
```
{
  "email": "user@example.com",
  "password": "supersecurepassword123"
}
```
Because this model requires a plain-text password string, your FastAPI endpoint can receive it, pass it to your hashing function, and save the hashed version to the database.

#### 3. The output filter: ```UserOut```
```
class UserOut(BaseModel):
    id: int
    email: EmailStr
```
This schema handles outgoing data. When your backend finishes creating a user, you want to send a success response back to the Flutter app.

Notice what is missing here: ```password```.

By returning data through the ```UserOut``` schema, FastAPI automatically strips away the password field. Even if your database query contains the hashed password, it will never be sent over the internet to the client. This is an essential security layer.

#### 4. The magic configuration
```
class Config:
        from_attributes = True
```
<strong>Note:</strong> In older versions of Pydantic, this was written as ```orm_mode = True```.

<strong>Important:</strong>

This line is crucial because of a fundamental mismatch in Python libraries:
* SQLAlchemy database objects store data <strong>as object attributes</strong> (accessible via dot notation, like user.email).
* Pydantic schemas normally expect data <strong>as standard dictionary keys</strong> (like user["email"]).

By setting ```from_attributes = True```, you are telling Pydantic: 

"Hey, when I return data from the database, it's going to be an ORM object, not a dictionary. Go ahead and read its attributes anyway."

Because of this single line, inside your ```auth.py``` router, you can write:
```
return db_user # A SQLAlchemy object
```
And FastAPI will seamlessly read ```db_user.id``` and ```db_user.email```, validate them, drop the password, and convert it into clean JSON for your Flutter app.
