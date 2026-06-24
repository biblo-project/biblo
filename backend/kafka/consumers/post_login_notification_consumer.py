import json
import random
import time
from confluent_kafka import Consumer, KafkaError

# Import your real database session and models
from backend.database import get_db
from backend.models.user import User
from backend.models.book import Book

import requests

# 1. Configure the Consumer to listen to the login stream
conf = {
    'bootstrap.servers': 'localhost:9092,localhost:9094,localhost:9095',
    'group.id': 'notification-popup-group',
    'auto.offset.reset': 'latest',  # Only listen to new logins happening right now
    'enable.auto.commit': True
}

consumer = Consumer(conf)
consumer.subscribe(['user-logins'])

# 2. In-memory dictionary to track the last book shown per user session
# Structure: { user_id: last_shown_book_id }
last_shown_book_tracker = {}

print("Notification consumer engine started. Listening for user logins...")

try:
    while True:
        # Check for a login event (timeouts after 1.0 second if idle)
        msg = consumer.poll(1.0)
        
        if msg is None:
            continue
        if msg.error():
            if msg.error().code() == KafkaError._PARTITION_EOF:
                continue
            else:
                print(f"Kafka error: {msg.error()}")
                break

        # --- A User Just Logged In! ---
        try:
            # Decode the event data
            event = json.loads(msg.value().decode('utf-8'))
            user_id = event.get("user_id")
            print(f"\nDetected login event for User ID: {user_id}")

            # Connect to your Postgres database using your existing get_db utility
            # We use next() because get_db is a generator function
            db = next(get_db())
            try:
                # 1. Fetch all books from your Postgres table to choose from
                all_books = db.query(Book).all()
                if not all_books:
                    print("No books found in the database to recommend.")
                    continue

                # 2. Get the book ID we showed this specific user last time (if any)
                last_book_id = last_shown_book_tracker.get(user_id)

                # 3. Filter out that last book so the current recommendation is strictly different
                eligible_books = [book for book in all_books if book.id != last_book_id]
                
                # Fallback safeguard: if your DB only has 1 book total, just use all books
                chosen_book = random.choice(eligible_books if eligible_books else all_books)

                # 4. Update our in-memory tracker with the new selection
                last_shown_book_tracker[user_id] = chosen_book.id

                # 5. Mock user genres for the prompt text
                # (Later, you can query your user preferences table here!)
                genre1, genre2 = "Sci-Fi", "Fantasy"

                # 6. Build the final JSON payload for the front-end pop-up
                popup_payload = {
                    "type": "POPUP_NOTIFICATION",
                    "user_id": user_id,
                    "question": f"You might like '{chosen_book.title}' by {chosen_book.author} since you like {genre1} and {genre2}",
                    "buttons": [
                        {"text": "Yes please", "action": "accept", "book_id": chosen_book.id},
                        {"text": "Nah, later", "action": "dismiss"}
                    ]
                }

                # 7. Print out the exact package ready for delivery
                print(f"SENDING POP-UP PAYLOAD TO FRONTEND:")
                print(json.dumps(popup_payload, indent=2))

                try:
                    response = requests.post(
                        "http://localhost:8000/internal/send-notification",
                        json=popup_payload,
                        timeout=2
                    )
                    print(f"Dispatch status: {response.json()}")
                except Exception as e:
                    print(f"Could not dispatch to WebSocket gateway: {e}")

            finally:
                db.close()  
                # Always close your database connection when done

        except Exception as process_error:
            print(f"Failed to process login notification event: {process_error}")

except KeyboardInterrupt:
    print("\nShutting down notification consumer daemon...")
finally:
    consumer.close()
    print("Notification consumer connection closed cleanly.")