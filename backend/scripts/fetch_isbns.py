"""
One-time utility script: fetch_isbns.py

Purpose:
    Loop through every book in the Biblo `books` table that is missing an
    ISBN, look it up using the Open Library Search API, and update the
    row with the ISBN found.

How to run:
    1. Activate your venv:        venv\\Scripts\\activate
    2. Install requests if needed: pip install requests
    3. Run from the backend folder: python fetch_isbns.py

Notes:
    - This script is NOT part of your FastAPI app. It's a one-off helper
      you run manually whenever you add new books without an ISBN.
    - It uses your existing SQLAlchemy database setup (database.py, models/book.py)
      so it stays consistent with the rest of your backend.
"""

import time
import requests

from backend.database import SessionLocal
from backend.models.book import Book


OPEN_LIBRARY_SEARCH_URL = "https://openlibrary.org/search.json"


def fetch_isbn_for_book(title: str, author: str, max_retries: int = 2) -> str | None:
    """
    Calls the Open Library Search API for a given title + author
    and returns the first ISBN found, or None if nothing usable is found.

    Retries up to `max_retries` times on network errors (timeouts, etc.)
    before giving up on this particular book.
    """
    params = {
        "title": title,
        "author": author,
        "limit": 1,  # we only need the first/best match
        # Explicitly ask for these fields - without this, Open Library's
        # search.json response is often missing the isbn field entirely,
        # even when the book has ISBNs in its full record.
        "fields": "title,author_name,isbn,edition_key",
    }

    response = None

    for attempt in range(1, max_retries + 1):
        try:
            response = requests.get(OPEN_LIBRARY_SEARCH_URL, params=params, timeout=15)
            break  # success - no need to retry
        except requests.exceptions.RequestException as e:
            print(f"  [!] Network error for '{title}' (attempt {attempt}/{max_retries}): {e}")
            if attempt < max_retries:
                time.sleep(3)  # brief pause before retrying
            else:
                return None  # out of retries, give up on this book

    # If the API call itself failed (bad response, server error, etc.)
    if response is None or response.status_code != 200:
        status = response.status_code if response is not None else "no response"
        print(f"  [!] API call failed for '{title}' (status {status})")
        return None

    data = response.json()
    docs = data.get("docs", [])

    if not docs:
        # Title + author combo found nothing - this can happen when the
        # author name format doesn't match Open Library's records exactly
        # (e.g. "James S.A. Corey" being a pen name, or subtitles in the
        # title confusing the search). Retry with title only, no author filter.
        print(f"  [!] No results for '{title}' + author filter, retrying with title only...")

        fallback_params = {
            "title": title,
            "limit": 1,
            "fields": "title,author_name,isbn,edition_key",
        }
        try:
            response = requests.get(OPEN_LIBRARY_SEARCH_URL, params=fallback_params, timeout=15)
        except requests.exceptions.RequestException as e:
            print(f"  [!] Network error on fallback search for '{title}': {e}")
            return None

        if response.status_code != 200:
            return None

        data = response.json()
        docs = data.get("docs", [])

        if not docs:
            print(f"  [!] Still no results found for '{title}' (title-only search)")
            return None

    first_result = docs[0]
    isbn_list = first_result.get("isbn")

    if isbn_list:
        # Open Library often returns multiple ISBNs (different editions).
        # We just take the first one for simplicity.
        return isbn_list[0]

    # FALLBACK: the search result didn't include an isbn field directly,
    # but it usually includes edition_key(s) - the unique IDs of specific
    # printed editions. We can fetch one of those editions directly and
    # read its ISBN from there instead.
    edition_keys = first_result.get("edition_key")

    if not edition_keys:
        print(f"  [!] Result found for '{title}' but it has no ISBN or edition_key")
        return None

    first_edition_key = edition_keys[0]
    edition_url = f"https://openlibrary.org/books/{first_edition_key}.json"

    try:
        edition_response = requests.get(edition_url, timeout=15)
    except requests.exceptions.RequestException as e:
        print(f"  [!] Network error fetching edition for '{title}': {e}")
        return None

    if edition_response.status_code != 200:
        print(f"  [!] Could not fetch edition record for '{title}'")
        return None

    edition_data = edition_response.json()

    # Editions store ISBNs as isbn_13 and/or isbn_10 - prefer isbn_13
    edition_isbn_13 = edition_data.get("isbn_13")
    edition_isbn_10 = edition_data.get("isbn_10")

    if edition_isbn_13:
        return edition_isbn_13[0]
    elif edition_isbn_10:
        return edition_isbn_10[0]
    else:
        print(f"  [!] Edition record for '{title}' has no ISBN either")
        return None


def main():
    db = SessionLocal()

    try:
        # Only fetch books that don't already have an isbn set
        books_missing_isbn = db.query(Book).filter(
            (Book.isbn == None) | (Book.isbn == "")
        ).all()

        print(f"Found {len(books_missing_isbn)} books missing an ISBN.\n")

        for book in books_missing_isbn:
            print(f"Looking up: '{book.title}' by {book.author}...")

            isbn = fetch_isbn_for_book(book.title, book.author)

            if isbn:
                book.isbn = isbn
                db.commit()
                print(f"  -> Updated with ISBN: {isbn}\n")
            else:
                print(f"  -> Skipped (no ISBN found)\n")

            # Be polite to Open Library's free API - small delay between calls
            time.sleep(1)

        print("Done updating ISBNs.")

    finally:
        db.close()


if __name__ == "__main__":
    main()