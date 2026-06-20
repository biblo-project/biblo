import json
from confluent_kafka import Producer

# Setup the configuration dictionary for the modern cluster
conf = {
    # Points to your 3-node host ports mapped to your Windows machine
    'bootstrap.servers': 'localhost:9092,localhost:9094,localhost:9095',
    # Optional: A unique ID to identify this script in your Kafka UI logs
    'client.id': 'biblo-fastapi-backend'
}

# Initialize the producer engine
producer = Producer(conf)

def publish_book_event(action: str, book = None, book_id = None):
    """
    Publishes a book change event to the 'book-mutations' Kafka topic.
    
    action: "create", "update", or "delete"
    book: a SQLAlchemy Book object
    """
    # Build your plain Python dictionary payload

    if action == "delete":
        event = {"action": "delete", "book_id": book_id}
    
    else:
        event = {
            "action": action,
            "book_id": book.id,
            "title": book.title,
            "author": book.author,
            "description": book.description,
            "isbn": book.isbn,
        }
    
    # Serialize the payload to json string and encode to standard bytes
    payload_bytes = json.dumps(event).encode('utf-8')
    
    # Send it to the active topic we verified in the UI
    producer.produce('book-updates', value=payload_bytes)
    
    # Block and force immediate delivery to the cluster nodes
    producer.flush()
    
    print(f"Successfully published event: {event}")