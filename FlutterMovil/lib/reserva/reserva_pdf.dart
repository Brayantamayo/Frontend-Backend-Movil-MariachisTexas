import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mariachi_admin/core/models/app_models.dart';

// ─── COLORES ──────────────────────────────────────────────────────────────────
const _primary = PdfColor.fromInt(0xFF7B0D1E); // AppColors.primary
const _textMuted = PdfColor.fromInt(0xFF64748B);
const _border = PdfColor.fromInt(0xFFE2E8F0);
const _bg = PdfColor.fromInt(0xFFF8FAFC);

// ─── FORMATO MONEDA ───────────────────────────────────────────────────────────
String _cop(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$${buf.toString()} COP';
}

// ─── GENERADOR PRINCIPAL ──────────────────────────────────────────────────────
Future<void> descargarReservaPdf(Reserva r) async {
  final doc = pw.Document();

  final fecha =
      '${r.fechaEvento.day.toString().padLeft(2, '0')}/${r.fechaEvento.month.toString().padLeft(2, '0')}/${r.fechaEvento.year}';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Encabezado ───────────────────────────────────────────────────
          _header(r),
          pw.SizedBox(height: 20),

          // ── Info del evento ──────────────────────────────────────────────
          _seccion('Información del Evento', [
            _fila('Fecha', fecha),
            _fila('Horario', '${r.horaInicio} – ${r.horaFin}'),
            _fila('Lugar', r.ubicacion),
            if (r.homenajeado.isNotEmpty) _fila('Homenajeado', r.homenajeado),
          ]),
          pw.SizedBox(height: 14),

          // ── Cliente ──────────────────────────────────────────────────────
          _seccion('Cliente', [
            _fila('Nombre', r.clienteNombre),
            if (r.clienteEmail.isNotEmpty) _fila('Email', r.clienteEmail),
            if (r.clienteTelefono.isNotEmpty)
              _fila('Teléfono', r.clienteTelefono),
          ]),
          pw.SizedBox(height: 14),

          // ── Servicios ────────────────────────────────────────────────────
          if (r.chips.isNotEmpty) ...[
            _seccionServiciosChips(r.chips),
            pw.SizedBox(height: 14),
          ],

          // ── Resumen financiero ───────────────────────────────────────────
          _seccionFinanciero(r),
          pw.SizedBox(height: 14),

          // ── Abonos ───────────────────────────────────────────────────────
          if (r.abonos.isNotEmpty) ...[
            _seccionAbonos(r.abonos),
          ],

          pw.Spacer(),

          // ── Pie de página ────────────────────────────────────────────────
          _footer(),
        ],
      ),
    ),
  );

  await Printing.layoutPdf(
    onLayout: (_) async => doc.save(),
    name: 'Reserva_${r.id}_${r.clienteNombre.replaceAll(' ', '_')}.pdf',
  );
}

// ─── WIDGETS PDF ──────────────────────────────────────────────────────────────

pw.Widget _header(Reserva r) {
  final estadoColor = switch (r.estadoEnum) {
    EstadoReserva.confirmada => const PdfColor.fromInt(0xFF047857),
    EstadoReserva.anulada => const PdfColor.fromInt(0xFFB91C1C),
    EstadoReserva.finalizado => const PdfColor.fromInt(0xFF1D4ED8),
    EstadoReserva.pendiente => const PdfColor.fromInt(0xFFB45309),
  };

  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: _primary,
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Mariachi Admin',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Reserva #${r.id}',
              style: const pw.TextStyle(
                color: PdfColors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(20),
          ),
          child: pw.Text(
            r.estadoLabel.toUpperCase(),
            style: pw.TextStyle(
              color: estadoColor,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _seccion(String titulo, List<pw.Widget> filas) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const pw.BoxDecoration(
            color: _bg,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
        ),
        pw.Divider(color: _border, height: 1),
        pw.Padding(
          padding: const pw.EdgeInsets.all(14),
          child: pw.Column(children: filas),
        ),
      ],
    ),
  );
}

pw.Widget _fila(String label, String valor) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 11, color: _textMuted),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

// Versión con VentaServicio (nombres reales del catálogo)
pw.Widget _seccionServiciosChips(List<VentaServicio> servicios) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const pw.BoxDecoration(
            color: _bg,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text('Servicios',
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary)),
        ),
        pw.Divider(color: _border, height: 1),
        pw.Padding(
          padding: const pw.EdgeInsets.all(14),
          child: pw.Column(children: [
            pw.Row(children: [
              pw.Expanded(
                  child: pw.Text('Servicio',
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _textMuted))),
              pw.SizedBox(
                  width: 40,
                  child: pw.Text('Cant.',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _textMuted))),
              pw.SizedBox(
                  width: 80,
                  child: pw.Text('Precio',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _textMuted))),
              pw.SizedBox(
                  width: 80,
                  child: pw.Text('Subtotal',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _textMuted))),
            ]),
            pw.Divider(color: _border),
            ...servicios.map((s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(children: [
                    pw.Expanded(
                        child: pw.Text(s.nombre,
                            style: const pw.TextStyle(fontSize: 11))),
                    pw.SizedBox(
                        width: 40,
                        child: pw.Text('${s.cantidad}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 11))),
                    pw.SizedBox(
                        width: 80,
                        child: pw.Text(_cop(s.precio.round()),
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 11))),
                    pw.SizedBox(
                        width: 80,
                        child: pw.Text(_cop(s.subtotal.round()),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold))),
                  ]),
                )),
          ]),
        ),
      ],
    ),
  );
}

pw.Widget _seccionFinanciero(Reserva r) {
  final pagado = r.totalValor - r.saldoPendiente;
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const pw.BoxDecoration(
            color: _bg,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            'Resumen Financiero',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
        ),
        pw.Divider(color: _border, height: 1),
        pw.Padding(
          padding: const pw.EdgeInsets.all(14),
          child: pw.Column(
            children: [
              _filaFinanciero('Valor Total', _cop(r.totalValor.round()),
                  bold: true),
              _filaFinanciero('Pagado', _cop(pagado.round()),
                  color: const PdfColor.fromInt(0xFF047857)),
              _filaFinanciero('Saldo Pendiente', _cop(r.saldoPendiente.round()),
                  color: r.saldoPendiente > 0
                      ? const PdfColor.fromInt(0xFFB91C1C)
                      : const PdfColor.fromInt(0xFF047857),
                  bold: r.saldoPendiente > 0),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _filaFinanciero(String label, String valor,
    {PdfColor? color, bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 11, color: _textMuted)),
        pw.Text(valor,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            )),
      ],
    ),
  );
}

pw.Widget _seccionAbonos(List<Abono> abonos) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const pw.BoxDecoration(
            color: _bg,
            borderRadius: pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Text(
            'Historial de Pagos',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
        ),
        pw.Divider(color: _border, height: 1),
        pw.Padding(
          padding: const pw.EdgeInsets.all(14),
          child: pw.Column(
            children: abonos.asMap().entries.map((e) {
              final i = e.key + 1;
              final a = e.value;
              final fecha =
                  '${a.fechaPago.day.toString().padLeft(2, '0')}/${a.fechaPago.month.toString().padLeft(2, '0')}/${a.fechaPago.year}';
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  children: [
                    pw.Text('$i.',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _textMuted)),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text('$fecha · ${a.metodoPago}',
                          style: const pw.TextStyle(fontSize: 11)),
                    ),
                    pw.Text(_cop(a.monto.round()),
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF047857))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _footer() {
  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _border)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Mariachi Admin',
            style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
        pw.Text(
          'Generado el ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          style: const pw.TextStyle(fontSize: 9, color: _textMuted),
        ),
      ],
    ),
  );
}
