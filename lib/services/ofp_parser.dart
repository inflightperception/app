import '../models/ofp_data.dart';

class OfpParser {
  static OfpData parse(String rawText) {
    return OfpData(
      flightNumber    : _extract(rawText, RegExp(r'AZ\s*(\d{4})')),
      departure       : _extract(rawText, RegExp(r'([A-Z]{3})-([A-Z]{3})'), group: 1),
      destination     : _extract(rawText, RegExp(r'([A-Z]{3})-([A-Z]{3})'), group: 2),
      date            : _extract(rawText, RegExp(r'(\d{4}-\d{2}-\d{2})')),
      ofpVersion      : _extract(rawText, RegExp(r'OFP:(\d+/\d+/\d+)')),
      destAlternates  : _extractAll(
        rawText.substring(
          rawText.indexOf('DESTINATION ALTERNATE(S)'),
          rawText.indexOf('ENROUTE AIRPORT(S)'),
        ),
        RegExp(r'[A-Z]{4}\s*/\s*([A-Z]{3})'),
      ),
      enrouteAirports : _extractAll(
        rawText.substring(
          rawText.indexOf('ENROUTE AIRPORT(S)'),
          rawText.indexOf('INTENTIONALLY LEFT BLANK'),
        ),
        RegExp(r'[A-Z]{4}\s*/\s*([A-Z]{3})'),
      ),

      taxiTime : _extract(rawText, RegExp(r'TAXI\s+\d+\s+(\d{2}\.\d{2})')),
      plntofTime : _extract(rawText, RegExp(r'PLNTOF\s+\d+\s+(\d{2}\.\d{2})')),

      etd             : _extract(rawText, RegExp(r'\(\d+\.\d+\)\s+(\d{4})/\d{4}')),
      eta             : _extract(rawText, RegExp(r'\(\d+\.\d+\)\s+\d{4}/\d{4}\s+(\d{4})/\d{4}'))
    );
  }

  static String? _extract(String text, RegExp pattern, {int group = 1}) {
    final match = pattern.firstMatch(text);
    return match?.group(group)?.trim();
  }

  static List<String> _extractAll(String text, RegExp pattern, {int group = 1}) {
    return pattern
        .allMatches(text)
        .map((m) => m.group(group)?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
