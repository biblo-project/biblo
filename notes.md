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

---
## 2. Not able to start or "cold boot" the Android emulator due to the pop-up message "Medium Phone API 36.1 is already running as process 26564."

If the Android emulator is stuck, and you're not able to reboot it and seeing the above error message, then run the following command in your Window terminal to kill the process:
```
taskkill /F /PID 26564
```
Expected output:
```
SUCCESS: The process with PID 26564 has been terminated.
```

---
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

---
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

---
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

---
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

---
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
* SQLAlchemy database objects store data <strong>as object attributes</strong> (accessible via dot notation, like ```user.email```).
* Pydantic schemas normally expect data <strong>as standard dictionary keys</strong> (like ```user["email"]```).

By setting ```from_attributes = True```, you are telling Pydantic: 

"Hey, when I return data from the database, it's going to be an ORM object, not a dictionary. Go ahead and read its attributes anyway."

Because of this single line, inside your ```auth.py``` router, you can write:
```
return db_user # A SQLAlchemy object
```
And FastAPI will seamlessly read ```db_user.id``` and ```db_user.email```, validate them, drop the password, and convert it into clean JSON for your Flutter app.

---
## 8. Updated ```core/security.py```
```
from passlib.context import CryptContext
from datetime import datetime, timedelta, UTC
from jose import jwt

from ..config import settings

pwd_context = CryptContext(schemes=["bcryprt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(UTC) + timedelta(minutes=60)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")
```
Here is the line-by-line explanation:

### 1. The core imports
```
from passlib.context import CryptContext 
```
This is a tool specifically built for securely managing password hashing algorithms. It takes care of all the complex math needed to scramble a password beyond recognition.

```
from datetime import datetime, timedelta, UTC
```
We use datetime to find the exact current time, timedelta to measure out a 60-minute duration, and UTC to ensure our server uses universal global time instead of whatever local time your laptop happens to be set to.
```
from jose import jwt
```
This is the tool that packages user data (like their user ID) into an encrypted, tamper-proof string (the JWT token) that gets sent to your Flutter app.
``` 
from ..config import settings
```
* Navigates up one folder level (..) and imports your global settings object.
* It needs access to that 64-character SECRET_KEY you generated earlier to securely sign the JWT tokens.

### 2. Setting up the encryption engine
``` 
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
```
* Configures our password hashing machine.
* ```schemes=["bcrypt"]``` tells Python to use Bcrypt, which is an industry-standard, slow hashing algorithm designed to resist brute-force hacking attempts.
* ```deprecated="auto"``` ensures that if you upgrade the security configuration later, old passwords will still be read correctly.

### 3. Password hashing (for signup)
```
def hash_password(password: str) -> str:
    return pwd_context.hash(password)
```
* A function that takes a plain-text password string and returns a completely unreadable, randomized string (a hash).
* When a user registers, you pass their password through this. If their password is "password123", this function turns it into something like $2b$12$K3...etc. This is what gets saved to the database.

### 4. Password verification (for login)
```
def verify_password(plain_password, hashed_password) -> bool:
    return pwd_context.verify(plain_password, hashed_password) 
```
* A function that compares a plain-text password against a stored hash and returns True or False.
* When a user tries to log in, they type a plain password. Because you can't "decrypt" a hash back into a normal password, passlib securely re-hashes the new password attempt and checks if it mathematically matches the scrambled hash in your database.

### 5. Creating the digital hand-stamp (JWT token)
``` 
def create_access_token(data: dict):
```
A function that accepts a dictionary of data (usually the user's database ID) and turns it into a signed token.
``` 
    to_encode = data.copy()
```
* Creates a duplicate copy of the dictionary passed into the function.
* This prevents the function from accidentally altering or modifying your original user data variables elsewhere in the app.
``` 
    expire = datetime.now(UTC) + timedelta(minutes=60)
```
* Calculates an exact timestamp precisely 60 minutes into the future.
* For security reasons, authentication tokens shouldn't last forever. If someone steals a user's phone or intercepts their network packet, the token automatically becomes completely useless after 1 hour.
``` 
    to_encode.update({"exp": expire})
```
* Injects that expiration timestamp directly into our data dictionary under the key "exp".
* The JWT standard looks explicitly for an "exp" key to know when to automatically lock the user out and force them to re-authenticate.
``` 
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")
```
* Scrambles the data payload, locks it down using your secret key, and signs it using a cryptographic algorithm.
* It returns a long, three-part string separated by dots (xxxx.yyyy.zzzz) that is sent back to Flutter.

---
## 9. Updated ```api/auth.py``` (signup + login endpoints)
These are the actual URLs (```/auth/signup``` and ```/auth/login```) your Flutter app will target. They orchestrate checking the database, validating passwords, and generating tokens.
``` 
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..models.user import User
from ..schemas.user import UserCreate, UserOut
from ..core.security import  hash_password, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/signup", response_model=UserOut)
def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    # check if the user exists
    db_user = db.query(User).filter(User.email == user_data.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_user = User(email=user_data.email, hashed_password=hash_password(user_data.password))
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login")
def login(user_data: UserCreate, db: Session = Depends(get_db)):
    user=db.query(User).filter(User.email == user_data.email).first()
    if not user or not verify_password(user_data.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Invalid credentials")
    
    token = create_access_token(data={"sub": str(user.id)})
    return {"access_token": token, "token_type": "bearer"}
```
This code is your Authentication Router (```api/auth.py```). It is the orchestration layer where everything you have built so far—database setups, data validation schemas, and security configurations—comes together to create two functional web URLs: ```/auth/signup``` and ```/auth/login```.

Here is the line-by-line breakdown of how it works:

### 1. Bringing all the pieces together (the imports)
``` 
from fastapi import APIRouter, Depends, HTTPException
```
* <strong>APIRouter:</strong> A tool from FastAPI used to split your API endpoints into separate files (mini-applications) so your main.py doesn't become a massive 2,000-line file.

<strong>💡 The Analogy: A Mall Directory</strong>
Imagine you are building a massive shopping mall. If you put every single store, checkout counter, and utility closet behind one single entrance door without any hallways, it would be total chaos.

Instead, you build sections: a Food Court, a Fashion Wing, and an Entertainment Zone. Each section has its own map and management, but they all connect back to the main mall.

main.py is the main entrance of the mall.

APIRouter blocks are the different wings (e.g., ```/users```, ```/products```, ```/orders```).

<strong>💻 The Technical Reality</strong>
In a large application, keeping all your API routes (endpoints) in main.py creates a monolithic, unmaintainable file.

APIRouter is a class that allows you to modularize your routing. You create a router instance in a separate file (e.g., ```auth.py```), attach routes to it using decorators like ```@router.post("/login")```, and then include that router back into your main FastAPI app instance (```app.include_router(auth_router)```). At runtime, FastAPI merges these trees together into a single OpenAPI schema.

* <strong>Depends:</strong> FastAPI’s dependency injection system. It allows an endpoint to declare something it needs before running (like a database connection).

<strong>💡 The Analogy: Theme Park Height Check </strong>
Imagine you are going on a rollercoaster. Before you can board, a ride attendant has to check your height. You don't get to just jump into the seat; the "height check" must happen before the ride starts. If you pass, you get in. If you don't, you get turned away.

```Depends``` is that attendant. It intercepts the user before they hit the actual logic of the endpoint to make sure they have what they need (like a database connection) or are allowed to be there (like an active login session).

<strong>💻 The Technical Reality</strong>
```Depends``` is the core of FastAPI's Dependency Injection (DI) system. Instead of your endpoint function manually creating a database session or parsing a JWT token inside its body, you pass the dependency as a function parameter wrapped in ```Depends()```.

```
@router.get("/profile")
def get_profile(current_user: User = Depends(get_current_user)):
return current_user
```
When a request hits this endpoint, FastAPI looks at ```Depends(get_current_user)```, executes that function first, takes whatever it returns (the user object), and injects it directly into the current_user variable. This ensures separation of concerns and makes your code incredibly easy to unit-test, because you can easily swap out real dependencies for "mock" dependencies.

* <strong>HTTPException:</strong> A structured way to instantly stop code execution and send a specific error message and status code (like ```400 Bad Request```) back to Flutter.

<strong>💡 The Analogy: The "Eject" Button</strong>
Imagine you are driving a high-tech car, and suddenly the engine detects that there is absolutely no oil left. The car shouldn't just keep trying to drive and explode; it needs to immediately halt the system, flash a red light on your dashboard, and tell you exactly what went wrong.

An HTTPException is that immediate emergency brake. It stops your Python code right where it is and sends a clear, structured signal back to the driver (your Flutter app).

<strong>💻 The Technical Reality</strong>
In standard Python, when something goes wrong, you might raise a generic ValueError or KeyError. However, a web server needs to communicate errors using standard HTTP Status Codes (like ```404 Not Found``` or ```401 Unauthorized```) so the frontend client knows how to react.

When you write raise ```HTTPException(status_code=400, detail="Username taken")```, FastAPI catches this specific exception, halts any further execution of that request, and automatically serializes a clean JSON response to send over the network:

<strong>NOTE:</strong>
* JSON serialization is the process of converting an in-memory data structure or object (like a dictionary, list, or class instance) into a standardized JSON string format. 
* This transformation is essential because live programming objects cannot be directly saved to a file, stored in a database, or transmitted across a network. 
* Converting them into a text-based string stream makes them portable and universally readable by different programming languages. 
* Serialization: Converts an Object/Data Structure -> JSON String. It is often referred to as "encoding" or "stringifying".
* Deserialization: Converts a JSON String -> Object/Data Structure. It is the exact inverse process, often called "decoding" or "parsing"
```
{
"detail": "Username taken"
}
```
Your Flutter app receives this alongside a 400 status code, allowing your Dart code to easily catch the error and show a nice toast notification to the user.
```
from sqlalchemy.orm import Session
```
```Session``` This is a type hint. It tells Python that our database variable (db) will be an official SQLAlchemy database session instance, unlocking auto-complete in your code editor.

<strong>NOTE:</strong>
In Python, a **type hint** is essentially a label you put next to a variable to say, "Hey, this variable is supposed to hold this specific kind of data." Let’s look at the technical reason we use them and an analogy to make it stick.

<strong>💡 The Analogy: The Label on a Tool Organizer</strong>
Imagine you have a big toolbox. If you just throw every tool into a giant, empty bucket, you can still use them, but every time you need a tool, you have to dig around blindly. You might pull out a hammer when you actually needed a screwdriver.

Now, imagine an organized toolbox with molded slots, and each slot has a clear label: [10mm Wrench], [Phillips Screwdriver], or [Tape Measure].

Because of the label, you know exactly what belongs there.

When you reach for that slot, your brain instantly knows what capabilities that tool has (e.g., you know a screwdriver can turn a screw, but it can't measure a wall).

A type hint is that label.

<strong>💻 The Technical Reality</strong>
By default, Python is a **dynamically typed** language. This means Python doesn't care what you put inside a variable. You could create a variable named db, and Python would happily let you store a database connection in it, or a piece of text, or the number 42. *Python only finds out it's wrong when the code actually runs and crashes*.

When you write code like this:

```
db: Session
```
You are explicitly telling your Code Editor (like VS Code or Cursor) and Python: 
"The variable db is a Session object from SQLAlchemy."

Why this is a superpower (Auto-Complete)
Because your code editor now knows that db is an official SQLAlchemy Session, it can look up all the built-in commands that come with SQLAlchemy.

The moment you type ```db.``` in your editor, a helpful menu instantly pops up (auto-complete) showing you all your available options:
```
.query()
.add()
.commit()
.close()
```
Without that type hint, your editor is completely in the dark. It doesn't know if ```db``` is a database session or just a random word, so it can't offer you any auto-complete suggestions, forcing you to memorize the exact SQLAlchemy syntax or constantly check the documentation.
### 2. Building the router group
``` 
router = APIRouter(prefix="/auth", tags=["Authentication"])
```
* ```prefix="/auth"```: This automatically groups all endpoints in this file under a shared URL prefix. Instead of writing out @router.post("/auth/signup"), you can just write @router.post("/signup").
* ```tags=["Authentication"]```: This is purely for organizational aesthetics. It groups these endpoints together under an "Authentication" banner inside your interactive Swagger page (/docs).

### 3. The signup endpoint (User registration)
``` 
@router.post("/signup", response_model=UserOut)
```
* ```@router.post("/signup")```: Declares that this endpoint accepts HTTP POST requests (used when creating new data) targeted at http://127.0.0.1:8000/auth/signup.
* ```response_model=UserOut```: Remember your Pydantic schema? This guarantees that whatever data this function returns will be scrubbed through UserOut, stripping away the user's password before sending the JSON response back over the web.

``` 
def signup(user_data: UserCreate, db: Session = Depends(get_db)):
```
* ```user_data: UserCreate```: FastAPI reads the incoming JSON payload from Flutter, passes it through the ```UserCreate``` schema, checks if the email format is valid, and provides it to the function as a clean object.
* ```db: Session = Depends(get_db)```: FastAPI fires up the ```get_db()``` utility function you wrote earlier, borrows a live database connection bucket, loads it into the ```db``` variable, and promises to close it automatically when this function finishes.

``` 
db_user = db.query(User).filter(User.email == user_data.email).first()
```
Translates to a SQL command: 
```
SELECT * FROM users WHERE email = 'user_data.email' LIMIT 1;
``` 
It searches your PostgreSQL database to see if this email is already taken.
``` 
if db_user:
    raise HTTPException(status_code=400, detail="Email already registered")
```
If ```db_user``` is not empty (the email already exists), it drops everything, rings the alarm bell, and shoots a 400 error response straight back to the user.
``` 
new_user = User(email=user_data.email, hashed_password=hash_password(user_data.password))
```
If the email is unique, we create a fresh instances of our SQLAlchemy User database model. 
Notice that we intercept the plain text ```user_data.password``` and run it through our ```hash_password``` algorithm before assigning it to the model.
``` 
db.add(new_user)
db.commit()
db.refresh(new_user)
```
* ```db.add(new_user)```: Places the user object into SQLAlchemy’s staging area (like a shopping cart). It hasn’t saved to PostgreSQL yet.
* ```db.commit()```: Pushes the transaction to the database, physically writing the new row into your ```users``` table.
* ```db.refresh(new_user)```: Pulls the data back out of the database briefly so Python can learn the new unique ```id``` number that PostgreSQL automatically generated for this user.

```
return new_user
```
Returns the new user record. Thanks to ```response_model=UserOut```, the client will receive a clean JSON payload containing just the ```id``` and ```email```.

### 4. The login endpoint(User authentication)
``` 
@router.post("/login")
def login(user_data: UserCreate, db: Session = Depends(get_db)):
```
This sets up a POST route at ```/auth/login``` that expects an email and password payload.
``` 
user = db.query(User).filter(User.email == user_data.email).first()
```
This looks up the email address in the database to see if the user even has an account.
``` 
if not user or not verify_password(user_data.password, user.hashed_password):
    raise HTTPException(status_code=400, detail="Invalid credentials")
```
* If the email isn't found (```not user```), OR if the plain password they typed doesn't mathematically match the hashed password on file (```not verify_password(...)```), it rejects them with an "Invalid credentials" error.
* <strong>Security tip:</strong> Notice it doesn't say "Wrong password"—keeping it ambiguous prevents hackers from guessing which emails are registered in your database!

``` 
token = create_access_token(data={"sub": str(user.id)})
```
If credentials are correct, we call our security helper to generate a JWT token. The standard practice is to store the user's unique identity database ID inside the key "```sub```" (Subject).
``` 
return {"access_token": token, "token_type": "bearer"}
```
This returns a successful response containing the signed string token and the ```token_type: bearer directive```. Your Flutter app will receive this JSON object, grab the token, and use it to stay logged in. 

<strong>NOTE:</strong>
To understand what a `````"token_type": "bearer"````` directive means, think of the word "bearer" in its literal, old-school sense: the person who bears (holds) this item. 

<strong>💡 The Analogy: A Movie Theater Ticket</strong>
* Imagine you buy a ticket to a movie theater online. The theater doesn't care about your facial recognition, your ID card, or your credit card history when you walk up to the door.
* They only care about one thing: Do you possess the ticket?
* Whoever is bearing (holding) that ticket gets to walk into the theater.
* If you hand the ticket to a friend, your friend gets in.
* If you drop the ticket on the sidewalk and a stranger picks it up, that stranger gets in.

=> **The ticket is a Bearer Token.** The phrase ```"token_type": "bearer"``` is simply telling your Flutter app: 
"Hey, treat this token like a physical movie ticket. Just by holding it, you are authorized to enter."

<strong>💻 The Technical Reality</strong>
* In web development, **Bearer** is an official web standard (part of the OAuth 2.0 framework).
* When your FastAPI backend sends back ```{"token_type": "bearer"}```, it is giving explicit instructions to your Flutter app on how it expects to receive that token in future requests. 
* It tells Flutter exactly how to format the network headers when it wants to fetch protected data (like a user's private profile).
* **How Flutter uses this directive:**
Because the backend specified that the type is bearer, your Flutter app knows it must store that token and attach it to the Authorization header of every subsequent HTTP request using a very specific format:
```
Authorization: Bearer <your_actual_jwt_token_string>
```
When a request arrives at your backend, FastAPI looks for that exact word—Bearer—followed by the space and the token string. If it sees it, it unpacks the token, verifies it, and grants access.
* **Why is this directive important?**
There are other token types in the tech world (like Hawk or MAC tokens), which require complex cryptographic signing for every single request. By explicitly stating ```"token_type": "bearer"```, the API clarifies that no extra encryption math is needed on the frontend. The Flutter app just needs to copy-paste that token into the header, and it's good to go.

---
## 10. Updated ```main.py```
``` 
from fastapi import FastAPI
from apis.auth import router as auth_router

app=FastAPI()

app.include_router(auth_router)

@app.get("/")
def root():
    return {"message": "Biblo backend running"}
```
<strong>💡 The Analogy: Plugging an Extension Cord into the Wall</strong>
* Imagine you just bought a brand-new, high-tech gourmet blender for your kitchen. You set it on the counter. It’s fully assembled, perfectly engineered, and completely ready to make smoothies.
* But right now, it’s just sitting there doing nothing. Why? Because it isn’t plugged into the wall outlet.
* ```main.py``` is your kitchen's main electrical wall outlet (the power source for your whole app).
* ```auth.py``` (the file where you wrote your login logic) is that beautiful new blender.
* ```app.include_router(auth_router)``` is the act of physical plugging the blender's cord into the wall socket.
* Until you plug it in, your kitchen (```main.py```) has no idea the blender exists, and turning the blender's knobs won't do anything. Once plugged in, power flows, and the blender becomes an active part of your kitchen.

<strong>💻 The Technical Reality</strong>
* When you start a FastAPI application, you run a command pointing directly to ```main.py``` (e.g., ```uvicorn main:app```). 
* FastAPI reads ```main.py``` from top to bottom to map out all the URLs (endpoints) it needs to listen for.
* If your authentication code is sitting in a file named ```auth.py```, FastAPI doesn't automatically go hunting through your folders to find it. 
* You have to explicitly import it and register it.

Line-by-Line Breakdown:
```
from .api.auth import router as auth_router
```
* This goes into your folders, looks inside the api directory, opens the auth file, and grabs the router you built there. 
* We rename it as ```auth_router``` just to be incredibly clear about what it is.
```
app = FastAPI()
```
**This initializes your main web server application object. This is the heart of your backend.**
```
app.include_router(auth_router)
```
This tells your main app: 
"Take every single URL endpoint written inside auth_router (like ```/login```, ```/register```, ```/logout```) and copy-paste them into your main URL map."
```
@app.get("/")
```
* This is just a simple "Health Check" route left at the base of your main file. 
* If you open your browser to http://localhost:8000/, it will return:
```
{"message": "Biblo backend running"}
 ```
just to prove to you that your server is alive and successfully turned on.

<strong>NOTE:</strong>
Similar to the ```auth_router```, if you have a folder structure for machine learning or recommendation routes, you import that specific router and plug it into ```main.py``` the exact same way.

Assuming your folder structure looks something like this:
```

└── my_project/
├── main.py
├── api/
│   └── auth.py          # Contains auth_router
└── ml/
└── recommendations.py   # Contains rec_router
```
Your ```main.py``` code will look like this:
```
from fastapi import FastAPI
from .api.auth import router as auth_router
from .ml.recommendations import router as rec_router 

app = FastAPI()

# Registering both "wings" of your application
app.include_router(auth_router)
app.include_router(rec_router) 

@app.get("/")
def root():
    return {"message": "Biblo backend running"}
```

---
## 11. Run Alembic migrations to create the users table in PostgreSQL

### 1. Run the following command in the terminal:
```
alembic init alembic
```

<strong>NOTE:</strong>
* You might run into errors if a directory named alembic already exists. To avoid any such errors, delete the directory beforehand.
* After the above command successfully executes, it automatically creates:

  * A new folder named ```alembic``` inside your backend directory (containing your migration environment files).
  * A file named ```alembic.ini``` (this file will be on the same level as ```main.py```).

### 2. Now, configure alembic.ini with your DB URL:
```
sqlalchemy.url = driver://user:pass@localhost/dbname
```
Here is what each placeholder piece means, and exactly what you should type in its place:

* ```driver```: The type of database and the Python library you are using to talk to it. 
* For a standard local setup using PostgreSQL or SQLite, this will look like:
  * **For PostgreSQL**: ```postgresql+psycopg2```
  * **For SQLite** (simplest local setup): ```sqlite:///```
* ```user```: Your database username (often postgres by default for PostgreSQL).
* ```pass```: The password you chose when you installed/setup your database.
* ```localhost```: This literally means "this computer." It's the network address for your own machine (127.0.0.1).
* ```dbname```: The specific name of the database you created for this project.

### 3. Update ```alembic/env.py```
In the file, make the following update:
```
from backend.database import Base
from backend.models.user import User
target_metadata = Base.metadata
```

<strong>NOTE:</strong>
Make sure that your ```.env``` file is in the root and NOT inside the ```backend/``` directory.
### 4. Now, run the following commands:
```
alembic revision --autogenerate -m "create users table"
alembic upgrade head
```
Now, to check if the table was successfully created, try either of these:

1. Check:
```
biblo\Databases\BIBLO\Schemas\public\Tables\users
```
If you don't see the ```users``` under ```Tables``` then Alembic could not detect your models.

2. Check:
In 
```
biblo/
└── alembic/
    └── versions/
```
Look for a file named something like:
```a1b2c3d4_create_users_table.py```

If it contains something like:
``` 
def upgrade():
    op.create_table(
        'users',
        ...
    )
```
then Alembic successfully detected your model.

However, if the file looks like this:
```
def upgrade():
pass

def downgrade():
pass
```
then Alembic did NOT detect your User model.
=> The most common reason is that env.py imports Base but never imports the model definitions.

## 12. Resolving ```ImportError: attempted relative import beyond top-level package.```
### **Error:**
This error occurs when Python encounters a relative import that tries to move outside the package hierarchy.

For example:
``` 
from ..database import get_db
```
Here, the ```..``` means:
"Go up one package level."

However, if Python is not treating the current file as part of a package, there is no parent package to move up to.

In Biblo, this happened because files were being executed in a way that caused Python to treat them as standalone modules rather than members of the backend package.

### **Solution:**
Run the application from the project root and import using package-aware imports.
So, instead of running:
``` 
cd backend
uvicorn main:app --reload
```

Run:
``` 
cd ..
uvicorn backend.main:app --reload
```

This tells Python:
"```backend``` is a package"

**Additional points:**
Relative imports only work when Python recognizes the module as part of a package.

Examples:
``` 
from .database import get_db
from .models.user import User
```
These require the file to be inside a package structure.

Running modules directly often breaks relative imports.

### **NOTE:**
**💡 The Analogy: The "Family Tree" vs. The Standalone Nomad**
* Imagine you are looking at a family tree.
* You can say, "This is my brother" or "That is my uncle" because everyone in the room is connected to the same shared family tree. Everyone knows exactly who "my" refers to.
* Now, imagine a total stranger walks into a random coffee shop downtown, stands on a chair, and shouts, "I am going to visit my brother!" * The people in the coffee shop will stare blankly. Why? Because the stranger is acting as a standalone nomad. They aren't inside a family reunion where everyone knows their context. Nobody knows who "my" is.
* In Python:
  * A Package is that family reunion. It’s a folder structure where Python explicitly knows how files are related to each other.
  * Running a module directly is like that stranger in the coffee shop. The file is executed completely on its own, losing all context of its "family tree" neighbors.

**💻 The Technical Reality**
* To Python, a folder isn't automatically a "package" just because it holds files. 
* A folder becomes a package when Python looks at it from the outside as part of a larger system.

#### 1. **What does "Recognized as part of a package" mean?**
    
* When you use a relative dot (.), you are telling Python:
  => "Look at my internal name (```__name__```), find my parent package, and look next door."

* If your project looks like this:
```
backend/
├── main.py
└── apis/
└── auth.py
```

* If you start your app from ```main.py```, Python loads ```main.py``` as the king of the castle. 
* When ```main.py``` imports ```apis.auth```, Python records ```auth.py```'s official family name as ```apis.auth```.
* Because its name is ```apis.auth```, it has a parent (```apis```). If you use a relative import inside ```auth.py``` now, Python says: 
* "Ah, your parent is apis, so I know exactly where to look!"

#### 2. **Why "Running modules directly" breaks it**
   
* When you open a terminal and tell Python to run a file directly—like typing python apis/auth.py or when an external tool forces a script to run on its own—Python isolates that file completely.
* The moment a file is run directly, Python intentionally wipes out its family name and replaces it with a generic standalone title: ```__main__```.
* Look what happens to your relative import now:

```
# Inside auth.py (Run directly)
from .database import get_db
```

* Python reads the dot (```.```) and asks: 
"Okay, what is your parent package?" 

* It checks the file's name, sees ```__main__```, and notices there are no dots or parent folders attached to that name. 
* It realizes this file is a standalone nomad in a coffee shop.
* Because it has no recognized parent package, Python throws the mentioned error.

#### 3. **🛠️ The Golden Rule to Take Away**
   * Relative imports (```.```, ```..```) are highly fragile because they depend entirely on how the code was kicked off. If a file is executed directly or from the wrong directory, the dots break instantly.
   * Absolute imports (from database import get_db) are rock-solid. They tell Python: 
   => "I don't care who my parent package is or how I was executed. Just start looking from our project base camp folder and find the file."

## 13. Why are there blank __init__.py files in the project directories?

* A directory without an ```__init__.py``` file is normally treated as an ordinary folder.
* A directory with an ```__init__.py``` file (the file can remain completely empty) is treated as a Python package.

Example:
``` 
backend/
├── __init__.py
├── database.py
├── main.py
```

Now Python understands:
``` 
backend.database
backend.main
```

## 14. The importance of using package relative imports

When running:
```
uvicorn backend.main:app
```
imports should generally look like:
```
from .apis.auth import router
from .database import get_db
from .models.user import User
```
or
```
from backend.apis.auth import router
from backend.database import get_db
```
Pick one style and use it consistently.

Don't mix:
```
from apis.auth import ...
from ..database import ...
```
because those assume different package layouts.

## 15. Where the packages installed in the virtual environment live?
* A common question during development is:
"Should I run pip install from the project root or inside backend?"

* The answer is neither location matters.
* What matters is which virtual environment is currently active.

Example:

* Activate the virtual environment first via the terminal:
```
venv\Scripts\Activate
```
* Then run from anywhere:
```
pip install "pydantic[email]"
```
The package gets installed into:
```
C:\Projects\biblo\venv\Lib\site-packages\
```
```
venv/
└── Lib/
    └── site-packages/
```
because that's where your active virtual environment lives.

Examples:
```
C:\Projects\biblo>
pip install "pydantic[email]"
C:\Projects\biblo\backend>
pip install "pydantic[email]"
C:\Projects>
pip install "pydantic[email]"
```
All three get installed into the same environment.

## 16. AttributeError: module 'bcrypt' has no attribute '__about__'

### **Error:**
While hashing passwords, Passlib attempted to communicate with the installed bcrypt package.

The environment contained:
```
passlib 1.7.4
bcrypt 5.0.0
```
Passlib expected:
```
bcrypt.__about__.__version__
```
but bcrypt 5 removed that attribute. So, this is a compatibility issue between Passlib and newer bcrypt versions.

### **Solution:**
* Check installed versions:
```
pip show passlib
pip show bcrypt
```
* Downgrade bcrypt:
Inside your activated virtual environment:
```
pip uninstall bcrypt
pip install "bcrypt<5"
```
or more specifically:
```
pip install bcrypt==4.0.1
```

### **Additional points:**
* A second symptom appeared:
```
ValueError: password cannot be longer than 72 bytes
```
even though the password was:
```
srishti
```
which is only 7 characters.

* This strongly suggested the problem was not the password itself.
* Instead, the Passlib ↔ bcrypt integration was malfunctioning due to version incompatibility.
* Once bcrypt was downgraded, password hashing behaved normally.

## 17. Consideration: Eventually switching to pwdlib from passlib
### **Context:**
Passlib has historically been the standard password hashing library for FastAPI projects.

However:

* Development activity has slowed.
* Compatibility issues occasionally arise with newer bcrypt versions.
* Modern FastAPI examples increasingly use Pwdlib.

### **Benefits of Pwdlib:**
* A typical setup looks like:
```
from pwdlib import PasswordHash
password_hash = PasswordHash.recommended()
```
Hashing:
```
hashed = password_hash.hash(password)
```
Verifying:
```
password_hash.verify(password, hashed)
```

### **Additional Points:**
#### **Option A: Continue with Passlib**
```
pip install bcrypt==4.0.1
```
Finish:

* Signup
* Login
* JWT authentication
* Remaining tutorial steps

Pros:

* Minimal disruption
* Notes remain valid
* Faster progress

#### **Option B: Switch to Pwdlib**

Refactor authentication immediately.

Pros:

* More modern stack
* Fewer dependency issues

Cons:

* Requires changes while debugging
* More documentation updates



