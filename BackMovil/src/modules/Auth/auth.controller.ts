import { Request, Response } from 'express';
import { loginService } from './auth.services';

export const loginController = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({ message: 'Email y contraseña son requeridos' });
      return;
    }

    const result = await loginService({ email, password });
    res.status(200).json(result);
  } catch (error: any) {
    const clientErrors = ['Credenciales inválidas', 'Usuario inactivo. Contacta al administrador.'];
    if (clientErrors.includes(error.message)) {
      res.status(401).json({ message: error.message });
    } else {
      console.error('Login error:', error);
      res.status(500).json({ message: 'Error interno del servidor' });
    }
  }
};