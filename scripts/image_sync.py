#!/usr/bin/env python3
"""
image_sync.py — Zann Image Scraper + Hugging Face Uploader

Modes:
  audit   — Validate all existing word_data entries; delete corrupt ones so they
             are re-queued by stealth_sync.py on the next run.
  scrape  — For the next `batch_size` words that have word_data but no
             media_sync_status entry, scrape Zann for images, encrypt them
             (AES-256-CBC using the same ENC_KEY / ENC_IV as the word files),
             and push them to a Hugging Face dataset in sharded folders.
"""

import argparse
import base64
import json
import os
import re
import shutil
import sqlite3
import sys
import time
import random
import urllib.request
import urllib.error
from pathlib import Path

try:
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    from cryptography.hazmat.primitives import padding as sym_padding
except ImportError:
    sys.exit("ERROR: Install cryptography → pip install cryptography")

try:
    from huggingface_hub import HfApi
except ImportError:
    sys.exit("ERROR: Install huggingface_hub → pip install huggingface_hub")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/128.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}

ZANN_BASE = "https://www.zann.app/dictionary/"


def _load_key_iv(enc_key_b64: str, enc_iv_b64: str):
    return base64.b64decode(enc_key_b64), base64.b64decode(enc_iv_b64)


def encrypt_bytes(raw: bytes, key: bytes, iv: bytes) -> bytes:
    padder = sym_padding.PKCS7(128).padder()
    padded = padder.update(raw) + padder.finalize()
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    enc = cipher.encryptor()
    return enc.update(padded) + enc.finalize()


def decrypt_bytes(enc: bytes, key: bytes, iv: bytes) -> bytes:
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    dec = cipher.decryptor()
    padded = dec.update(enc) + dec.finalize()
    unpadder = sym_padding.PKCS7(128).unpadder()
    return unpadder.update(padded) + unpadder.finalize()


def compute_hf_path(original_url: str) -> str:
    """
    Map a CDN URL to a sharded Hugging Face path.
    e.g. https://word-images.cdn-wordup.com/sensesMobile/d70a7242-f5a5.webp
         → images/d7/0a/d70a7242-f5a5.webp.enc
    """
    filename = original_url.split("/")[-1]        # e.g. "d70a7242-f5a5.webp"
    p1 = filename[:2].lower()                     # "d7"
    p2 = filename[2:4].lower()                    # "0a"
    return f"images/{p1}/{p2}/{filename}.enc"


def fetch_url_bytes(url: str, timeout: int = 10) -> bytes:
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

def validate_word_json(word_id: int, expected_word: str, raw_json: str) -> bool:
    """
    Returns True only when the JSON payload is structurally sound.
    All checks are strict: any failure means the record should be purged.
    """
    try:
        data = json.loads(raw_json)
    except Exception:
        print(f"  [VALIDATE] {word_id}: JSON parse error")
        return False

    if not isinstance(data, dict) or not data:
        print(f"  [VALIDATE] {word_id}: empty or non-dict payload")
        return False

    if "error" in data:
        print(f"  [VALIDATE] {word_id}: error key in payload: {data['error']}")
        return False

    senses = data.get("Senses") or data.get("senses") or []
    if not isinstance(senses, list) or len(senses) == 0:
        print(f"  [VALIDATE] {word_id}: no senses")
        return False

    first = senses[0]
    if not isinstance(first, dict):
        print(f"  [VALIDATE] {word_id}: first sense is not a dict")
        return False
    if not first.get("id") or not first.get("de"):
        print(f"  [VALIDATE] {word_id}: first sense missing id/de")
        return False

    return True


# ---------------------------------------------------------------------------
# Image URL extraction
# ---------------------------------------------------------------------------

def extract_image_urls(word_json: str, zann_data: dict) -> list[dict]:
    """
    Returns a list of dicts describing every image associated with this word.
    Each dict: { "original_url": str, "section": str, "sense_id": str|None }

    section is one of: "word", "sense", "tip", "quote"
    """
    results = []
    seen = set()

    def add(url, section, sense_id=None):
        if url and isinstance(url, str) and url.startswith("http") and url not in seen:
            seen.add(url)
            results.append({"original_url": url, "section": section, "sense_id": sense_id})

    # 1. Main word image (ZannWordImage from zann)
    add(zann_data.get("ZannWordImage"), "word")

    # 2. Senses from Zann (per-sense images and their tips)
    for s in zann_data.get("ZannSenses", []):
        sid = s.get("id")
        add(s.get("ImageSrc"), "sense", sid)
        for tip in s.get("Tips", []):
            add(tip.get("imageUrl"), "tip", sid)

    # 3. Quote images (ZannQuotes)
    for q in zann_data.get("ZannQuotes", []):
        add(q.get("ImageSrc"), "quote")

    return results


# ---------------------------------------------------------------------------
# Zann scraper
# ---------------------------------------------------------------------------

NEXT_DATA_RE = re.compile(
    r'<script id="__NEXT_DATA__" type="application/json"[^>]*>([\s\S]*?)</script>'
)


def scrape_zann(word_text: str) -> dict:
    """
    Returns a dict with keys: ZannWordImage, ZannSenses, ZannQuotes.
    Returns empty dict on any failure.
    """
    slug = word_text.lower().replace(" ", "-")
    url = f"{ZANN_BASE}{slug}"
    try:
        html = fetch_url_bytes(url, timeout=12).decode("utf-8", errors="replace")
        m = NEXT_DATA_RE.search(html)
        if not m:
            return {}
        next_data = json.loads(m.group(1))
        props = next_data.get("props", {}).get("pageProps", {})
        result = {}
        if props.get("senses"):
            result["ZannSenses"] = props["senses"]
            # The first sense's ImageSrc becomes the word-level image
            first_img = props["senses"][0].get("ImageSrc")
            if first_img:
                result["ZannWordImage"] = first_img
        if props.get("quotes"):
            result["ZannQuotes"] = props["quotes"]
        return result
    except Exception as e:
        print(f"  [ZANN] scrape failed for '{word_text}': {e}")
        return {}


# ---------------------------------------------------------------------------
# AUDIT MODE
# ---------------------------------------------------------------------------

def run_audit(db_path: str, api_dir: str, enc_key: bytes, enc_iv: bytes):
    print("\n=== AUDIT MODE: Validating existing synced words ===")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("SELECT id, word, json_content FROM word_data")
    rows = cursor.fetchall()
    print(f"Total existing word_data rows: {len(rows)}")

    corrupt = []
    for word_id, word, json_content in rows:
        if not validate_word_json(word_id, word, json_content):
            corrupt.append((word_id, word))

    if not corrupt:
        print(f"All {len(rows)} words passed validation. ✅")
        conn.close()
        return

    print(f"\n⚠️  {len(corrupt)} corrupt entries found. Purging...")
    for word_id, word in corrupt:
        # Remove from SQLite
        cursor.execute("DELETE FROM word_data WHERE id = ?", (word_id,))
        cursor.execute("DELETE FROM media_sync_status WHERE word_id = ?", (word_id,))

        # Remove the encrypted file from api_dir so it's not pushed to api branch
        enc_file = os.path.join(api_dir, f"{word_id}.enc")
        if os.path.exists(enc_file):
            os.remove(enc_file)
            print(f"  Deleted: {enc_file}")

        print(f"  Purged DB entry for word_id={word_id} ('{word}'). Will be re-synced next run.")

    conn.commit()
    conn.close()
    print(f"\nAudit complete: {len(corrupt)} entries purged, {len(rows) - len(corrupt)} healthy.")


# ---------------------------------------------------------------------------
# SCRAPE MODE
# ---------------------------------------------------------------------------

def run_scrape(
    db_path: str,
    hf_repo: str,
    hf_token: str,
    image_output_dir: str,
    batch_size: int,
    enc_key: bytes,
    enc_iv: bytes,
    min_delay: float,
    max_delay: float,
):
    print(f"\n=== SCRAPE MODE: batch_size={batch_size} ===")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Load already-known image registry (for deduplication)
    cursor.execute("SELECT original_url, hf_path FROM image_registry")
    image_registry = {row[0]: row[1] for row in cursor.fetchall()}
    print(f"Image registry: {len(image_registry)} known images (dedup cache)")

    # Select next batch of words that need images
    cursor.execute("""
        SELECT id, word, json_content
        FROM word_data
        WHERE id NOT IN (SELECT word_id FROM media_sync_status)
        ORDER BY rank ASC
        LIMIT ?
    """, (batch_size,))
    words_to_process = cursor.fetchall()

    if not words_to_process:
        print("All synced words already have images backed up. Nothing to do. ✅")
        conn.close()
        return

    print(f"Words to process this run: {len(words_to_process)}")

    # Prepare staging directory
    staging_dir = Path(image_output_dir)
    if staging_dir.exists():
        shutil.rmtree(staging_dir)
    staging_dir.mkdir(parents=True)

    new_images_staged = {}   # hf_path → local file path
    words_done = []          # (word_id, hf_paths_for_this_word)

    for idx, (word_id, word_text, json_content) in enumerate(words_to_process, 1):
        print(f"\n[{idx}/{len(words_to_process)}] Processing word_id={word_id} '{word_text}'")

        # Step 1: Validate the stored JSON before we even try to scrape
        if not validate_word_json(word_id, word_text, json_content):
            print(f"  Skipping corrupt stored data for {word_id} — will be purged by next audit run.")
            continue

        # Step 2: Scrape Zann for image URLs
        zann_data = scrape_zann(word_text)
        if not zann_data:
            print(f"  No Zann data found for '{word_text}'. Marking as processed with 0 images.")
            words_done.append((word_id, []))
            continue

        image_entries = extract_image_urls(json_content, zann_data)
        print(f"  Found {len(image_entries)} unique images on Zann")

        word_hf_paths = []

        # Step 3: Download, encrypt, stage each image
        for entry in image_entries:
            original_url = entry["original_url"]
            hf_path = compute_hf_path(original_url)

            # Deduplication check
            if original_url in image_registry:
                known_path = image_registry[original_url]
                word_hf_paths.append({"hf_path": known_path, **entry})
                print(f"  DEDUP: {original_url.split('/')[-1]} already uploaded → {known_path}")
                continue

            try:
                raw_bytes = fetch_url_bytes(original_url, timeout=10)
                enc_bytes = encrypt_bytes(raw_bytes, enc_key, enc_iv)

                # Write to sharded staging folder
                local_path = staging_dir / hf_path
                local_path.parent.mkdir(parents=True, exist_ok=True)
                local_path.write_bytes(enc_bytes)

                new_images_staged[hf_path] = str(local_path)
                image_registry[original_url] = hf_path
                word_hf_paths.append({"hf_path": hf_path, **entry})
                print(f"  ✅ Encrypted: {original_url.split('/')[-1]} ({len(raw_bytes)//1024}KB raw → {len(enc_bytes)//1024}KB enc)")
            except Exception as e:
                print(f"  ❌ Failed to download {original_url}: {e}")
                continue

        words_done.append((word_id, word_hf_paths))

        # Polite delay between Zann scrapes
        if idx < len(words_to_process):
            delay = random.uniform(min_delay, max_delay)
            time.sleep(delay)

    # Step 4: Push all new images to Hugging Face in one batch commit
    if new_images_staged:
        print(f"\n📤 Uploading {len(new_images_staged)} new images to Hugging Face ({hf_repo})...")
        try:
            api = HfApi(token=hf_token)
            api.upload_folder(
                folder_path=str(staging_dir),
                repo_id=hf_repo,
                repo_type="dataset",
                commit_message=(
                    f"Add {len(new_images_staged)} encrypted images "
                    f"for {len(words_done)} words [auto-sync]"
                ),
            )
            print(f"✅ Upload complete: {len(new_images_staged)} images pushed to {hf_repo}")
        except Exception as e:
            print(f"❌ Hugging Face upload failed: {e}")
            conn.close()
            sys.exit(1)
    else:
        print("\n📤 No new images to upload (all were deduplicated or skipped).")

    # Step 5: Record results in SQLite
    print("\n💾 Recording results in SQLite...")
    for word_id, hf_paths_list in words_done:
        cursor.execute("""
            INSERT OR REPLACE INTO media_sync_status (word_id, images_count, hf_paths)
            VALUES (?, ?, ?)
        """, (word_id, len(hf_paths_list), json.dumps(hf_paths_list)))

    # Register newly uploaded images in dedup registry
    for orig_url, hf_path in image_registry.items():
        cursor.execute("""
            INSERT OR IGNORE INTO image_registry (original_url, hf_path)
            VALUES (?, ?)
        """, (orig_url, hf_path))

    conn.commit()
    conn.close()

    total_synced = len(words_done)
    total_images = sum(len(p) for _, p in words_done)
    print(f"\n=== Scrape complete: {total_synced} words processed, {total_images} images mapped, {len(new_images_staged)} new uploads ===")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Zann Image Scraper + Hugging Face Uploader")
    parser.add_argument("--mode", choices=["audit", "scrape"], required=True)
    parser.add_argument("--target-db", default="wordup_database.db")
    parser.add_argument("--api-dir", default="api_words")
    parser.add_argument("--hf-repo", default="derfang/worddown-media")
    parser.add_argument("--hf-token", default=os.environ.get("HF_TOKEN", ""))
    parser.add_argument("--image-output-dir", default="hf_images")
    parser.add_argument("--batch-size", type=int, default=500)
    parser.add_argument("--min-delay", type=float, default=1.0)
    parser.add_argument("--max-delay", type=float, default=2.0)
    args = parser.parse_args()

    enc_key_b64 = os.environ.get("ENC_KEY", "")
    enc_iv_b64 = os.environ.get("ENC_IV", "")
    if not enc_key_b64 or not enc_iv_b64:
        sys.exit("ERROR: ENC_KEY and ENC_IV environment variables must be set.")

    enc_key, enc_iv = _load_key_iv(enc_key_b64, enc_iv_b64)

    if args.mode == "audit":
        run_audit(args.target_db, args.api_dir, enc_key, enc_iv)
    elif args.mode == "scrape":
        if not args.hf_token:
            sys.exit("ERROR: HF_TOKEN environment variable or --hf-token must be set for scrape mode.")
        run_scrape(
            db_path=args.target_db,
            hf_repo=args.hf_repo,
            hf_token=args.hf_token,
            image_output_dir=args.image_output_dir,
            batch_size=args.batch_size,
            enc_key=enc_key,
            enc_iv=enc_iv,
            min_delay=args.min_delay,
            max_delay=args.max_delay,
        )


if __name__ == "__main__":
    main()
