import requests
import json
import os

# Your active authentication token
TOKEN = "058daa1c-96cf-4b55-b016-115dd35136e1"

# The specific List IDs extracted from your user_learning cache
# 0: Favorite, 1: IELTS, 2: TOEFL, 4: GRE, 572: Electrical Engineering, 573: Electronics
LIST_IDS = {
    "Favorite": 0,
    "IELTS": 1,
    "TOEFL": 2,
    "GRE": 4,
    "Electrical_Engineering": 572,
    "Electronics": 573,
    "1500_Essential_Words": 721,
    "Phrasal_Verbs": 722,
    "Idioms": 723
}

# Create a directory to save the JSON files
output_dir = "wordup_lists"
os.makedirs(output_dir, exist_ok=True)


def fetch_word_list(name, list_id):
    url = f"https://my.wrdp.app/learning/getWords/{list_id}?t={TOKEN}"

    try:
        response = requests.get(url)
        response.raise_for_status()  # Check for HTTP errors

        data = response.json()

        # Save the JSON data to a file
        filepath = os.path.join(output_dir, f"{name}_{list_id}.json")
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)

        print(
            f"Successfully saved {name} (ID: {list_id}) - {len(data)} items retrieved.")

    except requests.exceptions.RequestException as e:
        print(f"Failed to fetch {name} (ID: {list_id}): {e}")


# Loop through all your lists and download the data
print("Starting WordUp list extraction...")
for list_name, list_id in LIST_IDS.items():
    fetch_word_list(list_name, list_id)

print("\nExtraction complete. Check the 'wordup_lists' folder.")
