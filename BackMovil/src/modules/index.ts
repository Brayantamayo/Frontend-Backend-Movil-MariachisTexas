import { Router } from 'express';
import authRoutes from './Auth/auth,routes';
import repertorioRoutes from './Repertorio/Repertorio.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/repertorio', repertorioRoutes);

export default router;