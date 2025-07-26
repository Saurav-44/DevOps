<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Simple Frontend</title>
</head>
<body>
  <h1>User Registration</h1>
  <form id="userForm">
    <input type="text" id="name" placeholder="Name" required />
    <input type="email" id="email" placeholder="Email" required />
    <button type="submit">Submit</button>
  </form>
  <pre id="result"></pre>
  <script>
    const form = document.getElementById('userForm');
    const result = document.getElementById('result');
    const api = `${window.location.origin.replace(/:[0-9]+$/, '')}:3000/api/users`;
    form.addEventListener('submit', e => {
      e.preventDefault();
      fetch(api, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name:  document.getElementById('name').value,
          email: document.getElementById('email').value
        })
      })
      .then(r => r.json())
      .then(json => result.textContent = JSON.stringify(json, null, 2))
      .catch(err => result.textContent = err);
    });
  </script>
</body>
</html>
