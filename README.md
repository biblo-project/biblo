# Biblo
Reading tracker and book recommendation Android application

## Concept notes

### Recommended Architecture (Initial, small scale)
```
Flutter App <=> Monolith Backend API Server <=> Database
```
No need for proxy yet since at this stage we're not creating microservices

In the backend, there are logically separate features — physically in one service.

### Functionalities 
1. User sign-up/login 
2. Get random suggestions (nothing to do with ML) 
3. Get curated suggestions (using ML) 
4. Update preferences (for the ML component to use for generating suggestions) 
5. Play a game 

     a. Fill-In-The-Blanks 
     b. Identify-the-book-from-the-dialogue 
     c. Match-the-authors-with-the-books  

### Domains
1. Auth Domain
2. Recommendation Domain
3. Game Domain

### Modular monolith
<img src="concept-notes/modular-monolith.png" width="600"/></td>

### Database design

1. Users
```
id (UUID)
username
email
password_hash
created_at
```
2. Books
```
id
title
author
genre
theme
trope
era
setting
pub_year
```
3. Quotes
```
id
book_id (foreign key)
quote_text
difficulty_level
```
4. Games
```
id
user_id
score
started_at
ended_at
```
### Rough notes
<table>
  <tr>
    <td><img src="concept-notes/biblo-concept-notes_1.jpg.jpeg" width="600"/></td>
    <td><img src="concept-notes/biblo-concept-notes_2.jpg.jpeg" width="600"/></td>
    <td><img src="concept-notes/biblo-concept-notes_3.jpeg" width="600"/></td>
  </tr>
</table>

### Games:
* Tic-Tac-Toe
* Rock-Paper-Scissors
* Coin-Toss
* Quiz game teaching the user about women in literature
* Card game
  1. There are two players that play against each other: the user and Biblo
  2. Both the players have a counter measuring their health in a number. The counter changes colours to depict the current health of the player. It's colours are: <br/>

     a. Green if the player's health is above a certain threshold, indicating that it is good <br/>
     b. Yellow if the player's health is within a certain range, indicating that it is low <br/>
     c. Red if the player's health is below a certain threshold, indicating that it's poor and the player could lose soon <br/>

  3. The game or "battle" is timed with a timer on screen.
  4. The user has a stack of cards from which they'll select one. On the screen you'll see two boxes, one displaying the current card and the other displaying the stack with just "stack" displayed on top of it.
  5. The can see what cards they have in a pop with left and right moving buttons to show them their collection of cards, and they can select one of them to play next.
  6. Biblo's card selection will be random.
  7. Both the user's and Biblo's card selection will be randomly decided. While the user can select the next card to play, Biblo will randomly select a card from its randomly selected collection.
  8. The cards are about popular mythical characters like vampires, werewolves, elves, dragons, pegasuses, goblins, etc. with different stats.
  9. There are 3 group of cards: <br/>
  
     a. "Common": Normal stats, not too high, not too low <br/>
     b. "Rare": Underpowered characters, low stats <br/>
     c. "Legendary": Overpowered characters, high stats <br/>

    NOTE: All the characters stats are balanced <br/>
 10. The stats of both the players get balanced out based on differences between their different stats.
 11. If a player has legendary cards, against the other player's non-legendary cards, then their health will increase by a small number (apart from the balancing out between their respective stats)
 12. If a player has  a rare card, against the other player's non-rare cards, their health will decrease by a small number (apart from the balancing out between their respective stats) 
 13. Common cards have no special effects similar to the legendary and rare cards

## Concept art
<table>
  <tr>
    <td><img src="concept-art/biblo-concept-art_1.jpg.jpeg" width="600"/></td>
    <td><img src="concept-art/biblo-concept-art_2.jpg.jpeg" width="600"/></td>
  </tr>
  <tr>
    <td><img src="concept-art/biblo-concept-art_3.jpg.jpeg" width="600"/></td>
    <td><img src="concept-art/biblo-concept-art_4.jpg.jpeg" width="600"/></td>
  </tr>
  <tr>
    <td><img src="concept-art/biblo-concept-art_5.jpg.jpeg" width="600"/></td>
    <td><img src="concept-art/biblo-concept-art_6.jpg.jpeg" width="600"/></td>
  </tr>
  <tr>
    <td><img src="concept-art/biblo-concept-art_7.jpg.jpeg" width="600"/></td>
    <td><img src="concept-art/biblo-concept-art_8.jpg.jpeg" width="600"/></td>
  </tr>
     <tr>
    <td><img src="concept-art/biblo-concept-art_9.jpeg" width="600"/></td>
  </tr>
</table>

## Backend structure
The backend structure being setup:
```
backend/
│
├── main.py
├── database.py
├── config.py
├── .env
├── requirements.txt
│
├── models/
│   ├── __init__.py
│   ├── user.py
│   ├── book.py
│   ├── quote.py
│   └── games/
│       ├── __init__.py
│       ├── fill_in_the_blanks.py
│       ├── identify_the_book.py
│       ├── match_authors.py
│       └── card_game.py
│
├── schemas/
│   ├── __init__.py
│   ├── user.py
│   ├── book.py
│   ├── quote.py
│   └── games/
│       ├── __init__.py
│       ├── fill_in_the_blanks.py
│       ├── identify_the_book.py
│       ├── match_authors.py
│       └── card_game.py
│
├── api/
│   ├── __init__.py
│   ├── auth.py
│   ├── users.py
│   ├── books.py
│   ├── recommendations.py
│   └── games/
│       ├── __init__.py
│       ├── fill_in_the_blanks.py
│       ├── identify_the_book.py
│       ├── match_authors.py
│       └── card_game.py
│
├── services/
│   ├── __init__.py
│   ├── recommendation_service.py
│   └── games/
│       ├── __init__.py
│       ├── fill_in_the_blanks_service.py
│       ├── identify_the_book_service.py
│       ├── match_authors_service.py
│       └── card_game_service.py
│
├── core/
│   ├── __init__.py
│   ├── security.py
│   └── auth.py
│
├── ml/
│   ├── __init__.py
│   └── recommender.py
│
└── alembic/
     └── alembic.ini
```
## Packages installed
```
py -m pip install fastapi uvicorn sqlalchemy psycopg2-binary python-dotenv alembic passlib[bcrypt] python-jose[cryptography]
```

## Biblo — Kafka & OpenSearch Integration Plan
### Overview
* PostgreSQL remains the primary database and source of truth.
* Kafka and OpenSearch are additions that enhance performance and intelligence — they do not replace PostgreSQL.

### 1. Apache Kafka
**Role:** Message broker that captures user activity as real-time events.
**Where it fits:**

* Every meaningful user action generates a Kafka event
* These events continuously feed the ML recommendation engine with live user behaviour data

**Events to track:**
```
user_viewed_book
user_played_game
user_updated_preferences
user_saved_book
```
**When to add:** After the curated (ML-based) recommendations are working.

### 2. OpenSearch
**Role:** Powers fast book search and recommendation display.
**Where it fits:**

* Handles book search queries instead of querying PostgreSQL directly (faster at scale)
* Supports fuzzy search — typos still return correct results
* Can power the curated recommendations display layer

**When to add:** After book search is working with PostgreSQL.

### How the full stack connects
User action (Flutter)
→ FastAPI
→ Kafka (logs the event)
→ ML module (reads Kafka events, updates recommendations)
→ OpenSearch (indexes and serves results)
→ Flutter displays results

### Technology summary

**PostgreSQL** — permanent data storage (users, books, preferences, game scores)
**OpenSearch** — fast search and retrieval layer on top of PostgreSQL data
**Kafka** — real-time event streaming layer feeding the ML module

## Updated DB design

### Tables:
```
users
├── id
├── email
├── hashed_password
└── username

user_genres
├── id
├── user_id → (foreign key to users.id)
└── genre

books
├── id
├── title
├── author
└── description   

book_genres
├── id
├── book_id → (foreign key to books.id)
└── genre

quotes
├── id
├── book_id → (foreign key to books.id)
└── quote_text

reading_list
├── id
├── user_id → (foreign key to users.id)
├── book_id → (foreign key to books.id)
└── status  → (to_read / reading / read)
```

### Relationships:
``` 
users ──────< user_genres

books ──────< book_genres

books ──────< quotes

users ──────< reading_list >────── books
```

### Notes:

* book_genres and user_genres follow the same pattern — one row per genre instead of a comma-separated string
* reading_list is a junction table between users and books — it handles the many-to-many relationship
* One user can have many reading list entries 
* One book can appear in many users' lists 
* One book can have many genres 
* One user can have many preferred genres

## Explanation of curated recommendations ML logic
Installed the following libraries:
* scikit-learn
* pandas
* numpy

Here is the step-by-step breakdown of how your machine learning recommendation endpoint processes data behind the scenes:

### 1. User Authentication & Preference Extraction

* **Route Protection:** The endpoint uses FastAPI dependencies (`Depends`) to verify the logged-in user and open a secure database connection.
* **Preference Gathering:** It queries the database to see which genres the current user has selected.
* **The Empty Guard:** If the user has not selected any genres yet, the engine skips the math entirely and simply returns a fallback list of 10 generic books.

---

### 2. Building the "Feature Soup" (Data Preparation)

* **Database Gathering:** The code pulls your entire catalog of books out of PostgreSQL and converts it into a structured Pandas DataFrame.
* **Text Merging:** For every single book, it gathers the title, author, description, and its mapped genres, joining them together into a long string called a **"feature soup."** This acts as the book's textual footprint.

---

### 3. Vectorization (TF-IDF Matrix Construction)

* **Turning Words into Numbers:** Computers can't calculate mathematical distance on raw text, so the code initializes a `TfidfVectorizer`.
* **Filtering Noise:** It strips out common, low-value words (like "the", "and", "is") using English `stop_words`.
* **The Matrix:** It converts the text blocks into a huge numerical table (the `tfidf_matrix`) where every unique word represents a distinct geometric dimension, and the numbers represent how uniquely important that word is to that specific book.

---

### 4. Training the KNN Neighborhood Map

* **Engine Configuration:** It spins up a $K$-Nearest Neighbors (`NearestNeighbors`) algorithm configured to look for the **5 closest matches** (`n_neighbors=5`).
* **The Angle Calculation:** It uses the **`cosine` metric**, which measures the *angle* between text vectors in geometric space rather than word counts. This ensures a long book description and a short book description map perfectly if they use the same types of vocabulary.
* **In-Memory Fitting:** It trains the engine (`knn.fit`) instantly on your book catalog matrix, mapping where every book sits relative to the others.

---

### 5. Creating the User Vector

* **User Modeling:** The code grabs the user's selected genres and joins them into a single text string (e.g., `"Sci-Fi Cyberpunk"`).
* **Dimensional Alignment:** It runs this text through the exact same `tfidf.transform` tool so the user's tastes are converted into a mathematical coordinate that exists inside the exact same geometric space as the books.

---

### 6. Distance Calculation & Recommendation Extraction

* **The Query:** The code fires `knn.kneighbors(user_vector)`. The trained model drops the user's coordinate into the geometric web and calculates which 5 books have the smallest angular distance from the user.
* **Returning Database Objects:** The algorithm returns a list of numerical index coordinates. The code takes those layout positions, grabs the original PostgreSQL SQLAlchemy `Book` objects out of the DataFrame, and drops them into a clean array.

FastAPI automatically serializes these 5 database objects into JSON and sends them right down to your Flutter application's vertical layout!