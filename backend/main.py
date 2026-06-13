from fastapi import FastAPI
from backend.apis.auth import router as auth_router
from backend.apis.genres import router as genres_router

app=FastAPI()

app.include_router(auth_router)
app.include_router(genres_router)

@app.get("/")
def root():
    return {"message": "Biblo backend running"}