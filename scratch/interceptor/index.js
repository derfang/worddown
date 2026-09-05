const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
  console.log('Starting Puppeteer... Please wait a moment.');
  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();

  console.log('Browser launched! Please log in to WordUp.');
  console.log('Listening for network traffic...');

  page.on('response', async (response) => {
    try {
      if (response.status() === 200) {
        const contentType = response.headers()['content-type'] || '';
        if (contentType.includes('application/json') || response.url().includes('json')) {
          let text = await response.text();
          if (text) {
            let data;
            try {
              data = JSON.parse(text);
              // Handle potential double-stringified payload
              if (typeof data === 'string') {
                data = JSON.parse(data);
              }
            } catch (e) {
              return; // Not valid JSON
            }

            // We are looking for a flat JSON list containing more than 1000 integers/strings,
            // or an object that contains such a list.
            const bodyStr = JSON.stringify(data);
            if (bodyStr.length > 5000) { // Look for large payloads (> 5KB)
              console.log(`Captured large JSON payload from: ${response.url()}`);
              
              // We'll dump all large JSON responses to ensure we don't miss it.
              // We will append it as a JSON line.
              const logEntry = { url: response.url(), data: data };
              fs.appendFileSync(
                path.join(__dirname, 'wordup_network_dump.jsonl'), 
                JSON.stringify(logEntry) + '\n', 
                'utf-8'
              );
              console.log('--> Saved payload to wordup_network_dump.jsonl');
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors (e.g. response body already consumed, or navigation happened)
    }
  });

  await page.goto('https://web.wordupapp.co/');

  console.log('\n======================================================');
  console.log('The browser is now open. Go ahead and log in.');
  console.log('Keep this running until your Known Words are loaded.');
  console.log('Close the browser window when you are completely finished.');
  console.log('======================================================\n');
})();
