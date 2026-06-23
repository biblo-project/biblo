from fastapi import FastAPI
from backend.apis.auth import router as auth_router
from backend.apis.genres import router as genres_router
from backend.apis.books import router as random_books_router
from backend.apis.users import router as user_router
from backend.apis.search import router as search_router
from backend.routers import notifications
from backend.core.opensearch import connect_opensearch, close_opensearch
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    connect_opensearch()

    yield

    close_opensearch()

app = FastAPI(lifespan=lifespan)

app.include_router(auth_router)
app.include_router(genres_router)
app.include_router(random_books_router)
app.include_router(user_router)
app.include_router(search_router)
app.include_router(notifications.router)

@app.get("/")
def root():
    return {"message": "Biblo backend running"}