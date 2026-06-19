from fastapi import APIRouter, Depends, HTTPException, Query
from opensearchpy import OpenSearch
from typing import List

# Import your existing client injector and your existing Pydantic schema
from backend.core.opensearch import get_opensearch_client
from backend.schemas.book import BookOut 

router = APIRouter(prefix="/search", tags=["Search"])

@router.get("", response_model=List[BookOut])
async def search_books(
    q: str = Query(..., description="The search term for titles or authors"),
    client: OpenSearch = Depends(get_opensearch_client)
):
    """
    Search books across title and author fields with built-in typo tolerance.
    """
    if not q.strip():
        return []

    try:
        # Construct the OpenSearch multi_match query
        search_body = {
            "query": {
                "multi_match": {
                    "query": q,
                    "fields": ["title^2", "author"], 
                    # The ^2 gives title matches double weight!
                    "fuzziness": "AUTO"             
                    # Handles typos dynamically (e.g., "harr" -> "harry")
                }
            },
            "size": 20 
            # Limit results to the top 20 best matches
        }

        # Execute the search against your index
        response = client.search(
            index="biblo_books",
            body=search_body
        )

        # Extract the raw hits from the OpenSearch JSON nested structure
        hits = response.get("hits", {}).get("hits", [])
        
        # Pull the original database dictionary fields out of the '_source' block
        books = []
        for hit in hits:
            book_data = hit.get("_source", {})
            books.append(book_data)

        return books

    except Exception as e:
        # Log the error internally and return a clean HTTP exception to the frontend
        import logging
        logger = logging.getLogger("uvicorn.error")
        logger.error(f"OpenSearch query failure: {e}")
        raise HTTPException(status_code=500, detail="Search cluster query encountered an error.")