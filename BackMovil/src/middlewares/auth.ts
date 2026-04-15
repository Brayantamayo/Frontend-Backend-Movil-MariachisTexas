import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

/// Interface para el middleware de autenticación
export interface AuthRequest extends Request {
  user?: { id: number; email: string; role: string };
}

/// Middleware de autenticación
// Verifica el token JWT en la cabecera Authorization y decodifica la información del usuario
export const auth = (req: AuthRequest, res: Response, next: NextFunction): void => {
const token = req.headers.authorization?.split(' ')[1];

/// Verificar si existe token
if (!token) {
    res.status(401).json({ message: 'Token requerido' });
    return;
}

try {
    /// Verificar si token es válido
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as {id: number; email: string; role: string;
    };
    req.user = decoded;
    next();
} catch {
    res.status(401).json({ message: 'Token inválido o expirado' });
}
};