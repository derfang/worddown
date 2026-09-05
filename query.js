const sqlite3 = require('sqlite3');
const db = new sqlite3.Database('my_wordup_v3.db');
const fs = require('fs');
db.all("SELECT wordId as i, text as w, primaryMeaning as m FROM words", (e, r) => {
  fs.writeFileSync('words_search.json', JSON.stringify(r));
  console.log('Dumped. Size:', fs.statSync('words_search.json').size);
});
