import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import modules from '../modules';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:60950', // Flutter Web dev server
    'http://127.0.0.1:3000',
    'http://127.0.0.1:60950',
    /^http:\/\/localhost:\d+$/, // Cualquier puerto localhost
    /^http:\/\/127\.0\.0\.1:\d+$/ // Cualquier puerto 127.0.0.1
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  optionsSuccessStatus: 200 // Para navegadores legacy
}));

// Middleware para logging de peticiones
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url} - Origin: ${req.headers.origin || 'none'}`);
  console.log(`Headers: ${JSON.stringify(req.headers)}`);
  next();
});

app.use(express.json());

// Rutas
app.use('/api', modules);

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

// Test endpoint para verificar CORS
app.get('/api/test', (_req, res) => {
  res.json({ 
    message: 'CORS funcionando correctamente',
    timestamp: new Date().toISOString(),
    origin: _req.headers.origin || 'none'
  });
});

// Test endpoint para verificar autenticación
app.get('/api/test-auth', (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ 
      error: 'No token provided',
      headers: req.headers
    });
  }

  try {
    const jwt = require('jsonwebtoken');
    const decoded = jwt.verify(token, process.env.JWT_SECRET!);
    res.json({ 
      message: 'Token válido',
      user: decoded,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(401).json({ 
      error: 'Token inválido',
      details: error instanceof Error ? error.message : 'Error desconocido'
    });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
  console.log(`Disponible también en:`);
  console.log(`- http://127.0.0.1:${PORT}`);
  console.log(`- http://192.168.18.158:${PORT} (para dispositivos en red)`);
});

export default app;