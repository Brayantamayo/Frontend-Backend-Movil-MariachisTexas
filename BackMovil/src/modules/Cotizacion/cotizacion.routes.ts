import { Router } from 'express';
import { auth } from '../../middlewares/auth';
import {
  getAllCotizacionesController,
  searchCotizacionesController,
  getCotizacionByIdController,
  createCotizacionController,
  updateCotizacionController,
  convertirAReservaController,
  anularCotizacionController,
  deleteCotizacionController,
  generatePDFController,
} from './cotizacion.controller';

const router = Router();

// Todas las rutas requieren autenticación
router.use(auth);

// GET /api/cotizaciones - Obtener todas las cotizaciones
router.get('/', getAllCotizacionesController);

// GET /api/cotizaciones/search?q=texto - Buscar cotizaciones
router.get('/search', searchCotizacionesController);

// GET /api/cotizaciones/:id - Obtener cotización por ID
router.get('/:id', getCotizacionByIdController);

// POST /api/cotizaciones - Crear nueva cotización
router.post('/', createCotizacionController);

// PUT /api/cotizaciones/:id - Actualizar cotización
router.put('/:id', updateCotizacionController);

// POST /api/cotizaciones/:id/convertir - Convertir a reserva
router.post('/:id/convertir', convertirAReservaController);

// PATCH /api/cotizaciones/:id/anular - Anular cotización
router.patch('/:id/anular', anularCotizacionController);

// DELETE /api/cotizaciones/:id - Eliminar cotización
router.delete('/:id', deleteCotizacionController);

// GET /api/cotizaciones/:id/pdf - Generar y descargar PDF
router.get('/:id/pdf', generatePDFController);

export default router;