import prisma from '../../config/prisma';
import { EstadoCotizacion, TipoEvento } from '../../generated/prisma';

export interface CreateCotizacionPayload {
  clienteId?: number;
  nombreHomenajeado: string;
  tipoEvento: TipoEvento;
  fechaEvento: string; // ISO string
  horaInicio: string; // ISO string
  horaFin: string; // ISO string
  direccionEvento: string;
  notasAdicionales?: string;
  contactoEmail?: string;
  contactoNombre?: string;
  contactoTelefono?: string;
  contactoTelefono2?: string;
  servicios: Array<{ servicioId: number; cantidad: number }>;
  repertorios: Array<{ repertorioId: number; orden: number }>;
}

export interface UpdateCotizacionPayload {
  nombreHomenajeado?: string;
  tipoEvento?: TipoEvento;
  fechaEvento?: string;
  horaInicio?: string;
  horaFin?: string;
  direccionEvento?: string;
  notasAdicionales?: string;
  contactoEmail?: string;
  contactoNombre?: string;
  contactoTelefono?: string;
  contactoTelefono2?: string;
}

// Obtener todas las cotizaciones
export const getAllCotizacionesService = async () => {
  return prisma.cotizacion.findMany({
    include: {
      cliente: {
        select: {
          id: true,
          apellido: true,
          usuario: {
            select: { nombre: true }
          }
        }
      },
      servicios: {
        include: {
          servicio: {
            select: { nombre: true, precio: true }
          }
        }
      },
      repertorios: {
        include: {
          repertorio: {
            select: { titulo: true, artista: true }
          }
        },
        orderBy: { orden: 'asc' }
      },
      reserva: {
        select: { id: true, estado: true }
      }
    },
    orderBy: { createdAt: 'desc' }
  });
};

// Obtener cotización por ID
export const getCotizacionByIdService = async (id: number) => {
  const cotizacion = await prisma.cotizacion.findUnique({
    where: { id },
    include: {
      cliente: {
        select: {
          id: true,
          apellido: true,
          email: true,
          telefonoPrincipal: true,
          telefonoAlternativo: true,
          direccion: true,
          ciudad: true,
          usuario: {
            select: { nombre: true }
          }
        }
      },
      servicios: {
        include: {
          servicio: {
            select: { id: true, nombre: true, descripcion: true, precio: true }
          }
        }
      },
      repertorios: {
        include: {
          repertorio: {
            select: { id: true, titulo: true, artista: true, genero: true, duracion: true }
          }
        },
        orderBy: { orden: 'asc' }
      },
      reserva: {
        select: { id: true, estado: true, totalValor: true, saldoPendiente: true }
      }
    }
  });

  if (!cotizacion) {
    throw new Error('Cotización no encontrada');
  }

  return cotizacion;
};

// Crear nueva cotización
export const createCotizacionService = async (payload: CreateCotizacionPayload) => {
  const {
    servicios,
    repertorios,
    ...cotizacionData
  } = payload;

  // Calcular total estimado
  const serviciosData = await prisma.servicio.findMany({
    where: { id: { in: servicios.map(s => s.servicioId) } }
  });

  const totalEstimado = serviciosData.reduce((total, servicio) => {
    const cantidad = servicios.find(s => s.servicioId === servicio.id)?.cantidad || 1;
    return total + (Number(servicio.precio) * cantidad);
  }, 0);

  return prisma.cotizacion.create({
    data: {
      ...cotizacionData,
      fechaEvento: new Date(cotizacionData.fechaEvento),
      horaInicio: new Date(cotizacionData.horaInicio),
      horaFin: new Date(cotizacionData.horaFin),
      totalEstimado,
      servicios: {
        create: servicios.map(s => ({
          servicioId: s.servicioId,
          cantidad: s.cantidad
        }))
      },
      repertorios: {
        create: repertorios.map(r => ({
          repertorioId: r.repertorioId,
          orden: r.orden
        }))
      }
    },
    include: {
      cliente: {
        select: {
          id: true,
          apellido: true,
          usuario: { select: { nombre: true } }
        }
      },
      servicios: {
        include: {
          servicio: { select: { nombre: true, precio: true } }
        }
      },
      repertorios: {
        include: {
          repertorio: { select: { titulo: true, artista: true } }
        },
        orderBy: { orden: 'asc' }
      }
    }
  });
};

// Actualizar cotización
export const updateCotizacionService = async (id: number, payload: UpdateCotizacionPayload) => {
  const updateData: any = { ...payload };
  
  if (payload.fechaEvento) updateData.fechaEvento = new Date(payload.fechaEvento);
  if (payload.horaInicio) updateData.horaInicio = new Date(payload.horaInicio);
  if (payload.horaFin) updateData.horaFin = new Date(payload.horaFin);

  return prisma.cotizacion.update({
    where: { id },
    data: updateData,
    include: {
      cliente: {
        select: {
          id: true,
          apellido: true,
          usuario: { select: { nombre: true } }
        }
      },
      servicios: {
        include: {
          servicio: { select: { nombre: true, precio: true } }
        }
      },
      repertorios: {
        include: {
          repertorio: { select: { titulo: true, artista: true } }
        },
        orderBy: { orden: 'asc' }
      }
    }
  });
};

// Convertir cotización a reserva
export const convertirAReservaService = async (id: number) => {
  const cotizacion = await prisma.cotizacion.findUnique({
    where: { id },
    include: {
      servicios: {
        include: { servicio: true }
      }
    }
  });

  if (!cotizacion) {
    throw new Error('Cotización no encontrada');
  }

  if (cotizacion.estado !== EstadoCotizacion.EN_ESPERA) {
    throw new Error('Solo se pueden convertir cotizaciones en espera');
  }

  if (!cotizacion.totalEstimado) {
    throw new Error('La cotización debe tener un total estimado');
  }

  return prisma.$transaction(async (tx) => {
    // Actualizar estado de cotización
    await tx.cotizacion.update({
      where: { id },
      data: { estado: EstadoCotizacion.CONVERTIDA }
    });

    // Crear reserva
    const reserva = await tx.reserva.create({
      data: {
        cotizacionId: id,
        totalValor: cotizacion.totalEstimado,
        saldoPendiente: cotizacion.totalEstimado,
        estado: 'PENDIENTE'
      }
    });

    return reserva;
  });
};

// Anular cotización
export const anularCotizacionService = async (id: number) => {
  const cotizacion = await prisma.cotizacion.findUnique({
    where: { id }
  });

  if (!cotizacion) {
    throw new Error('Cotización no encontrada');
  }

  if (cotizacion.estado === EstadoCotizacion.CONVERTIDA) {
    throw new Error('No se puede anular una cotización ya convertida');
  }

  return prisma.cotizacion.update({
    where: { id },
    data: { estado: EstadoCotizacion.ANULADA }
  });
};

// Eliminar cotización
export const deleteCotizacionService = async (id: number) => {
  const cotizacion = await prisma.cotizacion.findUnique({
    where: { id },
    include: { reserva: true }
  });

  if (!cotizacion) {
    throw new Error('Cotización no encontrada');
  }

  if (cotizacion.reserva) {
    throw new Error('No se puede eliminar una cotización que ya tiene reserva');
  }

  return prisma.cotizacion.delete({
    where: { id }
  });
};

// Buscar cotizaciones
export const searchCotizacionesService = async (query: string) => {
  return prisma.cotizacion.findMany({
    where: {
      OR: [
        { nombreHomenajeado: { contains: query, mode: 'insensitive' } },
        { contactoNombre: { contains: query, mode: 'insensitive' } },
        { contactoEmail: { contains: query, mode: 'insensitive' } },
        { cliente: {
          OR: [
            { apellido: { contains: query, mode: 'insensitive' } },
            { usuario: { nombre: { contains: query, mode: 'insensitive' } } }
          ]
        }}
      ]
    },
    include: {
      cliente: {
        select: {
          id: true,
          apellido: true,
          usuario: { select: { nombre: true } }
        }
      },
      servicios: {
        include: {
          servicio: { select: { nombre: true, precio: true } }
        }
      },
      repertorios: {
        include: {
          repertorio: { select: { titulo: true, artista: true } }
        },
        orderBy: { orden: 'asc' }
      },
      reserva: {
        select: { id: true, estado: true }
      }
    },
    orderBy: { createdAt: 'desc' }
  });
};