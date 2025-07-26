const express    = require('express');
const bodyParser = require('body-parser');
const mysql      = require('mysql2');

const app = express();
app.use(bodyParser.json());
const port = 3000;

// Connect to MySQL (running in same container)
const db = mysql.createConnection({
  host:     process.env.MYSQL_HOST || 'localhost',
  user:     process.env.MYSQL_USER || 'root',
  password: process.env.MYSQL_PASSWORD || 'pass123',
  database: process.env.MYSQL_DATABASE || 'userdata'
});

// initialize table
db.execute(`
  CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
  )
`);

app.post('/api/users', (req, res) => {
  const { name, email } = req.body;
  db.execute(
    'INSERT INTO users (name, email) VALUES (?, ?)',
    [name, email],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ id: result.insertId, name, email });
    }
  );
});

app.get('/api/users', (req, res) => {
  db.execute('SELECT * FROM users', (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});
