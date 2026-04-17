import prisma from '../../config/prisma';

export interface UpdateReservaPayload {
  estado?: string;
  saldoPendiente?: number;
}

export const getAllReservasService = async () => {
  try {
    const reservas = await prisma.reserva.findMany({
      include: {
        cotizacion: {
          include: {
            cliente: true,
            repertorios: {
              include: {
                repertorio: true
              }
            },
            servicios: {
              include: {
                servicio: true
              }
            }
          }
        },
        abonos: true
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    return reservas.map(reserva => ({
      id: reserva.id,
      cotizacionId: reserva.cotizacionId,
      totalValor: parseFloat(reserva.totalValor.toString()),
      saldoPendiente: parseFloat(reserva.saldoPendiente.toString()),
      estado: reserva.estado,
      createdAt: reserva.createdAt,
      updatedAt: reserva.updatedAt,
      cotizacion: reserva.cotizacion ? {
        id: reserva.cotizacion.id,
        nombreHomenajeado: reserva.cotizacion.nombreHomenajeado,
        tipoEvento: reserva.cotizacion.tipoEvento,
        fechaEvento: reserva.cotizacion.fechaEvento,
        horaInicio: reserva.cotizacion.horaInicio,
        horaFin: reserva.cotizacion.horaFin,
        direccionEvento: reserva.cotizacion.direccionEvento,
        notasAdicionales: reserva.cotizacion.notasAdicionales,
        totalEstimado: reserva.cotizacion.totalEstimado ? parseFloat(reserva.cotizacion.totalEstimado.toString()) : null,
        estado: reserva.cotizacion.estado,
        contactoEmail: reserva.cotizacion.contactoEmail,
        contactoNombre: reserva.cotizacion.contactoNombre,
        contactoTelefono: reserva.cotizacion.contactoTelefono,
        cliente: reserva.cotizacion.cliente ? {
          id: reserva.cotizacion.cliente.id,
          apellido: reserva.cotizacion.cliente.apellido,
          email: reserva.cotizacion.cliente.email,
          telefonoPrincipal: reserva.cotizacion.cliente.telefonoPrincipal
        } : null,
        repertorios: reserva.cotizacion.repertorios.map(cr => ({
          id: cr.repertorio.id,
          titulo: cr.repertorio.titulo,
          artista: cr.repertorio.artista,
          genero: cr.repertorio.genero,
          categoria: cr.repertorio.categoria,
          duracion: cr.repertorio.duracion,
          dificultad: cr.repertorio.dificultad,
          portada: cr.repertorio.portada
        })),
        servicios: reserva.cotizacion.servicios.map(cs => ({
          id: cs.servicio.id,
          nombre: cs.servicio.nombre,
          descripcion: cs.servicio.descripcion,
          precio: parseFloat(cs.servicio.precio.toString()),
          cantidad: cs.cantidad
        }))
      } : null,
      abonos: reserva.abonos.map(abono => ({
        id: abono.id,
        monto: parseFloat(abono.monto.toString()),
        fechaPago: abono.fechaPago,
        metodoPago: abono.metodoPago,
        nuevoSaldo: parseFloat(abono.nuevoSaldo.toString()),
        notas: abono.notas
      }))
    }));
  } catch (error) {
    console.error('Error en getAllReservasService:', error);
    throw error;
  }
};

export const getReservaByIdService = async (id: number) => {
  try {
    const reserva = await prisma.reserva.findUnique({
      where: { id },
      include: {
        cotizacion: {
          include: {
            cliente: true,
            repertorios: {
              include: {
                repertorio: true
              }
            },
            servicios: {
              include: {
                servicio: true
              }
            }
          }
        },
        abonos: true
      }
    });

    if (!reserva) return null;

    return {
      id: reserva.id,
      cotizacionId: reserva.cotizacionId,
      totalValor: parseFloat(reserva.totalValor.toString()),
      saldoPendiente: parseFloat(reserva.saldoPendiente.toString()),
      estado: reserva.estado,
      createdAt: reserva.createdAt,
      updatedAt: reserva.updatedAt,
      cotizacion: reserva.cotizacion ? {
        id: reserva.cotizacion.id,
        nombreHomenajeado: reserva.cotizacion.nombreHomenajeado,
        tipoEvento: reserva.cotizacion.tipoEvento,
        fechaEvento: reserva.cotizacion.fechaEvento,
        horaInicio: reserva.cotizacion.horaInicio,
        horaFin: reserva.cotizacion.horaFin,
        direccionEvento: reserva.cotizacion.direccionEvento,
        notasAdicionales: reserva.cotizacion.notasAdicionales,
        totalEstimado: reserva.cotizacion.totalEstimado ? parseFloat(reserva.cotizacion.totalEstimado.toString()) : null,
        estado: reserva.cotizacion.estado,
        contactoEmail: reserva.cotizacion.contactoEmail,
        contactoNombre: reserva.cotizacion.contactoNombre,
        contactoTelefono: reserva.cotizacion.contactoTelefono,
        cliente: reserva.cotizacion.cliente ? {
          id: reserva.cotizacion.cliente.id,
          apellido: reserva.cotizacion.cliente.apellido,
          email: reserva.cotizacion.cliente.email,
          telefonoPrincipal: reserva.cotizacion.cliente.telefonoPrincipal
        } : null,
        repertorios: reserva.cotizacion.repertorios.map(cr => ({
          id: cr.repertorio.id,
          titulo: cr.repertorio.titulo,
          artista: cr.repertorio.artista,
          genero: cr.repertorio.genero,
          categoria: cr.repertorio.categoria,
          duracion: cr.repertorio.duracion,
          dificultad: cr.repertorio.dificultad,
          portada: cr.repertorio.portada
        })),
        servicios: reserva.cotizacion.servicios.map(cs => ({
          id: cs.servicio.id,
          nombre: cs.servicio.nombre,
          descripcion: cs.servicio.descripcion,
          precio: parseFloat(cs.servicio.precio.toString()),
          cantidad: cs.cantidad
        }))
      } : null,
      abonos: reserva.abonos.map(abono => ({
        id: abono.id,
        monto: parseFloat(abono.monto.toString()),
        fechaPago: abono.fechaPago,
        metodoPago: abono.metodoPago,
        nuevoSaldo: parseFloat(abono.nuevoSaldo.toString()),
        notas: abono.notas
      }))
    };
  } catch (error) {
    console.error('Error en getReservaByIdService:', error);
    throw error;
  }
};

export const updateReservaService = async (id: number, payload: UpdateReservaPayload) => {
  try {
    const updateData: any = {};

    if (payload.estado) {
      updateData.estado = payload.estado;
    }

    if (payload.saldoPendiente !== undefined) {
      updateData.saldoPendiente = payload.saldoPendiente;
    }

    const reserva = await prisma.reserva.update({
      where: { id },
      data: updateData,
      include: {
        cotizacion: {
          include: {
            cliente: true,
            repertorios: {
              include: {
                repertorio: true
              }
            },
            servicios: {
              include: {
                servicio: true
              }
            }
          }
        },
        abonos: true
      }
    });

    return {
      id: reserva.id,
      cotizacionId: reserva.cotizacionId,
      totalValor: parseFloat(reserva.totalValor.toString()),
      saldoPendiente: parseFloat(reserva.saldoPendiente.toString()),
      estado: reserva.estado,
      createdAt: reserva.createdAt,
      updatedAt: reserva.updatedAt,
      cotizacion: reserva.cotizacion ? {
        id: reserva.cotizacion.id,
        nombreHomenajeado: reserva.cotizacion.nombreHomenajeado,
        tipoEvento: reserva.cotizacion.tipoEvento,
        fechaEvento: reserva.cotizacion.fechaEvento,
        horaInicio: reserva.cotizacion.horaInicio,
        horaFin: reserva.cotizacion.horaFin,
        direccionEvento: reserva.cotizacion.direccionEvento,
        notasAdicionales: reserva.cotizacion.notasAdicionales,
        totalEstimado: reserva.cotizacion.totalEstimado ? parseFloat(reserva.cotizacion.totalEstimado.toString()) : null,
        estado: reserva.cotizacion.estado,
        contactoEmail: reserva.cotizacion.contactoEmail,
        contactoNombre: reserva.cotizacion.contactoNombre,
        contactoTelefono: reserva.cotizacion.contactoTelefono,
        cliente: reserva.cotizacion.cliente ? {
          id: reserva.cotizacion.cliente.id,
          apellido: reserva.cotizacion.cliente.apellido,
          email: reserva.cotizacion.cliente.email,
          telefonoPrincipal: reserva.cotizacion.cliente.telefonoPrincipal
        } : null,
        repertorios: reserva.cotizacion.repertorios.map(cr => ({
          id: cr.repertorio.id,
          titulo: cr.repertorio.titulo,
          artista: cr.repertorio.artista,
          genero: cr.repertorio.genero,
          categoria: cr.repertorio.categoria,
          duracion: cr.repertorio.duracion,
          dificultad: cr.repertorio.dificultad,
          portada: cr.repertorio.portada
        })),
        servicios: reserva.cotizacion.servicios.map(cs => ({
          id: cs.servicio.id,
          nombre: cs.servicio.nombre,
          descripcion: cs.servicio.descripcion,
          precio: parseFloat(cs.servicio.precio.toString()),
          cantidad: cs.cantidad
        }))
      } : null,
      abonos: reserva.abonos.map(abono => ({
        id: abono.id,
        monto: parseFloat(abono.monto.toString()),
        fechaPago: abono.fechaPago,
        metodoPago: abono.metodoPago,
        nuevoSaldo: parseFloat(abono.nuevoSaldo.toString()),
        notas: abono.notas
      }))
    };
  } catch (error) {
    console.error('Error en updateReservaService:', error);
    throw error;
  }
};
