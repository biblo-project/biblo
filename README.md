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
