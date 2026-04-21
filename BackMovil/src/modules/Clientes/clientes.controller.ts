import { Request, Response } from 'express';
import { obtenerClientes } from './clientes.services';

export const obtenerClientesController = async (req: Request, res: Response) => {
  try {
    const clientes = await obtenerClientes();
    res.json(clientes);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener clientes' });
  }
};