import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/ofp_data.dart';
import '../services/ofp_parser.dart';

class PdfService {
  static Future<String> extractText(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < document.pages.count; i++) {
      final pageText = extractor.extractText(
        startPageIndex: i,
        endPageIndex: i,
      );
      buffer.writeln('--- PAGE ${i + 1} ---');
      buffer.writeln(pageText);
    }

    document.dispose();
    return buffer.toString();
  }

  static Future<String> saveTextToFile(String text, String pdfFileName) async {
    final baseName = pdfFileName.replaceAll(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );

    final homeDir = Platform.environment['HOME'] ?? '.';
    final outputDir = Directory('$homeDir/ofp_output');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    // --- file 1: testo grezzo ---
    final rawPath = '${outputDir.path}/${baseName}_raw.txt';
    await File(rawPath).writeAsString(text, flush: true);

    // --- file 2: oggetto parsato ---
    final OfpData data = OfpParser.parse(text);
    final parsedPath = '${outputDir.path}/${baseName}_parsed.txt';
    await File(parsedPath).writeAsString(data.toString(), flush: true);

    return parsedPath; // restituisce il path del file parsato
  }
}
