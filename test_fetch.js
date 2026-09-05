const fs = require('fs');
const zlib = require('zlib');

async function testFetch() {
    try {
        const response = await fetch('https://cdn-wordup.com/Contents/v2025-10-23/6432.gz?t=058daa1c-96cf-4b55-b016-115dd35136e1', {
            headers: {
                'accept': '*/*',
                'origin': 'https://web.wordupapp.co',
                'referer': 'https://web.wordupapp.co/',
                'x-wordup-app-id': 'wordup_full',
                'x-wordup-source': 'web'
            }
        });
        
        if (!response.ok) {
            console.error('Failed to fetch:', response.status, response.statusText);
            return;
        }

        const buffer = await response.arrayBuffer();
        
        // Decompress the gz
        zlib.gunzip(Buffer.from(buffer), (err, decompressed) => {
            if (err) {
                console.error('Decompression error:', err);
                return;
            }
            
            const jsonStr = decompressed.toString('utf-8');
            console.log('Successfully decompressed! Preview:');
            console.log(jsonStr.substring(0, 500));
            fs.writeFileSync('sample_6432.json', jsonStr);
        });
        
    } catch (error) {
        console.error('Error:', error);
    }
}

testFetch();
