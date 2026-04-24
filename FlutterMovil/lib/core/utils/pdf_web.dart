import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Descarga bytes como archivo PDF en el navegador web.
void descargarEnWeb(List<int> bytes, String filename) {
  final jsArray = bytes.map((b) => b.toJS).toList().toJS;
  final blob = web.Blob(jsArray, web.BlobPropertyBag(type: 'application/pdf'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
  anchor.remove();
}
