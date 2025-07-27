const express = require('express');
const mysql = require('mysql2');
const app = express();
app.use(express.json());

const db = mysql.createConnection({
    host: 'db',
    user: 'root',
    password: 'root',
    database: 'testdb'
});

db.connect((err) => {
    if (err) { console.error('DB Error', err); process.exit(1); }
    console.log('Connected to MySQL');
});

app.post('/user', (req, res) => {
    const { name, email } = req.body;
    db.query('INSERT INTO users (name, email) VALUES (?, ?)', [name, email], (err) => {
        if (err) return res.status(500).send(err.message);
        res.send('User added!');
    });
});

app.listen(3000, () => console.log('Backend listening on 3000'));