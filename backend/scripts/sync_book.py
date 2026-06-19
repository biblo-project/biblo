import psycopg2
from psycopg2.extras import RealDictCursor
from opensearchpy import OpenSearch, helpers
import os

# 1. Database and OpenSearch Connection Settings
# Replace these strings with your actual database credentials
DB_SETTINGS = {
    "dbname": "BIBLO",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5432
}

OPENSEARCH_HOST = "localhost"
OPENSEARCH_PORT = 9200
# Pull the admin password directly from your environment or copy your string here
OPENSEARCH_PASSWORD = os.getenv("OPENSEARCH_PASSWORD", "opensearch@SRIS123") 
INDEX_NAME = "biblo_books"

def get_opensearch_client():
    """Initializes and returns a secure OpenSearch connection client."""
    return OpenSearch(
        hosts=[{'host': OPENSEARCH_HOST, 'port': OPENSEARCH_PORT}],
        http_compress=True, # Compresses payloads for faster network transfers
        http_auth=('admin', OPENSEARCH_PASSWORD),
        use_ssl=True,
        verify_certs=False, # Set to False for local testing with self-signed SSL
        ssl_assert_hostname=False,
        ssl_show_warn=False
    )

def create_book_index(client):
    """Creates the OpenSearch index configuration layout if it doesn't exist."""
    # Defining an index pattern ensures fields like authors and descriptions are searchable
    index_body = {
        'settings': {
            'index': {
                'number_of_shards': 3,     # Distributes data evenly across your 3 nodes
                'number_of_replicas': 1    # Keeps backup copies for high availability
            }
        },
        'mappings': {
            'properties': {
                'id': {'type': 'integer'},
                'title': {'type': 'text', 'analyzer': 'english'},
                'author': {'type': 'text', 'analyzer': 'english'},
                'description': {'type': 'text', 'analyzer': 'english'},
                'isbn': {'type': 'keyword'}, # Keyword ensures exact matches for lookups
            }
        }
    }
    
    if not client.indices.exists(index=INDEX_NAME):
        client.indices.create(index=INDEX_NAME, body=index_body)
        print(f"Successfully created fresh index: '{INDEX_NAME}'")
    else:
        print(f"Index '{INDEX_NAME}' already exists. Appending incoming data.")

def fetch_postgres_books():
    """Queries and returns all rows from the books table as dictionaries."""
    conn = psycopg2.connect(**DB_SETTINGS)
    # RealDictCursor returns rows as native Python dicts: {'title': 'Dune', 'author': ...}
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    print("Fetching books catalog from PostgreSQL...")
    cursor.execute("SELECT id, title, author, description, isbn FROM books;")
    books = cursor.fetchall()
    
    cursor.close()
    conn.close()
    return books

def generate_bulk_actions(books):
    """Formats the raw database dictionaries into OpenSearch structural actions."""
    for book in books:
        yield {
            "_index": INDEX_NAME,
            "_id": str(book['id']), # Explicitly map OpenSearch document ID to database primary key
            "_source": {
                "id": book['id'],
                "title": book['title'],
                "author": book['author'],
                "description": book['description'],
                "isbn": book['isbn'].strip() if book['isbn'] else "" # Clean trailing spacing artifacts
            }
        }

def main():
    try:
        # Initialize connections
        client = get_opensearch_client()
        create_book_index(client)
        
        # Get data
        books = fetch_postgres_books()
        if not books:
            print("No books found in the database table to sync.")
            return
        
        # Bulk upload stream
        print(f"Streaming {len(books)} documents into your OpenSearch cluster...")
        success, errors = helpers.bulk(client, generate_bulk_actions(books))
        
        print(f"\nSync complete! Successfully indexed {success} books.")
        if errors:
            print(f"Encountered errors with {len(errors)} items.")
            
    except Exception as e:
        print(f"\nFatal Migration Error: {e}")

if __name__ == "__main__":
    main()