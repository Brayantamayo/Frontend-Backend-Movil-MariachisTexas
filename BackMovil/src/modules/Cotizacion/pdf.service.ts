import PDFDocument from 'pdfkit';
import { getCotizacionByIdService } from './cotizacion.services';

export const generateCotizacionPDF = async (cotizacionId: number): Promise<Buffer> => {
  // Obtener datos de la cotización
  const cotizacion = await getCotizacionByIdService(cotizacionId);
  
  return new Promise((resolve, reject) => {
    try {
      // Crear documento PDF
      const doc = new PDFDocument({ margin: 50 });
      const buffers: Buffer[] = [];

      // Capturar el contenido del PDF en buffers
      doc.on('data', (buffer) => buffers.push(buffer));
      doc.on('end', () => resolve(Buffer.concat(buffers)));

      // Configurar fuente
      doc.fontSize(20).text('COTIZACIÓN DE SERVICIOS MARIACHI', { align: 'center' });
      doc.moveDown();

      // Información de la cotización
      doc.fontSize(14).text(`Cotización #${cotizacion.id}`, { underline: true });
      doc.moveDown(0.5);

      // Datos del evento
      doc.fontSize(12);
      doc.text(`Homenajeado: ${cotizacion.nombreHomenajeado}`, { continued: false });
      doc.text(`Tipo de Evento: ${formatTipoEvento(cotizacion.tipoEvento)}`);
      doc.text(`Fecha: ${formatDate(cotizacion.fechaEvento)}`);
      doc.text(`Hora: ${formatTime(cotizacion.horaInicio)} - ${formatTime(cotizacion.horaFin)}`);
      doc.text(`Lugar: ${cotizacion.direccionEvento}`);
      doc.text(`Estado: ${formatEstado(cotizacion.estado)}`);
      doc.moveDown();

      // Información de contacto
      if (cotizacion.contactoNombre || cotizacion.contactoEmail || cotizacion.contactoTelefono) {
        doc.fontSize(14).text('INFORMACIÓN DE CONTACTO', { underline: true });
        doc.fontSize(12);
        if (cotizacion.contactoNombre) doc.text(`Contacto: ${cotizacion.contactoNombre}`);
        if (cotizacion.contactoEmail) doc.text(`Email: ${cotizacion.contactoEmail}`);
        if (cotizacion.contactoTelefono) doc.text(`Teléfono: ${cotizacion.contactoTelefono}`);
        if (cotizacion.contactoTelefono2) doc.text(`Teléfono 2: ${cotizacion.contactoTelefono2}`);
        doc.moveDown();
      }

      // Cliente (si existe)
      if (cotizacion.cliente) {
        doc.fontSize(14).text('INFORMACIÓN DEL CLIENTE', { underline: true });
        doc.fontSize(12);
        doc.text(`Cliente: ${cotizacion.cliente.usuario.nombre} ${cotizacion.cliente.apellido}`);
        if (cotizacion.cliente.email) doc.text(`Email: ${cotizacion.cliente.email}`);
        if (cotizacion.cliente.telefonoPrincipal) doc.text(`Teléfono: ${cotizacion.cliente.telefonoPrincipal}`);
        if (cotizacion.cliente.direccion) doc.text(`Dirección: ${cotizacion.cliente.direccion}, ${cotizacion.cliente.ciudad}`);
        doc.moveDown();
      }

      // Servicios
      if (cotizacion.servicios && cotizacion.servicios.length > 0) {
        doc.fontSize(14).text('SERVICIOS CONTRATADOS', { underline: true });
        doc.moveDown(0.5);

        // Tabla de servicios
        const tableTop = doc.y;
        const itemHeight = 20;
        let currentY = tableTop;

        // Headers
        doc.fontSize(10);
        doc.text('Servicio', 50, currentY, { width: 200 });
        doc.text('Cantidad', 250, currentY, { width: 60, align: 'center' });
        doc.text('Precio Unit.', 310, currentY, { width: 80, align: 'right' });
        doc.text('Subtotal', 390, currentY, { width: 80, align: 'right' });
        
        currentY += itemHeight;
        doc.moveTo(50, currentY).lineTo(470, currentY).stroke();
        currentY += 5;

        // Servicios
        let total = 0;
        cotizacion.servicios.forEach((cs) => {
          const subtotal = Number(cs.servicio.precio) * cs.cantidad;
          total += subtotal;

          doc.text(cs.servicio.nombre, 50, currentY, { width: 200 });
          doc.text(cs.cantidad.toString(), 250, currentY, { width: 60, align: 'center' });
          doc.text(formatCurrency(Number(cs.servicio.precio)), 310, currentY, { width: 80, align: 'right' });
          doc.text(formatCurrency(subtotal), 390, currentY, { width: 80, align: 'right' });
          
          currentY += itemHeight;
        });

        // Total
        doc.moveTo(50, currentY).lineTo(470, currentY).stroke();
        currentY += 10;
        doc.fontSize(12).text('TOTAL ESTIMADO:', 310, currentY, { width: 80, align: 'right' });
        doc.text(formatCurrency(total), 390, currentY, { width: 80, align: 'right' });
        
        doc.moveDown(2);
      }

      // Repertorio
      if (cotizacion.repertorios && cotizacion.repertorios.length > 0) {
        doc.fontSize(14).text('REPERTORIO MUSICAL', { underline: true });
        doc.moveDown(0.5);
        doc.fontSize(10);

        cotizacion.repertorios.forEach((cr, index) => {
          doc.text(`${cr.orden}. ${cr.repertorio.titulo} - ${cr.repertorio.artista}`);
        });
        
        doc.moveDown();
      }

      // Notas adicionales
      if (cotizacion.notasAdicionales) {
        doc.fontSize(14).text('NOTAS ADICIONALES', { underline: true });
        doc.fontSize(10);
        doc.text(cotizacion.notasAdicionales, { align: 'justify' });
        doc.moveDown();
      }

      // Footer
      doc.fontSize(8);
      doc.text('Este documento es una cotización y no constituye una factura.', { align: 'center' });
      doc.text(`Generado el ${new Date().toLocaleDateString('es-CO')} a las ${new Date().toLocaleTimeString('es-CO')}`, { align: 'center' });

      // Finalizar el documento
      doc.end();

    } catch (error) {
      reject(error);
    }
  });
};

// Funciones auxiliares para formateo
function formatTipoEvento(tipo: string): string {
  const tipos: { [key: string]: string } = {
    'BODA': 'Boda',
    'CUMPLEANOS': 'Cumpleaños',
    'QUINCEANIOS': 'Quinceaños',
    'FUNERAL': 'Funeral',
    'RECONCILIACION': 'Reconciliación',
    'DIA_DE_MADRE': 'Día de la Madre',
    'AMOR': 'Serenata de Amor',
    'ANIVERSARIO': 'Aniversario',
    'PADRES': 'Día del Padre',
    'FIESTA': 'Fiesta',
    'OTRO': 'Otro'
  };
  return tipos[tipo] || tipo;
}

function formatEstado(estado: string): string {
  const estados: { [key: string]: string } = {
    'EN_ESPERA': 'En Espera',
    'CONVERTIDA': 'Convertida a Reserva',
    'ANULADA': 'Anulada'
  };
  return estados[estado] || estado;
}

function formatDate(date: Date): string {
  return new Date(date).toLocaleDateString('es-CO', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}

function formatTime(date: Date): string {
  return new Date(date).toLocaleTimeString('es-CO', {
    hour: '2-digit',
    minute: '2-digit'
  });
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    minimumFractionDigits: 0
  }).format(amount);
}