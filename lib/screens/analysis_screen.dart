import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// DATA MODELS – sostituisci i valori con quelli reali del tuo parser
// ---------------------------------------------------------------------------

class OFPAnalysisData {
  final String flightNumber;
  final String from;
  final String to;
  final String date;
  final String alternate;
  final String enrouteAirports;
  final String etd;
  final String eta;
  final String etaWindow;
  final String revision;
  final int blockFuelKg;
  final String taxiTime;
  final String plntofTime;
  final int? blockTimeMinutes;

  final int totalExtraFuelMin;

  final FuelComponent enrouteWeather;
  final FuelComponent destinationWeather;
  final FuelComponent alternateWeather;
  final FuelComponent appliedRules;

  final List<String> reasonItems;

  final double pilotsExtraFuelPercent;
  final double thisPilotExtraMin;
  final double routeAvgExtraMin;
  final List<double> extraFuelTrendMonths; // 6 valori (mesi)

  const OFPAnalysisData({
    required this.flightNumber,
    required this.from,
    required this.to,
    required this.date,
    required this.alternate,
    required this.enrouteAirports,
    required this.etd,
    required this.eta,
    required this.etaWindow,
    required this.revision,
    required this.blockFuelKg,
    required this.taxiTime,
    required this.plntofTime,
    required this.blockTimeMinutes,
    required this.totalExtraFuelMin,
    required this.enrouteWeather,
    required this.destinationWeather,
    required this.alternateWeather,
    required this.appliedRules,
    required this.reasonItems,
    required this.pilotsExtraFuelPercent,
    required this.thisPilotExtraMin,
    required this.routeAvgExtraMin,
    required this.extraFuelTrendMonths,
  });

  /// Dati di esempio – rimuovi o sostituisci con il parser reale
  factory OFPAnalysisData.mock() => const OFPAnalysisData(
    flightNumber: 'LH 2042',
    from: 'EDDF',
    to: 'LEMD',
    date: '2026-04-01',
    alternate: 'LEBL',
    enrouteAirports: 'EDDM, LFPG',
    etd: '1230',
    eta: '14:35 UTC',
    etaWindow: '13:35-15:35',
    revision: 'Rev 3',
    blockFuelKg: 8420,
    taxiTime: '00.15',
    plntofTime: '02.05',
    blockTimeMinutes: 140,
    totalExtraFuelMin: 7,
    enrouteWeather: FuelComponent(
      label: 'Enroute Weather',
      deltaMin: 3,
      applicable: true,
      detail:
          'Moderate turbulence SIGMET along LFFF FIR. Jet stream deviation likely.',
    ),
    destinationWeather: FuelComponent(
      label: 'Destination Weather',
      deltaMin: 2,
      applicable: true,
      detail:
          'METAR shows CB in vicinity, crosswind 22kt gusting 35kt. TAF trend worsening.',
    ),
    alternateWeather: FuelComponent(
      label: 'Alternate Weather',
      deltaMin: 1,
      applicable: false,
      detail: 'LEBL CAVOK, no significant weather. Alternate fuel nominal.',
    ),
    appliedRules: FuelComponent(
      label: 'Applied Rules',
      deltaMin: 1,
      applicable: true,
      detail:
          'Statistical uplift: 87% of pilots on EDDF-LEMD carry ≥5 min extra in Q1.',
    ),
    reasonItems: [
      'Active SIGMET for moderate turbulence along planned route through LFFF FIR',
      'Destination METAR indicates CB activity with gusty crosswinds exceeding 20kt',
      'Historical data shows 87% of pilots carry extra fuel on this route in winter',
      'Alternate LEBL conditions nominal — no additional alternate fuel required',
      'Combined statistical and meteorological factors suggest 7 minutes optimal',
    ],
    pilotsExtraFuelPercent: 0.87,
    thisPilotExtraMin: 5.2,
    routeAvgExtraMin: 5.5,
    extraFuelTrendMonths: [5.0, 6.0, 5.5, 6.5, 6.0, 7.0],
  );

  factory OFPAnalysisData.fromParsedOfpJson(Map<String, dynamic> json) {
    return OFPAnalysisData.fromAnalyzeResponseJson({'data': json});
  }

  factory OFPAnalysisData.fromAnalyzeResponseJson(Map<String, dynamic> json) {
    final parsedData = json['data'];
    final data = parsedData is Map<String, dynamic>
        ? parsedData
        : const <String, dynamic>{};
    final enrouteWeather = json['enroute_weather'];
    final enrouteWeatherData = enrouteWeather is Map<String, dynamic>
        ? enrouteWeather
        : const <String, dynamic>{};
    final decision = json['decision'];
    final decisionData = decision is Map<String, dynamic>
        ? decision
        : const <String, dynamic>{};

    final flightIdentification = data['flight_identification'];
    final flightData = flightIdentification is Map<String, dynamic>
        ? flightIdentification
        : const <String, dynamic>{};
    final alternates = data['alternates'];
    final alternatesData = alternates is Map<String, dynamic>
        ? alternates
        : const <String, dynamic>{};
    final times = data['times'];
    final timesData = times is Map<String, dynamic>
        ? times
        : const <String, dynamic>{};

    String value(Map<String, dynamic> source, String key, String fallback) {
      final rawValue = source[key];
      if (rawValue is String && rawValue.trim().isNotEmpty) {
        return rawValue.trim();
      }
      return fallback;
    }

    int? intValue(Map<String, dynamic> source, String key) {
      final rawValue = source[key];
      if (rawValue is int) return rawValue;
      return null;
    }

    double? doubleValue(Map<String, dynamic> source, String key) {
      final rawValue = source[key];
      if (rawValue is num) return rawValue.toDouble();
      return null;
    }

    bool boolValue(Map<String, dynamic> source, String key) {
      final rawValue = source[key];
      if (rawValue is bool) return rawValue;
      return false;
    }

    String listValue(Map<String, dynamic> source, String key) {
      final rawValue = source[key];
      if (rawValue is List) {
        final values = rawValue
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .map((value) => value.trim())
            .toList();
        if (values.isNotEmpty) return values.join(', ');
      }
      return 'N/A';
    }

    final revision = value(flightData, 'ofp_version', 'N/A');
    final eta = _formatHhmm(value(timesData, 'eta', 'N/A'));
    final etaWindowStart = value(timesData, 'eta_window_start', 'N/A');
    final etaWindowEnd = value(timesData, 'eta_window_end', 'N/A');
    final etaWindow = etaWindowStart == 'N/A' || etaWindowEnd == 'N/A'
        ? 'N/A'
        : '$etaWindowStart-$etaWindowEnd';
    final taxiMinutes = intValue(timesData, 'taxi_minutes');
    final plntofMinutes = intValue(timesData, 'plntof_minutes');
    final blockTimeMinutes = intValue(timesData, 'block_time_minutes');
    final decisionMinutes =
        intValue(decisionData, 'extra_fuel_total_minutes') ?? 0;
    final breakdownRaw = decisionData['breakdown'];
    final breakdown = breakdownRaw is List
        ? breakdownRaw.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    Map<String, dynamic>? firstBreakdownForArea(String areaName) {
      for (final item in breakdown) {
        final area = item['area'];
        if (area is String && area.toUpperCase() == areaName) {
          return item;
        }
      }
      return null;
    }

    final tafTrend = data['taf_trend'];
    final tafTrendData = tafTrend is Map<String, dynamic>
        ? tafTrend
        : const <String, dynamic>{};
    final tafDestination = tafTrendData['destination'];
    final tafDestinationData = tafDestination is Map<String, dynamic>
        ? tafDestination
        : const <String, dynamic>{};
    final tafAlternatesRaw = tafTrendData['destination_alternates'];
    final tafAlternates = tafAlternatesRaw is List
        ? tafAlternatesRaw.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];

    final enrouteBreakdown = breakdown.where((item) {
      final area = item['area'];
      return area is String && area.toUpperCase() == 'ENROUTE';
    }).toList();
    final destinationBreakdown = firstBreakdownForArea('DESTINATION');
    final alternateBreakdown = firstBreakdownForArea('ALTERNATE');
    final enrouteMinutes = enrouteBreakdown.isEmpty
        ? 0
        : intValue(enrouteBreakdown.first, 'minutes') ?? 0;
    final enrouteReason = enrouteBreakdown.isEmpty
        ? value(enrouteWeatherData, 'reason', 'No enroute extra fuel required.')
        : value(
            enrouteBreakdown.first,
            'reason',
            'No enroute extra fuel required.',
          );
    final destinationMinutes = destinationBreakdown == null
        ? intValue(tafDestinationData, 'extra_fuel_minutes') ?? 0
        : intValue(destinationBreakdown, 'minutes') ?? 0;
    final destinationReason = destinationBreakdown == null
        ? value(
            tafDestinationData,
            'extra_fuel_reason',
            'No destination TAF extra fuel required.',
          )
        : value(
            destinationBreakdown,
            'reason',
            'No destination TAF extra fuel required.',
          );
    final scoredAlternates = tafAlternates
        .where((item) => (intValue(item, 'extra_fuel_minutes') ?? 0) > 0)
        .toList();
    scoredAlternates.sort(
      (a, b) =>
          (intValue(b, 'extra_fuel_minutes') ?? 0) -
          (intValue(a, 'extra_fuel_minutes') ?? 0),
    );
    final bestAlternate = scoredAlternates.isEmpty
        ? const <String, dynamic>{}
        : scoredAlternates.first;
    final alternateMinutes = alternateBreakdown == null
        ? intValue(bestAlternate, 'extra_fuel_minutes') ?? 0
        : intValue(alternateBreakdown, 'minutes') ?? 0;
    final alternateReason = alternateBreakdown == null
        ? value(
            bestAlternate,
            'extra_fuel_reason',
            'No alternate TAF extra fuel required.',
          )
        : value(
            alternateBreakdown,
            'reason',
            'No alternate TAF extra fuel required.',
          );
    final enrouteConfidence =
        doubleValue(enrouteWeatherData, 'confidence') ??
        (enrouteBreakdown.isEmpty
            ? null
            : doubleValue(enrouteBreakdown.first, 'confidence')) ??
        0.0;
    final manualReview =
        boolValue(decisionData, 'manual_review_required') ||
        boolValue(enrouteWeatherData, 'manual_review_required');
    final hasSigWx = boolValue(
      enrouteWeatherData,
      'has_significant_enroute_wx',
    );
    final hasOcnlCb = boolValue(enrouteWeatherData, 'has_ocnl_cb');
    final topFl = intValue(enrouteWeatherData, 'top_fl');
    final topGreaterThanFl250 = boolValue(
      enrouteWeatherData,
      'top_greater_than_fl250',
    );
    final warningsRaw = enrouteWeatherData['warnings'];
    final warnings = warningsRaw is List
        ? warningsRaw.whereType<String>().where((item) => item.isNotEmpty)
        : const Iterable<String>.empty();
    final decisionReasons = breakdown
        .map((item) => value(item, 'reason', 'N/A'))
        .where((item) => item != 'N/A')
        .toList();
    final reasonItems = <String>[
      ...decisionReasons,
      if (hasSigWx)
        'Significant enroute weather detected on extracted SIGWX chart.',
      if (hasOcnlCb)
        'OCNL CB detected${topFl == null ? '' : ' with TOP FL$topFl'}${topGreaterThanFl250 ? ' above FL250' : ''}.',
      if (manualReview)
        'Manual review required by the enroute weather analysis.',
      ...warnings,
      if (decisionMinutes == 0 && !manualReview)
        'No extra fuel currently required by the decision engine.',
    ];

    return OFPAnalysisData(
      flightNumber: value(flightData, 'flight_number', 'N/A'),
      from: value(flightData, 'departure', 'N/A'),
      to: value(flightData, 'destination', 'N/A'),
      date: value(flightData, 'date', 'N/A'),
      alternate: listValue(alternatesData, 'destination_alternates'),
      enrouteAirports: listValue(alternatesData, 'enroute_airports'),
      etd: value(timesData, 'etd', 'N/A'),
      eta: eta,
      etaWindow: etaWindow,
      revision: revision == 'N/A' ? revision : 'OFP $revision',
      blockFuelKg: 0,
      taxiTime: _formatTimeWithMinutes(
        value(timesData, 'taxi_time', 'N/A'),
        taxiMinutes,
      ),
      plntofTime: _formatTimeWithMinutes(
        value(timesData, 'plntof_time', 'N/A'),
        plntofMinutes,
      ),
      blockTimeMinutes: blockTimeMinutes,
      totalExtraFuelMin: decisionMinutes,
      enrouteWeather: FuelComponent(
        label: 'Enroute Weather',
        deltaMin: enrouteMinutes,
        applicable: enrouteMinutes > 0 || hasSigWx || manualReview,
        detail:
            '$enrouteReason Confidence ${(enrouteConfidence * 100).round()}%.',
      ),
      destinationWeather: FuelComponent(
        label: 'Destination TAF',
        deltaMin: destinationMinutes,
        applicable: destinationMinutes > 0,
        detail: destinationReason,
      ),
      alternateWeather: FuelComponent(
        label: 'Alternate TAF',
        deltaMin: alternateMinutes,
        applicable: alternateMinutes > 0,
        detail: alternateReason,
      ),
      appliedRules: FuelComponent(
        label: 'Decision Engine',
        deltaMin: 0,
        applicable: decisionMinutes > 0 || manualReview,
        detail: manualReview
            ? 'Manual review required before confirming final fuel.'
            : 'Total includes enroute SIGWX, destination TAF, and max alternate TAF.',
      ),
      reasonItems: reasonItems,
      pilotsExtraFuelPercent: enrouteConfidence.clamp(0.0, 1.0),
      thisPilotExtraMin: decisionMinutes.toDouble(),
      routeAvgExtraMin: decisionMinutes.toDouble(),
      extraFuelTrendMonths: const [0, 0, 0, 0, 0, 0],
    );
  }

  static String _formatTimeWithMinutes(String value, int? minutes) {
    if (value == 'N/A' || minutes == null) return value;
    return '$value ($minutes min)';
  }

  static String _formatHhmm(String value) {
    if (value.length != 4) return value;
    return '${value.substring(0, 2)}:${value.substring(2)}';
  }
}

class FuelComponent {
  final String label;
  final int deltaMin;
  final bool applicable;
  final String detail;

  const FuelComponent({
    required this.label,
    required this.deltaMin,
    required this.applicable,
    required this.detail,
  });
}

// ---------------------------------------------------------------------------
// SCREEN
// ---------------------------------------------------------------------------

class AnalysisScreen extends StatelessWidget {
  final OFPAnalysisData data;

  const AnalysisScreen({super.key, required this.data});

  // ---- colori (stessa palette di HomeScreen / LoginScreen) ----
  static const _bgColor = Color(0xFFF2F4F7);
  static const _cardColor = Colors.white;
  static const _accentColor = Color(0xFF3B6FD4);
  static const _mutedMetricColor = Color(0xFF64748B);
  static const _textPrimary = Color(0xFF1A1D23);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E7EB);
  static const _successColor = Color(0xFF16A34A);
  static const _warningColor = Color(0xFFD97706);
  static const _errorColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(child: _buildPortrait(context)),
    );
  }

  // ── PORTRAIT ──────────────────────────────────────────────────────────────

  Widget _buildPortrait(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFlightInfoRow(),
          const SizedBox(height: 20),
          _buildBlockTimeHero(),
          const SizedBox(height: 12),
          _buildExtraFuelHero(),
          const SizedBox(height: 16),
          _buildComponentsGrid(crossAxisCount: 2),
          const SizedBox(height: 16),
          _buildWhyCard(),
          const SizedBox(height: 20),
          _buildAnalyticsHeader(),
          const SizedBox(height: 12),
          _buildDonutCard(),
          const SizedBox(height: 12),
          _buildPilotComparisonCard(),
          const SizedBox(height: 12),
          _buildTrendCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'OFP Analysis',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Recommended extra fuel based on weather, rules, and historical data',
          style: TextStyle(fontSize: 14, color: _textSecondary),
        ),
      ],
    );
  }

  // ── FLIGHT INFO ROW ───────────────────────────────────────────────────────

  Widget _buildFlightInfoRow() {
    final items = [
      _FlightInfoItem(
        icon: Icons.flight_rounded,
        label: 'FLIGHT',
        value: data.flightNumber,
      ),
      _FlightInfoItem(
        icon: Icons.flight_takeoff_rounded,
        label: 'FROM',
        value: data.from,
      ),
      _FlightInfoItem(
        icon: Icons.flight_land_rounded,
        label: 'TO',
        value: data.to,
      ),
      _FlightInfoItem(
        icon: Icons.calendar_today_rounded,
        label: 'DATE',
        value: data.date,
      ),
      _FlightInfoItem(
        icon: Icons.access_time_rounded,
        label: 'ETA',
        value: data.eta,
      ),
      _FlightInfoItem(
        icon: Icons.timer_rounded,
        label: 'TAXI',
        value: data.taxiTime,
      ),
      _FlightInfoItem(
        icon: Icons.flight_takeoff_rounded,
        label: 'PLNTOF',
        value: data.plntofTime,
      ),
      _FlightInfoItem(
        icon: Icons.loop_rounded,
        label: 'REVISION',
        value: data.revision,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildInfoChip(item),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInfoChip(_FlightInfoItem item) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 12, color: _textSecondary),
              const SizedBox(width: 4),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO: RECOMMENDED EXTRA FUEL ─────────────────────────────────────────

  Widget _buildBlockTimeHero() {
    return _buildMetricHero(
      label: 'BLOCK TIME',
      value: data.blockTimeMinutes?.toString() ?? 'N/A',
      unit: data.blockTimeMinutes == null ? '' : 'min',
      valueColor: _mutedMetricColor,
      valueFontSize: 58,
      unitFontSize: 22,
      description: 'Planned gate-to-gate time from OFP schedule data',
    );
  }

  Widget _buildExtraFuelHero() {
    return _buildMetricHero(
      label: 'RECOMMENDED EXTRA FUEL',
      value: '${data.totalExtraFuelMin}',
      unit: 'min',
      valueColor: _accentColor,
      valueFontSize: 80,
      unitFontSize: 28,
      description:
          'Based on enroute weather, destination conditions, and historical route data',
    );
  }

  Widget _buildMetricHero({
    required String label,
    required String value,
    required String unit,
    required Color valueColor,
    required double valueFontSize,
    required double unitFontSize,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 208),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 1.0,
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 6),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: unitFontSize,
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── COMPONENTS GRID ───────────────────────────────────────────────────────

  Widget _buildComponentsGrid({required int crossAxisCount}) {
    final components = [
      data.enrouteWeather,
      data.destinationWeather,
      data.alternateWeather,
      data.appliedRules,
    ];

    if (crossAxisCount == 4) {
      return Row(
        children: components
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildComponentCard(c),
                ),
              ),
            )
            .toList(),
      );
    }

    // 2-column grid
    final rows = <Widget>[];
    for (int i = 0; i < components.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _buildComponentCard(components[i])),
            if (i + 1 < components.length) ...[
              const SizedBox(width: 12),
              Expanded(child: _buildComponentCard(components[i + 1])),
            ],
          ],
        ),
      );
      if (i + 2 < components.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _buildComponentCard(FuelComponent c) {
    final isApplicable = c.applicable;
    final badgeColor = isApplicable ? _accentColor : _textSecondary;
    final badgeBg = isApplicable
        ? _accentColor.withOpacity(0.08)
        : _textSecondary.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isApplicable ? 'Applicable' : 'Not applicable',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${c.deltaMin}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  height: 1.0,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  'min',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.detail,
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
              height: 1.45,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── WHY CARD ──────────────────────────────────────────────────────────────

  Widget _buildWhyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: _accentColor),
              const SizedBox(width: 8),
              const Text(
                'Why This Recommendation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...data.reasonItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: _successColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ANALYTICS ─────────────────────────────────────────────────────────────

  Widget _buildAnalyticsHeader() {
    return const Text(
      'Decision Details',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  /// Donut chart "Pilots Using Extra Fuel" – disegnato con CustomPaint
  Widget _buildDonutCard() {
    return _AnalyticsCard(
      title: 'Enroute Analysis Confidence',
      subtitle: 'SIGWX chart assessment',
      child: SizedBox(
        height: 140,
        child: Center(child: _DonutChart(percent: data.pilotsExtraFuelPercent)),
      ),
    );
  }

  /// Barre orizzontali confronto pilota
  Widget _buildPilotComparisonCard() {
    final maxVal = data.thisPilotExtraMin > data.routeAvgExtraMin
        ? data.thisPilotExtraMin
        : data.routeAvgExtraMin;
    return _AnalyticsCard(
      title: 'Decision Minutes',
      subtitle: 'Current engine output',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildBarRow(
            'Recommended',
            data.thisPilotExtraMin,
            maxVal,
            _accentColor,
          ),
          const SizedBox(height: 12),
          _buildBarRow(
            'Reference',
            data.routeAvgExtraMin,
            maxVal,
            _textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBarRow(String label, double value, double maxVal, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
            Text(
              '${value.toStringAsFixed(1)} min',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final fraction = maxVal > 0 ? value / maxVal : 0.0;
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Line chart andamento ultimi 6 mesi
  Widget _buildTrendCard() {
    return _AnalyticsCard(
      title: 'Historical Trend',
      subtitle: 'Not connected yet',
      child: SizedBox(
        height: 120,
        child: _TrendChart(values: data.extraFuelTrendMonths),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  static String _formatOptionalMinutes(int? minutes) {
    if (minutes == null) return 'N/A';
    return '$minutes min';
  }
}

// ---------------------------------------------------------------------------
// ANALYTICS CARD WRAPPER
// ---------------------------------------------------------------------------

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D23),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DONUT CHART (CustomPainter)
// ---------------------------------------------------------------------------

class _DonutChart extends StatelessWidget {
  final double percent; // 0.0 – 1.0

  const _DonutChart({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(120, 120),
          painter: _DonutPainter(percent: percent),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(percent * 100).round()}%',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3B6FD4),
                height: 1.0,
              ),
            ),
            const Text(
              'carry extra',
              style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percent;
  _DonutPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 12.0;
    final rect = Rect.fromLTWH(
      strokeW / 2,
      strokeW / 2,
      size.width - strokeW,
      size.height - strokeW,
    );

    // sfondo
    canvas.drawArc(
      rect,
      -1.5707963, // -π/2 (top)
      6.2831853, // 2π
      false,
      Paint()
        ..color = const Color(0xFF3B6FD4).withOpacity(0.1)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // arco riempito
    canvas.drawArc(
      rect,
      -1.5707963,
      6.2831853 * percent,
      false,
      Paint()
        ..color = const Color(0xFF3B6FD4)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.percent != percent;
}

// ---------------------------------------------------------------------------
// TREND LINE CHART (CustomPainter)
// ---------------------------------------------------------------------------

class _TrendChart extends StatelessWidget {
  final List<double> values;

  const _TrendChart({required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: _TrendPainter(values: values),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  _TrendPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final n = values.length;
    final stepX = size.width / (n - 1);
    const padT = 16.0;
    const padB = 24.0;
    final chartH = size.height - padT - padB;

    Offset toPoint(int i) {
      final x = i * stepX;
      final y = padT + chartH * (1.0 - (values[i] - minV) / range);
      return Offset(x, y);
    }

    // path + fill
    final path = Path();
    final fillPath = Path();

    path.moveTo(toPoint(0).dx, toPoint(0).dy);
    fillPath.moveTo(toPoint(0).dx, size.height - padB);
    fillPath.lineTo(toPoint(0).dx, toPoint(0).dy);

    for (int i = 1; i < n; i++) {
      final p0 = toPoint(i - 1);
      final p1 = toPoint(i);
      final cp1 = Offset((p0.dx + p1.dx) / 2, p0.dy);
      final cp2 = Offset((p0.dx + p1.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(toPoint(n - 1).dx, size.height - padB);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3B6FD4).withOpacity(0.18),
            const Color(0xFF3B6FD4).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3B6FD4)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // punti
    for (int i = 0; i < n; i++) {
      final pt = toPoint(i);
      canvas.drawCircle(pt, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        pt,
        4,
        Paint()
          ..color = const Color(0xFF3B6FD4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // etichette Y asse (min e max)
    final tp = (double v) => TextPainter(
      text: TextSpan(
        text: v.toStringAsFixed(1),
        style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final minLabel = tp(minV);
    final maxLabel = tp(maxV);
    maxLabel.paint(canvas, Offset(0, padT - 2));
    minLabel.paint(canvas, Offset(0, size.height - padB + 2));
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.values != values;
}

// ---------------------------------------------------------------------------
// HELPER DATA CLASS
// ---------------------------------------------------------------------------

class _FlightInfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _FlightInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
