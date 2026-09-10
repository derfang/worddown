import argparse
import base64
import gzip
import json
import os
import random
import sqlite3
import sys
import time
import urllib.request
import urllib.error

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding

CDN_BASE_URL = 'https://cdn-wordup.com/Contents/v2025-10-23/'
DEFAULT_TOKEN = '058daa1c-96cf-4b55-b016-115dd35136e1'

DEFAULT_ENC_KEY = 'ma8lnJ2ZWz4+XvZ6UWkSZSeQGkv8fS0/XihcFPocysI='
DEFAULT_ENC_IV = '89DZIiGBL8zWSjDvUdfimQ=='

def encrypt_content(content_str: str, key_b64: str = DEFAULT_ENC_KEY, iv_b64: str = DEFAULT_ENC_IV) -> bytes:
    key = base64.b64decode(key_b64)
    iv = base64.b64decode(iv_b64)
    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(content_str.encode('utf-8')) + padder.finalize()
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    encryptor = cipher.encryptor()
    return encryptor.update(padded_data) + encryptor.finalize()

HEADERS = {
    'Accept': '*/*',
    'Origin': 'https://web.wordupapp.co',
    'Referer': 'https://web.wordupapp.co/',
    'x-wordup-app-id': 'wordup_full',
    'x-wordup-source': 'web',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
}

def init_target_db(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS word_data (
            id INTEGER PRIMARY KEY,
            word TEXT,
            rank INTEGER,
            json_content TEXT,
            synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_word_rank ON word_data(rank)')
    cursor.execute('CREATE INDEX IF NOT EXISTS idx_word_text ON word_data(word)')
    conn.commit()
    return conn

def get_synced_ids(conn: sqlite3.Connection) -> set:
    cursor = conn.cursor()
    cursor.execute('SELECT id FROM word_data')
    return {row[0] for row in cursor.fetchall()}

def get_pending_words(source_db_path: str, synced_ids: set, max_rank: int, batch_size: int):
    if not os.path.exists(source_db_path):
        raise FileNotFoundError(f'Source database not found: {source_db_path}')
    
    conn = sqlite3.connect(source_db_path)
    cursor = conn.cursor()
    cursor.execute('''
        SELECT wordId, rank, text 
        FROM words 
        WHERE rank > 0 AND rank <= ? 
        ORDER BY rank ASC
    ''', (max_rank,))
    
    pending = []
    for row in cursor.fetchall():
        word_id, rank, text = row
        if word_id not in synced_ids:
            pending.append({'id': word_id, 'rank': rank, 'text': text})
            if len(pending) >= batch_size:
                break
    conn.close()
    return pending

def fetch_word_content(word_id: int, token: str) -> str:
    url = f'{CDN_BASE_URL}{word_id}.gz?t={token}'
    req = urllib.request.Request(url, headers=HEADERS, method='GET')
    
    with urllib.request.urlopen(req, timeout=12) as response:
        if response.status != 200:
            raise ValueError(f'HTTP {response.status}')
        raw_bytes = response.read()
        try:
            decompressed = gzip.decompress(raw_bytes)
            return decompressed.decode('utf-8')
        except Exception:
            return raw_bytes.decode('utf-8')

def main():
    parser = argparse.ArgumentParser(description='Stealth WordUp Database Sync')
    parser.add_argument('--batch-size', type=int, default=150, help='Number of words to fetch in this run')
    parser.add_argument('--min-delay', type=float, default=1.5, help='Minimum delay between requests (seconds)')
    parser.add_argument('--max-delay', type=float, default=3.5, help='Maximum delay between requests (seconds)')
    parser.add_argument('--max-rank', type=int, default=50000, help='Max word frequency rank to include (covers all 42k+ words/idioms)')
    parser.add_argument('--source-db', type=str, default='my_wordup_v3.db', help='Path to my_wordup_v3.db')
    parser.add_argument('--target-db', type=str, default='wordup_database.db', help='Path to target wordup_database.db')
    parser.add_argument('--api-dir', type=str, default='api_words', help='Directory to store encrypted word files for REST API branch')
    parser.add_argument('--enc-key', type=str, default=DEFAULT_ENC_KEY, help='Base64 AES encryption key')
    parser.add_argument('--enc-iv', type=str, default=DEFAULT_ENC_IV, help='Base64 AES encryption IV')
    parser.add_argument('--token', type=str, default=DEFAULT_TOKEN, help='CDN access token')
    args = parser.parse_args()

    print('=== Starting Stealth WordUp Sync ===')
    print(f'Target DB: {args.target_db}')
    print(f'API Directory: {args.api_dir}')
    print(f'Batch Size: {args.batch_size} words | Max Rank: #{args.max_rank}')
    print(f'Delay range: {args.min_delay}s - {args.max_delay}s')

    target_conn = init_target_db(args.target_db)
    cursor = target_conn.cursor()

    # If api_dir is specified, make sure all existing DB entries are also exported to encrypted .enc files
    if args.api_dir:
        os.makedirs(args.api_dir, exist_ok=True)
        cursor.execute('SELECT id, json_content FROM word_data')
        existing_rows = cursor.fetchall()
        exported_count = 0
        for w_id, w_content in existing_rows:
            target_path = os.path.join(args.api_dir, f'{w_id}.enc')
            if not os.path.exists(target_path):
                enc_data = encrypt_content(w_content, key_b64=args.enc_key, iv_b64=args.enc_iv)
                with open(target_path, 'wb') as f:
                    f.write(enc_data)
                exported_count += 1
        if exported_count > 0:
            print(f'Exported {exported_count} existing words from DB to encrypted API files in {args.api_dir}/')

    synced_ids = get_synced_ids(target_conn)
    print(f'Currently synced words in database: {len(synced_ids)}')

    pending = get_pending_words(args.source_db, synced_ids, args.max_rank, args.batch_size)
    if not pending:
        print(f'All words up to rank #{args.max_rank} are already synced!')
        target_conn.close()
        return

    print(f'Queued {len(pending)} words for this batch.')
    success_count = 0

    for idx, item in enumerate(pending, 1):
        word_id = item['id']
        rank = item['rank']
        text = item['text']

        try:
            content = fetch_word_content(word_id, args.token)
            cursor.execute('''
                INSERT OR REPLACE INTO word_data (id, word, rank, json_content)
                VALUES (?, ?, ?, ?)
            ''', (word_id, text, rank, content))
            target_conn.commit()

            # Encrypt and save to api_dir
            if args.api_dir:
                enc_bytes = encrypt_content(content, key_b64=args.enc_key, iv_b64=args.enc_iv)
                enc_path = os.path.join(args.api_dir, f'{word_id}.enc')
                with open(enc_path, 'wb') as f:
                    f.write(enc_bytes)

            success_count += 1
            print(f'[{idx}/{len(pending)}] OK: #{rank} "{text}" (id: {word_id}) - {len(content)} chars')
        except urllib.error.HTTPError as e:
            print(f'[{idx}/{len(pending)}] HTTP Error {e.code} for #{rank} "{text}".')
            if e.code in (403, 429, 503):
                print(f'Rate limit / anti-bot detected ({e.code}). Pausing safely and aborting run.')
                break
        except Exception as e:
            print(f'[{idx}/{len(pending)}] Error fetching #{rank} "{text}": {e}')

        # Human-like randomized delay before next word
        if idx < len(pending):
            delay = random.uniform(args.min_delay, args.max_delay)
            time.sleep(delay)

    target_conn.close()
    print(f'=== Batch complete! Successfully synced {success_count}/{len(pending)} words. Total in DB: {len(synced_ids) + success_count} ===')

if __name__ == '__main__':
    main()
