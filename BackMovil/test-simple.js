const fetch = require('node-fetch');

fetch('http://localhost:3000/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'admin@mariachi.com',
    password: 'admin123'
  })
})
.then(res => {
  console.log('Login status:', res.status);
  return res.json();
})
.then(data => {
  console.log('Login response:', data);
  
  if (data.token) {
    return fetch('http://localhost:3000/api/cotizaciones', {
      headers: { 'Authorization': `Bearer ${data.token}` }
    });
  }
})
.then(res => {
  if (res) {
    console.log('Cotizaciones status:', res.status);
    return res.json();
  }
})
.then(cotizaciones => {
  if (cotizaciones) {
    console.log('Cotizaciones count:', cotizaciones.length);
    if (cotizaciones.length > 0) {
      console.log('Sample cotizacion:', {
        id: cotizaciones[0].id,
        totalEstimado: cotizaciones[0].totalEstimado,
        type: typeof cotizaciones[0].totalEstimado
      });
    }
  }
})
.catch(err => console.error('Error:', err.message));