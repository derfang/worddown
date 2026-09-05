const express = require('express');
const cors = require('cors');
const zlib = require('zlib');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const app = express();
app.use(cors());

// Serve the HTML, CSS, and JS files from this directory
app.use(express.static(__dirname));

// Open database
const dbPath = path.resolve(__dirname, 'my_wordup_v3.db');
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
    if (err) {
        console.error('Failed to open database:', err.message);
    } else {
        console.log('Connected to the WordUp SQLite database.');
    }
});

// Endpoint to find Word ID by Text
app.get('/api/findWord/:word', (req, res) => {
    const wordQuery = req.params.word.trim();
    const sql = `SELECT wordId, text FROM words WHERE text = ? COLLATE NOCASE LIMIT 1`;
    
    db.get(sql, [wordQuery], (err, row) => {
        if (err) {
            console.error('Database query error:', err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        if (row) {
            res.json({ wordId: row.wordId, text: row.text });
        } else {
            res.status(404).json({ error: 'Word not found in database' });
        }
    });
});

app.get('/api/word/:id', async (req, res) => {
    const wordId = req.params.id;
    
    // In the future, you might want to dynamically fetch the token 't=' or remove it if not strictly checked
    const url = `https://cdn-wordup.com/Contents/v2025-10-23/${wordId}.gz?t=058daa1c-96cf-4b55-b016-115dd35136e1`;

    try {
        const response = await fetch(url, {
            headers: {
                'accept': '*/*',
                'origin': 'https://web.wordupapp.co',
                'referer': 'https://web.wordupapp.co/',
                'x-wordup-app-id': 'wordup_full',
                'x-wordup-source': 'web'
            }
        });

        if (!response.ok) {
            return res.status(response.status).json({ error: 'Failed to fetch from WordUp CDN' });
        }

        const buffer = await response.arrayBuffer();
        
        // Decompress GZIP payload
        zlib.gunzip(Buffer.from(buffer), (err, decompressed) => {
            if (err) {
                console.error('Decompression error:', err);
                return res.status(500).json({ error: 'Failed to decompress data' });
            }
            
            try {
                const jsonStr = decompressed.toString('utf-8');
                const data = JSON.parse(jsonStr);
                res.json(data);
            } catch (parseErr) {
                console.error('JSON Parse error:', parseErr);
                res.status(500).json({ error: 'Failed to parse JSON' });
            }
        });

    } catch (error) {
        console.error('Server error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`WordUp proxy server running on http://localhost:${PORT}`);
});
