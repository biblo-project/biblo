# backend/schemas/notification.py
from pydantic import BaseModel

class PostLoginNotificationPayload(BaseModel):
    type: str
    user_id: int
    question: str
    buttons: list