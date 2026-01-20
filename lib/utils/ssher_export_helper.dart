import 'dart:convert';
import 'package:ndu_project/models/project_data_model.dart';
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as loader;

class SsherExportHelper {
  static String entriesToCsv(List<SsherEntry> entries, {String? categoryTitle}) {
    final buffer = StringBuffer();
    
    // Header
    if (categoryTitle != null) {
      buffer.writeln('Category: $categoryTitle');
      buffer.writeln();
    }
    
    buffer.writeln('#,Department,Team Member,Concern,Risk Level,Mitigation Strategy');
    
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final row = [
        '${i + 1}',
        _escapeCsv(e.department),
        _escapeCsv(e.teamMember),
        _escapeCsv(e.concern),
        _escapeCsv(e.riskLevel),
        _escapeCsv(e.mitigation),
      ];
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }

  static String allEntriesToCsv(Map<String, List<SsherEntry>> categoryMap) {
    final buffer = StringBuffer();
    buffer.writeln('SSHER Export - All Categories');
    buffer.writeln();
    
    categoryMap.forEach((category, entries) {
      buffer.writeln(entriesToCsv(entries, categoryTitle: category));
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    });
    
    return buffer.toString();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static Future<void> downloadCsv(String csvContent, String filename) async {
    final bytes = utf8.encode(csvContent);
    loader.downloadFile(bytes, filename);
  }
}
