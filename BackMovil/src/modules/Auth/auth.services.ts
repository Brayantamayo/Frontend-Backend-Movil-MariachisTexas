import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../../config/prisma';

export interface LoginPayload {
  email: string;
  password: string;
}

export interface AuthResult {
  token: string;
  user: {
    id: number;
    nombre: string;
    email: string;
    rolId: number;
  };
}

export const loginService = async ({ email, password }: LoginPayload): Promise<AuthResult> => {
  // 1. Buscar usuario en BD
  const usuario = await prisma.usuario.findUnique({
    where: { email },
  });

  if (!usuario) {
    throw new Error('Credenciales inválidas');
  }

  if (!usuario.estado) {
    throw new Error('Usuario inactivo. Contacta al administrador.');
  }

  // 2. Verificar contraseña con bcrypt
  const passwordOk = await bcrypt.compare(password, usuario.password);
  if (!passwordOk) {
    throw new Error('Credenciales inválidas');
  }

  // 3. Firmar JWT (payload incluye rolId para autorización)
  const token = jwt.sign(
    {
      id: usuario.id,
      email: usuario.email,
      rolId: usuario.rolId,
    },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' },
  );

  // 4. Retornar token + datos básicos del usuario
  return {
    token,
    user: {
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      rolId: usuario.rolId,
    },
  };
};