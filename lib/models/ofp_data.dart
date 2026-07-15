class OfpData {
  // ---- FLIGHT INFO ----
  final String? flightNumber;
  final String? departure;
  final String? destination;
  final String? date;
  final String? ofpVersion;
  final List<String> destAlternates;
  final List<String> enrouteAirports;

  // ---- TIMES ----
  final String? etd;
  final String? eta;
  final String? taxiTime;
  final String? plntofTime;

  const OfpData({
    this.flightNumber,
    this.departure,
    this.destination,
    this.date,
    this.ofpVersion,
    this.destAlternates = const [],
    this.enrouteAirports = const [],
    this.etd,
    this.eta,
    this.taxiTime,
    this.plntofTime,
  });

  // ---- COMPUTED ----
  double? get blockFuel {
    if (taxiTime == null || plntofTime == null) return null;
    final taxi = double.tryParse(taxiTime!);
    final plntof = double.tryParse(plntofTime!);
    if (taxi == null || plntof == null) return null;
    return taxi + plntof;
  }

  @override
  String toString() {
    return '''
========== OFP DATA ==========
Flight Number   : ${flightNumber ?? 'N/A'}
Departure       : ${departure ?? 'N/A'}
Destination     : ${destination ?? 'N/A'}
Date            : ${date ?? 'N/A'}
OFP Version     : ${ofpVersion ?? 'N/A'}
Dest Alternates : ${destAlternates.isEmpty ? 'N/A' : destAlternates.join(', ')}
Enroute Airports: ${enrouteAirports.isEmpty ? 'N/A' : enrouteAirports.join(', ')}
ETD             : ${etd ?? 'N/A'}
ETA             : ${eta ?? 'N/A'}
Taxi Time       : ${taxiTime ?? 'N/A'}
PLNTOF Time     : ${plntofTime ?? 'N/A'}
Block Fuel      : ${blockFuel?.toStringAsFixed(2) ?? 'N/A'}
==============================
''';
  }
}
