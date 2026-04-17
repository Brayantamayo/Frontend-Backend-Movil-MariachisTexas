import { Request, Response } from 'express';
import {
  getAllRepertorioService,
  getAllRepertorioAdminService,
  getRepertorioByIdService,
  searchRepertorioService,
} from './repertorio.services';

// GET /api/repertorio  → canciones activas (app móvil)
export const getAllRepertorioController = async (req: Request, res: Response): Promise<void> => {
  try {
    const data = await getAllRepertorioService();
    res.status(200).json(data);
  } catch (error: any) {
    console.error('getAllRepertorio error:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// GET /api/repertorio/admin  → todas (admin)
export const getAllRepertorioAdminController = async (req: Request, res: Response): Promise<void> => {
  try {
    const data = await getAllRepertorioAdminService();
    res.status(200).json(data);
  } catch (error: any) {
    console.error('getAllRepertorioAdmin error:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// GET /api/repertorio/search?q=texto
export const searchRepertorioController = async (req: Request, res: Response): Promise<void> => {
  try {
    const query = (req.query.q as string) ?? '';
    if (!query.trim()) {
      const data = await getAllRepertorioService();
      res.status(200).json(data);
      return;
    }
    const data = await searchRepertorioService(query);
    res.status(200).json(data);
  } catch (error: any) {
    console.error('searchRepertorio error:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// GET /api/repertorio/:id  → detalle completo con letra
export const getRepertorioByIdController = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = Number(req.params.id);
    if (isNaN(id)) {
      res.status(400).json({ message: 'ID inválido' });
      return;
    }
    const data = await getRepertorioByIdService(id);
    res.status(200).json(data);
  } catch (error: any) {
    if (error.message === 'Canción no encontrada') {
      res.status(404).json({ message: error.message });
    } else {
      console.error('getRepertorioById error:', error);
      res.status(500).json({ message: 'Error interno del servidor' });
    }
  }
};

