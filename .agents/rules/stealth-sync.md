## Stealth WordUp Database & Media Sync Invariant

This project runs an automated background ingestion pipeline to sync all 42,200 WordUp words and Zann media assets:

### Workflow Details
- **Workflow file**: `.github/workflows/stealth_database_sync.yml`
- **Schedule**: Runs automatically every 6 hours (`0 */6 * * *` at 00:00, 06:00, 12:00, 18:00 UTC) and via manual `workflow_dispatch`.
- **Source Database**: `my_wordup_v3.db` (contains 42,200 ranked words).
- **Scripts**:
  - `scripts/stealth_sync.py`: Fetches word JSONs via WordUp CDN, encrypts them (AES-256-CBC), stores in SQLite `word_data`, and exports `.enc` files to `api_words/`.
  - `scripts/image_sync.py`: Audits word data and scrapes Zann dictionary images, encrypting and uploading them to Hugging Face dataset `derfang/worddown-media`.

### Tracking & Checking Progress
- **Release tag**: `database-latest` on GitHub contains `wordup_database.db`.
- **API Branch**: `api` branch stores individual encrypted word files `words/{id}.enc`.
- **Hugging Face Media Repo**: `derfang/worddown-media` stores sharded encrypted `.webp.enc` images.
- **Detailed Progress Tracker**: See `docs/STEALTH_SYNC_TRACKING.md`.

Whenever checking sync progress or when the user asks about the WordUp API/media workflow status, refer to `docs/STEALTH_SYNC_TRACKING.md` and query the latest release, the `api` branch, or Hugging Face dataset `derfang/worddown-media`.
