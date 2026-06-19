import os
import logging
from opensearchpy import OpenSearch
from opensearchpy.exceptions import ConnectionError
from backend.config import settings

# Set up logging to monitor connection handshakes
logger = logging.getLogger("uvicorn.error")

# 1. Environment Configurations
# In production, these will be pulled from your environment variables or .env file

# OPENSEARCH_HOST = os.getenv("OPENSEARCH_HOST", "localhost")
# OPENSEARCH_PORT = int(os.getenv("OPENSEARCH_PORT", 9200))
# OPENSEARCH_USER = os.getenv("OPENSEARCH_USER", "admin")
# OPENSEARCH_PASSWORD = os.getenv("OPENSEARCH_PASSWORD")

OPENSEARCH_HOST = settings.OPENSEARCH_HOST
OPENSEARCH_PORT = settings.OPENSEARCH_PORT
OPENSEARCH_USER = settings.OPENSEARCH_USER
OPENSEARCH_PASSWORD = settings.OPENSEARCH_PASSWORD

# 2. Global Client Placeholder
# This will hold the persistent connection pool across your entire app instance
client: OpenSearch = None


def connect_opensearch() -> OpenSearch:
    """
    Initializes a global secure connection pool to the OpenSearch 3-node cluster.
    Designed to be executed during FastAPI startup.
    """
    global client
    
    # If the client is already initialized, return it
    if client is not None:
        return client

    logger.info(
    f"Connecting to OpenSearch at "
    f"{OPENSEARCH_HOST}:{OPENSEARCH_PORT}"
)
    
    try:
        client = OpenSearch(
            hosts=[{"host": OPENSEARCH_HOST, "port": OPENSEARCH_PORT}],
            http_compress=True,          # Reduces payload sizes over the wire
            http_auth=(OPENSEARCH_USER, OPENSEARCH_PASSWORD),
            use_ssl=True,
            verify_certs=False,          # Set to False for local self-signed SSL certificates
            ssl_assert_hostname=False,
            ssl_show_warn=False,
            pool_maxsize=20              # Max persistent connections to keep open
        )
        
        # Perform a fast cluster health ping to verify everything works instantly
        if client.ping():
            logger.info("Successfully connected to OpenSearch cluster cluster!")
        else:
            logger.error("OpenSearch ping failed. Cluster might be unavailable.")
            
        return client

    except ConnectionError as e:
        logger.error(f"Failed to establish connection to OpenSearch: {e}")
        raise e


def get_opensearch_client() -> OpenSearch:
    """
    FastAPI Dependency Injector. 
    Yields the active global client pool to your endpoints.
    """
    if client is None:
        raise RuntimeWarning("OpenSearch client is uninitialized. Call connect_opensearch() first.")
    return client


def close_opensearch():
    """
    Safely tears down and flushes active transport sockets.
    Designed to be executed during FastAPI shutdown.
    """
    global client
    if client is not None:
        logger.info("Closing active OpenSearch connection pool sockets...")
        client.close()
        client = None
        logger.info("OpenSearch connection pool terminated successfully.")