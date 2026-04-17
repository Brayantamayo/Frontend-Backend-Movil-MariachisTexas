import prisma from '../../config/prisma';

export interface CreateRepertorioPayload {
  titulo: string;
  artista: string;
  genero: string;
  categoria: string;
  letra?: string;
  audioUrl?: string;
  duracion: string;
  dificultad: string;
  portada?: string;
}

export interface UpdateRepertorioPayload extends Partial<CreateRepertorioPayload> {
  activa?: boolean;
}

// Obtener todas las canciones activas (para la app móvil)
export const getAllRepertorioService = async () => {
  return prisma.repertorio.findMany({
    where: { activa: true },
    orderBy: { titulo: 'asc' },
    select: {
      id: true,
      titulo: true,
      artista: true,
      genero: true,
      categoria: true,
      duracion: true,
      dificultad: true,
      portada: true,
      audioUrl: true,
      activa: true,
    },
  });
};

// Obtener todas (admin: activas e inactivas)
export const getAllRepertorioAdminService = async () => {
  return prisma.repertorio.findMany({
    orderBy: { titulo: 'asc' },
    select: {
      id: true,
      titulo: true,
      artista: true,
      genero: true,
      categoria: true,
      duracion: true,
      dificultad: true,
      portada: true,
      audioUrl: true,
      activa: true,
      createdAt: true,
    },
  });
};

// Obtener detalle completo de una canción (incluye letra)
export const getRepertorioByIdService = async (id: number) => {
  const cancion = await prisma.repertorio.findUnique({
    where: { id },
  });

  if (!cancion) {
    throw new Error('Canción no encontrada');
  }

  return cancion;
};

// Buscar canciones por título o artista
export const searchRepertorioService = async (query: string) => {
  return prisma.repertorio.findMany({
    where: {
      activa: true,
      OR: [
        { titulo: { contains: query, mode: 'insensitive' } },
        { artista: { contains: query, mode: 'insensitive' } },
        { genero: { contains: query, mode: 'insensitive' } },
      ],
    },
    orderBy: { titulo: 'asc' },
    select: {
      id: true,
      titulo: true,
      artista: true,
      genero: true,
      categoria: true,
      duracion: true,
      dificultad: true,
      portada: true,
      audioUrl: true,
      activa: true,
    },
  });
};
