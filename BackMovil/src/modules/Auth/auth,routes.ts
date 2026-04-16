import { Router } from 'express';
import { loginController } from './auth.controller';
import { auth } from '../../middlewares/auth';

const router = Router();

// POST /api/auth/login
router.post('/login', loginController);

// GET /api/auth/me  - obtener perfil del usuario autenticado
router.get('/me', auth, async (req: any, res) => {
  res.json({ user: req.user });
});

export default router;