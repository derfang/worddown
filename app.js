document.addEventListener('DOMContentLoaded', () => {
    const searchBtn = document.getElementById('searchBtn');
    const searchInput = document.getElementById('searchInput');
    const wordView = document.getElementById('wordView');
    const template = document.getElementById('wordTemplate');

    // Change placeholder to encourage entering an ID
    searchInput.placeholder = "Enter Word ID (e.g., 6432)...";
    searchInput.value = "6432";

    // Initial render
    setTimeout(() => {
        fetchAndRenderWord('6432');
    }, 300);

    // List Navigation State
    let currentListIds = [];
    let currentIndex = 0;

    const curriculumList = document.getElementById('curriculumList');
    const listNav = document.getElementById('listNav');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    const wordProgress = document.getElementById('wordProgress');

    // Search event
    searchBtn.addEventListener('click', async () => {
        const query = searchInput.value.trim();
        if (!query) return;

        // Check if query is just numbers (an ID) or a word
        const isId = /^\d+$/.test(query);

        if (isId) {
            wordView.innerHTML = `
                <div class="loading-state">
                    <div class="spinner"></div>
                    <p>Fetching Word ID ${query} from WordUp API...</p>
                </div>
            `;
            fetchAndRenderWord(query);
        } else {
            // It's a word, look it up in the SQLite DB first
            wordView.innerHTML = `
                <div class="loading-state">
                    <div class="spinner"></div>
                    <p>Looking up "${query}" in database...</p>
                </div>
            `;
            
            try {
                const res = await fetch(`http://localhost:3000/api/findWord/${query}`);
                if (!res.ok) {
                    if (res.status === 404) {
                        wordView.innerHTML = `<div class="loading-state"><p>Word "${query}" not found in database.</p></div>`;
                    } else {
                        wordView.innerHTML = `<div class="loading-state"><p>Database error occurred.</p></div>`;
                    }
                    return;
                }
                const data = await res.json();
                
                wordView.innerHTML = `
                    <div class="loading-state">
                        <div class="spinner"></div>
                        <p>Found "${data.text}" (ID: ${data.wordId}). Fetching from API...</p>
                    </div>
                `;
                fetchAndRenderWord(data.wordId);
            } catch (err) {
                console.error("Lookup error:", err);
                wordView.innerHTML = `<div class="loading-state"><p>Error connecting to server for lookup.</p></div>`;
            }
        }
    });

    searchInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') searchBtn.click();
    });

    // Handle List Selection
    curriculumList.addEventListener('change', async (e) => {
        const listName = e.target.value;
        if (!listName) {
            listNav.style.display = 'none';
            return;
        }

        try {
            wordView.innerHTML = `
                <div class="loading-state">
                    <div class="spinner"></div>
                    <p>Loading ${listName} list...</p>
                </div>
            `;
            
            // Assuming the frontend serves the static files from /wordup_static_lists/
            const res = await fetch(`/wordup_static_lists/${listName}.json`);
            if (!res.ok) throw new Error('Failed to load list');
            const data = await res.json();
            
            // "uw" contains comma-separated IDs
            currentListIds = data.uw.split(',').filter(id => id.trim() !== '');
            currentIndex = 0;
            
            if (currentListIds.length > 0) {
                listNav.style.display = 'flex';
                loadCurrentWord();
            } else {
                listNav.style.display = 'none';
                wordView.innerHTML = `<div class="loading-state"><p>List is empty.</p></div>`;
            }
        } catch (err) {
            console.error('Error loading list:', err);
            wordView.innerHTML = `<div class="loading-state"><p>Failed to load list.</p></div>`;
        }
    });

    function loadCurrentWord() {
        if (currentListIds.length === 0) return;
        const wordId = currentListIds[currentIndex];
        
        // Update progress
        wordProgress.textContent = `Word ${currentIndex + 1} of ${currentListIds.length}`;
        
        // Update search input to match
        searchInput.value = wordId;
        
        // Update button states
        prevBtn.disabled = currentIndex === 0;
        prevBtn.style.opacity = currentIndex === 0 ? '0.5' : '1';
        prevBtn.style.cursor = currentIndex === 0 ? 'not-allowed' : 'pointer';
        
        nextBtn.disabled = currentIndex === currentListIds.length - 1;
        nextBtn.style.opacity = currentIndex === currentListIds.length - 1 ? '0.5' : '1';
        nextBtn.style.cursor = currentIndex === currentListIds.length - 1 ? 'not-allowed' : 'pointer';

        // Fetch
        wordView.innerHTML = `
            <div class="loading-state">
                <div class="spinner"></div>
                <p>Fetching Word ID ${wordId} from WordUp API...</p>
            </div>
        `;
        fetchAndRenderWord(wordId);
    }

    prevBtn.addEventListener('click', () => {
        if (currentIndex > 0) {
            currentIndex--;
            loadCurrentWord();
        }
    });

    nextBtn.addEventListener('click', () => {
        if (currentIndex < currentListIds.length - 1) {
            currentIndex++;
            loadCurrentWord();
        }
    });

    async function fetchAndRenderWord(wordId) {
        try {
            const res = await fetch(`http://localhost:3000/api/word/${wordId}`);
            if (!res.ok) throw new Error('API Request Failed');
            
            const data = await res.json();
            renderRealData(wordId, data);
        } catch (err) {
            console.error(err);
            wordView.innerHTML = `
                <div class="glass-panel" style="text-align: center; color: var(--text-muted);">
                    <i class="fa-solid fa-circle-exclamation" style="font-size: 3rem; margin-bottom: 1rem; color: #ef4444;"></i>
                    <h2>Failed to load word data</h2>
                    <p>Make sure the Node.js backend is running on port 3000.</p>
                </div>
            `;
        }
    }

    function renderRealData(wordId, data) {
        // Clone template
        const clone = template.content.cloneNode(true);

        // WordUp stores Senses and Quotes. We don't have the actual text of the word in the gz payload directly, 
        // so we'll just display the ID, or infer from usage if possible. But wait, compounds might have it. 
        // Let's just use the search input value or look at Quotes.
        // For audio, we can try the standard media path.
        
        // Let's find the word text from Senses' examples or compounds if possible, or just default to ID.
        // Actually, Senses[0].ex usually contains the word.
        const wordText = "Word ID: " + wordId;

        clone.querySelector('.word-title').textContent = wordText;
        clone.querySelector('.phonetic').textContent = ""; 
        
        // Extract Part of Speech from first sense
        let pos = "";
        if (data.Senses && data.Senses.length > 0) {
            pos = data.Senses.map(s => s.ty).filter((v,i,a) => a.indexOf(v)===i).join(', ');
        }
        clone.querySelector('.part-of-speech').textContent = pos;
        clone.querySelector('.translation-text').textContent = "Real data fetched successfully!";

        // Setup audio (guessing path)
        const playBtn = clone.querySelector('.play-btn');
        playBtn.addEventListener('click', () => {
            playBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
            const audioUrl = `https://cdn-wordup.com/media/audio/uk/${wordId}.mp3`;
            const audio = new Audio(audioUrl);
            audio.play().then(() => {
                playBtn.innerHTML = '<i class="fa-solid fa-volume-high"></i>';
                playBtn.style.boxShadow = '0 0 20px var(--primary)';
                setTimeout(() => { playBtn.style.boxShadow = 'none'; }, 1000);
            }).catch(e => {
                console.error("Audio play error", e);
                playBtn.innerHTML = '<i class="fa-solid fa-volume-xmark"></i>';
            });
        });

        // Populate definitions
        const defsList = clone.querySelector('.definitions-list');
        if (data.Senses) {
            data.Senses.forEach(sense => {
                const li = document.createElement('li');
                li.innerHTML = `<strong>[${sense.ty}]</strong> ${sense.de} <br> <em style="color:var(--text-muted); font-size:0.9em;">"${sense.ex}"</em>`;
                defsList.appendChild(li);
            });
        }

        // Populate media grid (Quotes & Videos combined)
        const mediaGrid = clone.querySelector('.media-grid');
        
        // 1. Render Quotes
        if (data.Quotes) {
            data.Quotes.forEach(quoteStr => {
                // "336407|20413|Pulkit Samrat|Indian Actor|Lush green forests..."
                const parts = quoteStr.split('|');
                if (parts.length >= 5) {
                    const author = parts[2];
                    const text = parts.slice(4).join('|'); // The quote is everything after index 4
                    const card = document.createElement('div');
                    card.className = 'media-card';
                    card.innerHTML = `
                        <div class="media-info" style="padding: 1.5rem;">
                            <p class="media-quote">"${text}"</p>
                            <div class="media-author">
                                <i class="fa-solid fa-user-pen" style="color: var(--primary);"></i>
                                <span>${author}</span>
                            </div>
                        </div>
                    `;
                    mediaGrid.appendChild(card);
                }
            });
        }

        // 2. Render Videos (Thumbnails)
        if (data.Videos) {
            data.Videos.forEach(vidStr => {
                // "38785814|How to speak monkey: The...|2000-3611╣piece by piece,...|4Vfn5CV9juI|275000-295000"
                const parts = vidStr.split('|');
                if (parts.length >= 3) {
                    const youtubeId = parts[parts.length - 2];
                    const thumbUrl = `https://i.ytimg.com/vi/${youtubeId}/mqdefault.jpg`;
                    const card = document.createElement('div');
                    card.className = 'media-card';
                    card.innerHTML = `
                        <img src="${thumbUrl}" alt="Video thumbnail" class="media-thumb" loading="lazy">
                        <div class="media-info">
                            <p class="media-quote" style="font-size: 0.8rem; font-style: normal; color: var(--text-muted);">
                                YouTube ID: ${youtubeId}
                            </p>
                        </div>
                    `;
                    mediaGrid.appendChild(card);
                }
            });
        }

        // Render to DOM
        wordView.innerHTML = '';
        wordView.appendChild(clone);
    }
});
