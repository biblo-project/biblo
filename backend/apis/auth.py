from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session
from backend.database import get_db
from backend.models.user import User
from backend.schemas.user import UserCreate, UserOut, UserLogin
from backend.core.security import  hash_password, verify_password, create_access_token

# imports to fire the "login" event to Kafka
import json
from confluent_kafka import Producer

router = APIRouter(prefix="/auth", tags=["Authentication"])

#___________________________________________________________
# signup
@router.post("/signup", response_model=UserOut)
def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    # check if the user exists
    db_user = db.query(User).filter(User.email == user_data.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = User(
        email=user_data.email,
        username=user_data.username,
        hashed_password=hash_password(user_data.password)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

#___________________________________________________________
# login
@router.post("/login")
def login(user_data: UserLogin, db: Session = Depends(get_db)):

    # .strip() prevents issues if the user accidentally typed a trailing space
    identifier = user_data.username_or_email.strip()

    user=db.query(User).filter(
        or_(
            User.username == identifier,
            User.email == identifier
        )
    ).first()
    if not user or not verify_password(user_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token(data={"sub": str(user.id)})

    login_event = {
        "event_type": "user_logged_in",
        "user_id": user.id
    }

    # fire the event right after a successful credential check
    try:
        Producer.produce(
            topic="user-logins",
            key=str(user.id),
            value=json.dumps(login_event).encode('utf-8')
        )

        Producer.flush() # force Kafka to send the event immediately

    except Exception as kafka_error:
        print(f"Failed to publish login event: {kafka_error}")

    return {"access_token": token, "token_type": "bearer"}