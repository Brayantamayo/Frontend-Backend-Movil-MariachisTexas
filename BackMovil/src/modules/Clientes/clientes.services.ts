import prisma from '../../config/prisma';

export const obtenerClientes = async () => {
  return await prisma.cliente.findMany({
    include: {
      usuario: {
        select: {
          nombre: true,
          email: true,
        }
      }
    }
  });
};