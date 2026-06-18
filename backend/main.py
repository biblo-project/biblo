from fastapi import FastAPI
from backend.apis.auth import router as auth_router
from backend.apis.genres import router as genres_router
from backend.apis.books import router as random_books_router
from backend.apis.users import router as user_router

app=FastAPI()

app.include_router(auth_router)
app.include_router(genres_router)
app.include_router(random_books_router)
app.include_router(user_router)

@app.get("/")
def root():
    return {"message": "Biblo backend running"}