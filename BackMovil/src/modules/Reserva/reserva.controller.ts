import { Request, Response } from 'express';
import { getAllReservasService, getReservaByIdService, updateReservaService } from './reserva.services';

export const getAllReservasController = async (req: Request, res: Response): Promise<void> => {
  try {
    const reservas = await getAllReservasService();
    res.json(reservas);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
    res.status(500).json({ error: 'Error al obtener reservas', details: errorMessage });
  }
};

export const getReservaByIdController = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const reserva = await getReservaByIdService(parseInt(id));
    
    if (!reserva) {
      res.status(404).json({ error: 'Reserva no encontrada' });
      return;
    }
    
    res.json(reserva);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
    res.status(500).json({ error: 'Error al obtener reserva', details: errorMessage });
  }
};

export const updateReservaController = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { estado, saldoPendiente } = req.body;

    const reserva = await updateReservaService(parseInt(id), {
      estado,
      saldoPendiente
    });

    res.json(reserva);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
    res.status(500).json({ error: 'Error al actualizar reserva', details: errorMessage });
  }
};
