import { Router } from 'express';
import { getAllReservasController, getReservaByIdController, updateReservaController } from './reserva.controller';
import { auth } from '../../middlewares/auth';

const router = Router();

// Aplicar middleware de autenticación a todas las rutas
router.use(auth);

// GET /api/reservas - Obtener todas las reservas
router.get('/', getAllReservasController);

// GET /api/reservas/:id - Obtener una reserva por ID
router.get('/:id', getReservaByIdController);

// PUT /api/reservas/:id - Actualizar una reserva
router.put('/:id', updateReservaController);

export default router;
