from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.database import get_db
from backend.models.user import User
from backend.models.user_genre import UserGenre
from backend.schemas.genres import GenreSelection
from backend.core.auth import get_current_user
from backend.models.book_genre import BookGenre

router = APIRouter(prefix="/genres", tags=["Genres"])

@router.get("/")
def get_genres_dashboard(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
        # Now required to see personalization
):
    # 1. Gather all unique genres across your catalog
    unique_genres = db.query(BookGenre.genre).distinct().order_by(BookGenre.genre.asc()).all()
    all_genres_list = [g[0] for g in unique_genres]

    # 2. Gather only the genres this specific user has selected
    user_saved_genres = db.query(UserGenre.genre).filter(UserGenre.user_id == current_user.id).all()
    user_genres_list = [ug[0] for ug in user_saved_genres]

    # 3. Return a structured dictionary mapping both arrays
    return {
        "all_genres": all_genres_list,
        "selected_genres": user_genres_list
    }

@router.put("/")
def update_genres(
        genre_data: GenreSelection,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    # Step 1: Delete existing genres for this user
    db.query(UserGenre).filter(UserGenre.user_id == current_user.id).delete()

    # Step 2: Insert the new selections
    for genre in genre_data.genres:
        new_genre = UserGenre(user_id=current_user.id, genre=genre)
        db.add(new_genre)

    # Step 3: Commit everything
    db.commit()

    return {"message": "Genres updated successfully"}

'''
Notes:

1. current_user: User = Depends(get_current_user) 
 
This is how you get the logged in user in any endpoint. 
FastAPI automatically runs get_current_user, extracts 
the user from the token, and passes it in

2. We delete existing genres first before inserting new ones 

This is the cleanest way to handle updates to a list

3. PUT is used instead of POST because we're replacing/updating 
existing data, not creating something new for the first time
'''