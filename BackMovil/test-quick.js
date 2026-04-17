const fetch = require('node-fetch');

async function testQuick() {
  try {
    // Login
    const loginResponse = await fetch('http://localhost:3000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'admin@mariachi.com',
        password: 'admin123'
      })
    });

    if (!loginResponse.ok) {
      console.log('Login failed:', await loginResponse.text());
      return;
    }

    const loginData = await loginResponse.json();
    console.log('Login OK, token:', loginData.token.substring(0, 20) + '...');

    // Get cotizaciones
    const cotizacionesResponse = await fetch('http://localhost:3000/api/cotizaciones', {
      headers: { 'Authorization': `Bearer ${loginData.token}` }
    });

    if (!cotizacionesResponse.ok) {
      console.log('Cotizaciones failed:', await cotizacionesResponse.text());
      return;
    }

    const cotizaciones = await cotizacionesResponse.json();
    console.log(`Found ${cotizaciones.length} cotizaciones`);
    
    if (cotizaciones.length > 0) {
      console.log('First cotizacion:', {
        id: cotizaciones[0].id,
        nombreHomenajeado: cotizaciones[0].nombreHomenajeado,
        totalEstimado: cotizaciones[0].totalEstimado,
        totalEstimadoType: typeof cotizaciones[0].totalEstimado
      });
    }

  } catch (error) {
    console.error('Error:', error.message);
  }
}

testQuick();