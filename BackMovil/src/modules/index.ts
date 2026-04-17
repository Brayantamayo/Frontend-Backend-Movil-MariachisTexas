import { Router } from 'express';
import authRoutes from './Auth/auth,routes';
import repertorioRoutes from './Repertorio/Repertorio.routes';
import cotizacionRoutes from './Cotizacion/cotizacion.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/repertorio', repertorioRoutes);
router.use('/cotizaciones', cotizacionRoutes);

export default router;