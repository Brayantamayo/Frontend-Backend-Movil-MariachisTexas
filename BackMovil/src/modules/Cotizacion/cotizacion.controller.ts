import { Request, Response } from 'express';
import {
  getAllCotizacionesService,
  getCotizacionByIdService,
  createCotizacionService,
  updateCotizacionService,
  convertirAReservaService,
  anularCotizacionService,
  deleteCotizacionService,
  searchCotizacionesService,
} from './cotizacion.services';
import { generateCotizacionPDF } from './pdf.service';

// GET /api/cotizaciones
export const getAllCotizacionesController = async (req: Request, res: Response): Promise<void> => {
  try {
    const data = await getAllCotizacionesService();
    res.status(200).json(data);
  } catch (error: any) {
    console.error('getAllCotizaciones error:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// GET /api/cotizaciones/search?q=texto
export const searchCotizacionesController = async (req: Request, res: Response): Promise<void> => {
  try {
    const query = (req.query.q as string) ?? '';
    if (!query.trim()) {
      const data = await getAllCotizacionesService();
      res.status(200).json(data);
      return;
    }
    const data = await searchCotizacionesService(query);
    res.status(200).json(data);
  } catch (error: any) {
    console.error('searchCotizaciones error:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// GET /api/cotizaciones/:id
export const getCotizacionByIdController = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = Number(req.params.id);
    if (isNaN(id)) {
      res.status(400).json({ message: 'ID inválido' });
      return;
    }
    const data = await getCotizacionByIdService(id);
    res.status(200).json(data);
  } catch (error: any) {
    if (error.message === 'Cotización no encontrada') {
      res.status(404).json({ message: error.message });
    } else {
      console.error('getCotizacionById error:', error);
      res.status(500).json({ message: 'Error interno del servidor' });
    }
  }
};

// POST /api/cotizaciones
export const createCotizacionController = async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      clienteId,
      nombreHomenajeado,
      tipoEvento,
      fechaEvento,
      horaInicio,
      horaFin,
      direccionEvento,
      notasAdicionales,
      contactoEmail,
      contactoNombre,
      contactoTelefono,
      contactoTelefono2,
      servicios,
      repertorios
    } = req.body;

    // Validaciones básicas
    if (!nombreHomenajeado || !tipoEvento || !fechaEvento || !horaInicio || !horaFin || !direccionEvento) {
      res.status(400).json({ message: 'Faltan campos requeridos' });
      return;
    }

    if (!servicios || !Array.isArray(servicios) || servicios.length === 0) {
      res.status(400).json({ message: 'Debe incluir al menos un servicio' });
      return;
    }

    if (!repertorios || !Array.isArray(repertorios)) {
      res.status(400).json({ message: 'Debe incluir repertorios' });
      return;
    }

    const data = await createCotizacionService({
      clienteId: clienteId || undefined,
      nombreHomenajeado,
      tipoEvento,
      fechaEvento,
      horaInicio,
      horaFin,
      direccionEvento,
      notasAdicionales,
      contactoEmail,
      contactoNombre,
      contactoTelefono,
      contactoTelefono2,
      servicios,
      repertorios
    });

    res.status(201).json(data);
  } catch (error: any) {
    console.error('createCotizacion error:', error);
    res.status(500).json({ message: 'Error interno del servidor' });
  }
};

// PUT /api/cotizaciones/:id
export const updateCotizacionController = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = Number(req.params.id);
    if (isNaN(id)) {
      res.status(400).json({ message: 'ID inválido' });
      return;
    }

    const data = await updateCotizacionService(id, req.body);
    res.status(200).json(data);
  } catch (error: any) {
    if (error.message === 'Cotización no encontrada') {
      res.status(404).json({ message: error.message });
    } else {
      console.error('updateCotizacion error:', error);
      res.status(500).json({ message: 'Error interno del servidor' });
    }
  }
};

// POST /api/cotizaciones/:id/convertir
export const convertirAReservaController = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = Number(req.params.id);
    if (isNaN(id)) {
      res.status(400).json({ message: 'ID inválido' });
      return;
    }

    const reserva = await convertirAReservaService(id);
    res.status(200).json({ 
      message: 'Cotización convertida a reserva exitosamente',
      reserva 
    });
  } catch (error: any) {
    if (error.message.includes('no encontrada') || 
        error.message.includes('Solo se pueden convertir') ||
        error.message.includes('debe tener un total')) {
      res.status(400).json({ message: error.message });
    } else {
      console.error('convertirAReserva error:', error);
      res.status(500).json({ message: 'Error interno del servidor' });
    }
  }
};

// PATCH /api/cotizaciones/:id/anular
export const anularCotizacionController = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = Number(req.params.id);
    if (isNaN(id)) {
      res.status(400).json({ message: 'ID inválido' });
      return;
    }

    const data = await anularCotizacionService(id);
    res.status(200).json(data);
  } catch (error: any) {
    if (error.message.includes('no encontrada') || 
        error.message.includes('No se puede anular')) {
      res.status(400).json({ message: error.message });
    } else {
      console.error('anularCotizacion error:', error);
      res.status(500).json({ message: 'Error interno del servidor' });
    }
  }
};

// DELETE /api/cotizaciones/:id
export const deleteCotizacionController = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = Number(req.params.id);
    if (isNaN(id)) {
      res.status(400).json({ message: 'ID inválido' });
      return;
    }

    await deleteCotizacionService(id);
    res.status(200).json({ message: 'Cotización eliminada exitosamente' });
  } catch (error: any) {
    if (error.message.includes('no encontrada') || 
        error.message.includes('No se puede eliminar')) {
      res.status(400).json({ message: error.message });
    } else {
      console.error('deleteCotizacion error:', error);
      res.status(500).json({ message: 'Error interno del servidor' });
    }
  }
};

// GET /api/cotizaciones/:id/pdf
export const generatePDFController = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = Number(req.params.id);
    if (isNaN(id)) {
      res.status(400).json({ message: 'ID inválido' });
      return;
    }

    const pdfBuffer = await generateCotizacionPDF(id);
    
    // Configurar headers para descarga de PDF
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="cotizacion-${id}.pdf"`);
    res.setHeader('Content-Length', pdfBuffer.length);
    
    res.send(pdfBuffer);
  } catch (error: any) {
    if (error.message === 'Cotización no encontrada') {
      res.status(404).json({ message: error.message });
    } else {
      console.error('generatePDF error:', error);
      res.status(500).json({ message: 'Error al generar PDF' });
    }
  }
};