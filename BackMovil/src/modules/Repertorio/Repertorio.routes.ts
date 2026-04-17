import { Router } from 'express';
import { auth } from '../../middlewares/auth';
import {
  getAllRepertorioController,
  getAllRepertorioAdminController,
  searchRepertorioController,
  getRepertorioByIdController,
} from './repertorio.controller';

const router = Router();

// ─── Rutas públicas (requieren solo estar autenticado) ────────────────────────

// GET /api/repertorio          → lista canciones activas (app móvil)
router.get('/', auth, getAllRepertorioController);

// GET /api/repertorio/search?q=  → buscar por título, artista o género
router.get('/search', auth, searchRepertorioController);

// GET /api/repertorio/:id      → detalle completo (con letra y audioUrl)
router.get('/:id', auth, getRepertorioByIdController);

// ─── Rutas admin ──────────────────────────────────────────────────────────────

// GET /api/repertorio/admin/all  → todas incluyendo inactivas
router.get('/admin/all', auth, getAllRepertorioAdminController);


export default router;