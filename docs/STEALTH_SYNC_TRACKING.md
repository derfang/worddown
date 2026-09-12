# WordUp Database & Media Sync Tracking

This document tracks the ongoing background data ingestion pipeline, synchronizing the entire WordUp dictionary and associated Zann media to our decentralized repositories.

---

## 1. Overview & Architecture

- **GitHub Workflow File**: [`.github/workflows/stealth_database_sync.yml`](file:///c:/Users/PADIDAR/Desktop/task/worddown/.github/workflows/stealth_database_sync.yml)
- **Source Database**: `my_wordup_v3.db` (Contains 42,200 ranked words from rank #1 up to #34,004)
- **Cron Schedule**: Runs automatically every 6 hours (`0 */6 * * *` at 00:00, 06:00, 12:00, 18:00 UTC)
- **Manual Trigger**: Supports `workflow_dispatch` with custom `batch_size` (default: 500), `max_rank` (50,000), and randomized delays.

### Pipeline Stages per Run
1. **Database Restoration**: Downloads existing `wordup_database.db` from GitHub Release `database-latest`.
2. **Stealth Word Fetching ([`scripts/stealth_sync.py`](file:///c:/Users/PADIDAR/Desktop/task/worddown/scripts/stealth_sync.py))**:
   - Queries `my_wordup_v3.db` for the next un-synced batch of words by rank.
   - Downloads compressed word definitions from the WordUp CDN with polite, randomized delays (1.5s - 3.5s).
   - Encrypts JSON content with AES-256-CBC (`ENC_KEY` & `ENC_IV`).
   - Inserts records into SQLite table `word_data(id, word, rank, json_content, synced_at)`.
3. **Audit & Validation ([`scripts/image_sync.py --mode audit`](file:///c:/Users/PADIDAR/Desktop/task/worddown/scripts/image_sync.py))**:
   - Verifies integrity of all existing words and purges corrupted entries for re-queueing.
4. **Media Scrape & Backup ([`scripts/image_sync.py --mode scrape`](file:///c:/Users/PADIDAR/Desktop/task/worddown/scripts/image_sync.py))**:
   - Scrapes Zann dictionary CDN for images associated with newly ingested words.
   - Encrypts image bytes (`AES-256-CBC`) and stores them with sharded paths (`images/{sub1}/{sub2}/{hash}.webp.enc`).
   - Uploads new media batches directly to the Hugging Face dataset [`derfang/worddown-media`](https://huggingface.co/datasets/derfang/worddown-media).
   - Records mapping in SQLite tables `media_sync_status` and deduplication table `image_registry`.
5. **REST API Branch Deployment**:
   - Pushes individual encrypted word files (`words/{word_id}.enc`) to the orphan `api` branch of `derfang/worddown`.
6. **Release Publication**:
   - Re-packages and publishes updated `wordup_database.db` to GitHub Release `database-latest`.

---

## 2. Current Progress Snapshot

| Metric | Current Status (as of Sep 12, 2026) | Target Total | Progress (%) |
| :--- | :--- | :--- | :--- |
| **Total Synced Words** | **6,320** | 42,200 | **15.0%** |
| **Encrypted API Branch Files** | **5,320** files (`api` branch: `words/*.enc`) | 42,200 | **15.0%** |
| **Hugging Face Media Files** | **19,663** encrypted `.webp.enc` images | ~100,000+ | ~**20%** |
| **Release Database Size** | **88.56 MB** (`wordup_database.db`) | ~350 MB | — |
| **Active Run in Progress** | Run `34697636295` (triggered 13:52 UTC) | +500 words | In Progress |

---

## 3. How to Check Progress Remotely

When `gh` CLI is unavailable or rate-limited on the local machine:

1. **Check Latest API Branch Commit**:
   ```powershell
   git ls-remote origin refs/heads/api
   ```
   Look at the commit message: e.g., `Sync 5320 encrypted words to API branch [skip ci]`.

2. **Check Latest Release via GitHub API**:
   Query `https://api.github.com/repos/derfang/worddown/releases/tags/database-latest` to read the updated word count and database size.

3. **Check Hugging Face Media Count**:
   Query `https://huggingface.co/api/datasets/derfang/worddown-media` to view `siblings` count (number of encrypted media files).
