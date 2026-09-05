import sqlite3

conn = sqlite3.connect('my_wordup_v3.db')
c = conn.cursor()
c.execute('SELECT sql FROM sqlite_master WHERE type="table" AND name="words"')
print(c.fetchone()[0])
conn.close()
