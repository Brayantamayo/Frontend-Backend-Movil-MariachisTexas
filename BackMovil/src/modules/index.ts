import { Router } from 'express';
import authRoutes from './Auth/auth,routes';
import repertorioRoutes from './Repertorio/Repertorio.routes';
import cotizacionRoutes from './Cotizacion/cotizacion.routes';
import reservaRoutes from './Reserva/reserva.routes';
import clientesRoutes from './Clientes/clientes.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/repertorio', repertorioRoutes);
router.use('/cotizaciones', cotizacionRoutes);
router.use('/reservas', reservaRoutes);
router.use('/clientes', clientesRoutes);

export default router;