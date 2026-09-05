from playwright.sync_api import sync_playwright
import json
import os

def run(playwright):
    print("Launching Chromium browser... Please wait.")
    # Launch a visible browser
    browser = playwright.chromium.launch(headless=False)
    context = browser.new_context()
    page = context.new_page()

    # Create/clear the dump file
    dump_file = "wordup_bulk_known.jsonl"
    with open(dump_file, "w", encoding="utf-8") as f:
        pass 

    def handle_response(response):
        try:
            # We only care about successful JSON responses
            if response.status == 200 and ("application/json" in response.headers.get("content-type", "") or "json" in response.url):
                body = response.body()
                if body:
                    try:
                        data = json.loads(body.decode('utf-8'))
                    except:
                        return
                    
                    # WordUp sometimes double-stringifies its JSON payloads
                    if isinstance(data, str):
                        try:
                            data = json.loads(data)
                        except:
                            pass
                    
                    # Dump large payloads (greater than 5000 characters)
                    body_str = json.dumps(data)
                    if len(body_str) > 5000:
                        print(f"--> Captured large JSON from {response.url}")
                        with open(dump_file, "a", encoding="utf-8") as f:
                            f.write(json.dumps({"url": response.url, "data": data}) + "\n")
                        print(f"--> Saved to {dump_file}")
        except Exception as e:
            pass # Ignore read errors for media/closed connections

    # Attach our interceptor
    page.on("response", handle_response)

    print("\n======================================================")
    print("Browser launched! Please go ahead and log in.")
    print("This script will automatically dump large data into wordup_bulk_known.jsonl")
    print("Keep this script running until your Known Words are loaded.")
    print("Close the browser window when you are completely finished.")
    print("======================================================\n")
    
    # Go to WordUp
    page.goto("https://web.wordupapp.co/")
    
    # Pause keeps the session alive so you can interact
    page.pause()
    
    browser.close()

with sync_playwright() as playwright:
    run(playwright)
