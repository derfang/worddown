import json

with open('firebase.json', 'r') as f:
    data = json.load(f)

data['firestore'] = {
    "rules": "firestore.rules"
}

with open('firebase.json', 'w') as f:
    json.dump(data, f, indent=2)
