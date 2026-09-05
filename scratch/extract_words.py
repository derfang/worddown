import json
import sqlite3

json_path = 'scratch/known_words_raw.network-response'
db_path = 'my_wordup_v3.db'

with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

categories = {
    'KnownWordIds': 'all_known_words.txt',
    'UnknownWordIds': 'unknown_words.txt',
    'ReviewWordIds': 'review_words.txt',
    'ToLearn': 'to_learn_words.txt'
}

conn = sqlite3.connect(db_path)
c = conn.cursor()

for key, output_path in categories.items():
    raw_ids = data['Learning'].get(key, [])
    print(f"\nProcessing {key} (Found {len(raw_ids)} items)...")
    
    words = []
    missing_ids = 0
    
    for item in raw_ids:
        # Some items like ReviewWordIds are strings like '28828:4' (WordId:Level)
        if isinstance(item, str) and ':' in item:
            word_id = int(item.split(':')[0])
        else:
            word_id = int(item)
            
        c.execute('SELECT text FROM words WHERE wordId = ?', (word_id,))
        row = c.fetchone()
        if row:
            words.append(row[0])
        else:
            missing_ids += 1
            
    # Sort and save
    words.sort()
    with open(output_path, 'w', encoding='utf-8') as f:
        for w in words:
            f.write(w + '\n')
            
    print(f" -> Saved {len(words)} English words to {output_path}")
    if missing_ids > 0:
        print(f" -> Warning: {missing_ids} IDs were not found in the DB.")

conn.close()
print("\nAll extractions complete!")
