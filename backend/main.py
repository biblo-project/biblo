from fastapi import FastAPI
from .apis.auth import router as auth_router

app=FastAPI()

app.include_router(auth_router)

@app.get("/")
def root():
    return {"message": "Biblo backend running"}