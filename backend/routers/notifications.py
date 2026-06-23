from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict
from backend.schemas.notifications import PostLoginNotificationPayload

# Use APIRouter instead of app directly
router = APIRouter(tags=["Notifications"])

# Global in-memory registry for active connections
active_notification_connections: Dict[int, WebSocket] = {}

# The WebSocket Route your Flutter app hits
@router.websocket("/web-socket/notifications/{user_id}")
async def websocket_notifications_endpoint(websocket: WebSocket, user_id: int):
    await websocket.accept()
    active_notification_connections[user_id] = websocket
    print(f"Flutter app successfully connected via WebSocket for User: {user_id}")
    
    try:
        while True:
            # Keep connection alive
            await websocket.receive_text()
    except WebSocketDisconnect:
        if user_id in active_notification_connections:
            del active_notification_connections[user_id]
        print(f"WebSocket disconnected for User: {user_id}")

# The Internal Endpoint your consumer calls to pass messages
@router.post("/internal/send-notification")
async def send_internal_notification(payload: PostLoginNotificationPayload):
    ws_connection = active_notification_connections.get(payload.user_id)
    if ws_connection:
        await ws_connection.send_json(payload.dict())
        return {"status": "delivered"}
    return {"status": "user_not_connected"}