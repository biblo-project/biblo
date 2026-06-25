# Biblo — Known Limitations & Future Improvements

This document tracks intentional simplifications and known gaps in the current
implementation. These were conscious tradeoffs made to ship features within a
reasonable timeframe, not oversights — each one is documented here so they can
be addressed later, and so the reasoning behind them is preserved.

---

## Data Sync & Architecture

**Kafka CDC only covers application-level writes, not direct database writes.**
The current Postgres → OpenSearch sync pipeline only fires when a book is
created/updated/deleted through a FastAPI endpoint (e.g. the admin book
routes). Any change made directly via pgAdmin or raw SQL bypasses Kafka
entirely and will not sync to OpenSearch.
- *Production fix:* true CDC using a tool like Debezium, which reads
  PostgreSQL's write-ahead log directly and captures every change regardless
  of how it was made.

**Possible drift between Postgres and OpenSearch if the Kafka publish step fails.**
The current flow is: commit to Postgres → then publish to Kafka. If the
publish step fails (network issue, process crash) after a successful commit,
Postgres and OpenSearch can drift out of sync, and nothing currently catches
or repairs this automatically. Failures are logged but not retried.
- *Production fix:* a periodic reconciliation job comparing Postgres and
  OpenSearch and re-syncing any drift, or moving to true CDC (see above),
  which doesn't have this gap by design.

**Single-broker replication factor in places assumes a healthy 3-node cluster.**
`KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3` requires all 3 brokers to be
healthy for some operations to succeed. This is intentional (chosen for
learning/practice with multi-broker coordination) but means the local dev
cluster is less resilient to a single broker being down than a production
cluster typically would be configured to handle gracefully.

---

## Recommendation Engine

**Content-based filtering only — no collaborative filtering.**
The ML recommender uses TF-IDF + cosine similarity based on genres and
descriptions (content-based filtering). It does not yet account for what
*similar users* liked (collaborative filtering), which would require
significantly more user interaction data than currently exists.
- *Future improvement:* once there's a meaningful number of users and
  reading-list interactions, consider a hybrid approach.

**Post-login notification "don't repeat the last book" logic is in-memory only.**
`last_shown_book_tracker` in `post_login_notification_consumer.py` is a
plain Python dictionary. It resets every time the consumer script restarts,
meaning a user could see a repeat recommendation right after a restart.
- *Future improvement:* persist this in a small table
  (e.g. `recommendation_history`) if it becomes a noticeable issue in
  practice. Low priority — the cost of an occasional repeat is minor.

**No real admin role/permission system.**
Admin endpoints (e.g. `POST /admin/books`, `DELETE /admin/{book_id}`)
currently only require a valid JWT — any logged-in user could technically
call them, not just an actual admin.
- *Production fix:* add a `role` or `is_admin` field to the `User` model and
  check it in a dependency before allowing access to admin routes.

---

## Search & Data

**Book cover images depend on an external free API with inconsistent data.**
Cover images are fetched live from the Open Library Covers API using ISBNs.
Some books have multiple editions with inconsistent ISBN data, and the API
itself has no uptime/reliability guarantee. Image loading is also currently
imperfect (slow/loading states not fully polished).
- *Future improvement:* migrate to dedicated object storage (e.g. Cloudinary,
  S3, Supabase Storage) for reliability, especially if any books outside
  real published titles are ever added (Open Library only covers real books).

**OpenSearch index only includes title, author, description, isbn.**
Genre-based search/filtering is not yet supported in OpenSearch, since
`book_genres` data isn't included in the indexed documents.
- *Future improvement:* enrich indexed documents with genre arrays if
  genre-based search becomes a requirement.

---

## Frontend / Flutter

**WebSocket connection authentication is minimal.**
The notification WebSocket connects using a `user_id` in the URL path,
decoded client-side from the JWT. This works for the current single-user
testing setup but should be hardened before any real multi-user deployment
(e.g. verifying server-side that the requesting connection's token actually
matches the `user_id` in the path).

**Like button on `BookDetailsScreen` does not yet sync to the backend.**
Tapping the heart icon currently only updates local UI state
(`_toggleLikeStatus`). It does not yet call the reading-list endpoint to
actually persist the "like" / add-to-`to_read` action server-side.
- *Status:* known gap, not yet wired up.

**Avatar selection feature deprioritized.**
Profile avatar selection (choosing from a preset grid of avatars) was
deprioritized in favor of core recommendation/search infrastructure. Profile
image upload exists in concept but avatar selection specifically was shelved.

---

## Email / Notifications

**Email recommendations are a scheduled job, not real-time.**
Unlike the post-login popup (Kafka-driven, real-time), email recommendations
are intentionally designed as a periodic scheduled job (e.g. via APScheduler)
since a daily/weekly digest doesn't need to be tied to a login event. This is
a deliberate architectural choice, not a limitation — documented here for
clarity on why two similar-sounding features use different patterns.

**No unsubscribe / notification preference controls yet.**
There is currently no way for a user to opt out of email recommendations or
control notification frequency/channels.
- *Future improvement:* add a notification preferences section to the user
  profile.

---

## Deployment

**Entire stack currently runs locally only.**
FastAPI, PostgreSQL, OpenSearch, Kafka, and all consumers currently run on
a local development machine. None of this has been deployed to a cloud
environment yet, which will be a separate body of work (containerizing
services, managing secrets in a production-safe way, choosing hosting for
each component, etc.).

---

*Last updated: reflects project state as of the Kafka/OpenSearch/notification
integration work session. Update this file as new limitations are identified
or existing ones are resolved.*