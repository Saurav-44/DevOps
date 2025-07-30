const express=require('express');
const bodyParser=require('body-parser');
const mysql=require('mysql');
const app=express();
app.use(bodyParser.urlencoded({ extended: true }));

const db=mysql.createConnection({
host:'localhost',
user:'user',
password:'userpass',
database:'app_db'
});

db.connect(err => {
	if(err) {
		console.error('MySQL connection failed:',err);
		return;
	}
	console.log('Connected to MySQL');
	const createTableQuery = `
          CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100),
	    EMAIL VARCHAR(100)
	);
     `;
	db.query(createTableQuery, (err, result) => {
	  if (err) {
	     console.error('Error creating users table:', err);
	 } else {
	     console.log('Users table is ready.');
	}
    });
});

app.get('/', (req, res) => {
	res.sendFile(__dirname + '/index.html');
});

app.post('/submit', (req, res) => {
  const { name, email } = req.body;
  const sql= 'INSERT INTO users (name, email) VALUES (?, ?)';
  db.query(sql, [name, email], (err, result) => {
    if (err) return res.send('BD Error: ' + err);
    res.send('Data submitted succesfully');
  });
});

app.listen(5000, () => {
  console.log(' App running at http://localhost:5000');
});
