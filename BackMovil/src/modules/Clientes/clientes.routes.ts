import { Router } from 'express';
import { obtenerClientesController } from './clientes.controller';
import { auth } from '../../middlewares/auth';

const router = Router();

router.get('/', auth, obtenerClientesController);

export default router;