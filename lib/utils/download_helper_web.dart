import 'dart:html' as html;

void downloadTextFile(String fileName, String content) {
  final bytes = html.Blob([content], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
