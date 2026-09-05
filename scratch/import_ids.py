import json
import os

json_path = 'scratch/known_words_raw.network-response'
known_output = 'local_known_words.json'
to_learn_output = 'local_to_learn.json'

with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

known_ids = data['Learning'].get('KnownWordIds', [])
to_learn_ids = data['Learning'].get('ToLearn', [])

# local_known_words.json needs to be just a JSON array of integers
with open(known_output, 'w', encoding='utf-8') as f:
    json.dump(known_ids, f)

with open(to_learn_output, 'w', encoding='utf-8') as f:
    json.dump(to_learn_ids, f)

print(f"Successfully imported {len(known_ids)} known words to {known_output}")
print(f"Successfully imported {len(to_learn_ids)} to-learn words to {to_learn_output}")
