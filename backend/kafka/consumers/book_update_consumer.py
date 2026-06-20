import json
from confluent_kafka import Consumer, KafkaError
# Assuming your client is initialized in backend/app/opensearch.py 
# Adjust this import line to match your actual file path!
from backend.core.opensearch import connect_opensearch, get_opensearch_client

# 1. Configure the modern Consumer
conf = {
    # Points to your 3-node host ports mapped to your Windows machine
    'bootstrap.servers': 'localhost:9092,localhost:9094,localhost:9095',
    # Unique string identifying this consumer group
    'group.id': 'opensearch-sync-group',
    # Start reading from the beginning if no offsets are committed yet
    'auto.offset.reset': 'earliest',
    # Automatically commit processed messages back to the cluster
    'enable.auto.commit': True
}

consumer = Consumer(conf)

# 2. Subscribe to the active topic we verified in your UI
TARGET_TOPIC = 'book-updates'
consumer.subscribe([TARGET_TOPIC])

connect_opensearch()
client = get_opensearch_client()

print(f"Consumer daemon started. Monitoring stream channel: '{TARGET_TOPIC}'...")

try:
    # Continuous infinite background execution loop
    while True:
        # Check for new messages from Kafka (timeouts after 1.0 second if idle)
        msg = consumer.poll(1.0)
        
        if msg is None:
            continue  # No message arrived, loop back and check again
            
        if msg.error():
            # Handle end of partition signals gracefully vs actual errors
            if msg.error().code() == KafkaError._PARTITION_EOF:
                continue
            else:
                print(f"Kafka stream error encountered: {msg.error()}")
                break

        # 3. Process the raw incoming stream message bytes
        try:
            raw_payload = msg.value().decode('utf-8')
            event = json.loads(raw_payload)
            print(f"Received event from stream: {event}")

            action = event.get("action")
            book_id = event.get("book_id")

            '''
            # Scenario A: Write operations
            if action in ("create", "update"):
                client.index(
                    index="biblo_books",
                    id=str(book_id), # OpenSearch IDs are best handled as strings
                    body={
                        "title": event.get("title"),
                        "author": event.get("author"),
                        "description": event.get("description"),
                        "isbn": event.get("isbn"),
                    }
                )
                print(f"Synced book_id {book_id} cleanly to OpenSearch.")
                '''

            # Scenario A: Write operations
            if action in ("create", "update"):
                # Capture the response returned by OpenSearch
                response = client.index(
                    index="biblo_books",
                    id=str(book_id),
                    body={
                        "title": event.get("title"),
                        "author": event.get("author"),
                        "description": event.get("description"),
                        "isbn": event.get("isbn"),
                    }
                )
                print(f"Synced book_id {book_id} cleanly to OpenSearch.")
                print(f"RAW OPENSEARCH RESPONSE: {json.dumps(response, indent=2)}")

            # Scenario B: Eviction operations
            elif action == "delete":
                try:
                    client.delete(index="biblo_books", id=str(book_id))
                    print(f"Purged book_id {book_id} completely from OpenSearch.")
                except Exception as delete_error:
                    # Prevents the worker from crashing if an admin tries to 
                    # delete a book that was never successfully indexed
                    print(f"Skip delete: Book {book_id} not found in search index ({delete_error}).")

        except json.JSONDecodeError:
            print("Critical: Received a broken message that could not be parsed into JSON.")
        except Exception as e:
            print(f"Failed to process event data packet: {e}")

except KeyboardInterrupt:
    print("\nManual shutdown signal received.")
finally:
    # Clean up and close the cluster connection sockets gracefully on exit
    consumer.close()
    print("Consumer stream connection closed down safely.")