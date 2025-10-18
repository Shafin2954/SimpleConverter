import 'package:flutter/material.dart';
import 'dual_unit_converter.dart';
import 'ad_banner.dart';

class SpeedConverterPage extends StatelessWidget {
  const SpeedConverterPage({super.key});

  static const units = [
    'km/h',
    'mph',
    'm/s',
    'ft/s',
    'knot'
  ];

  static const _toMps = {
    'km/h': 0.277777778,
    'mph': 0.44704,
    'm/s': 1.0,
    'ft/s': 0.3048,
    'knot': 0.514444,
  };

  double _convert(double value, String from, String to) {
    if (from == to) return value;
    double mps = value * (_toMps[from] ?? 1.0);
    return mps / (_toMps[to] ?? 1.0);
  }

  String _scaleText(String from, String to) {
    if (from == to) return 'Same units';
    double fromToMps = _toMps[from] ?? 1.0;
    double toToMps = _toMps[to] ?? 1.0;
    double scale = fromToMps / toToMps;
    return 'Using scale: 1 $from = ${scale.toStringAsPrecision(6)} $to';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speed Converter')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: DualUnitConverter(
            units: units,
            scaleTextBuilder: _scaleText,
            convert: _convert,
          ),
        ),
      ),
      //bottomNavigationBar: const AdBanner(),
    );
  }
}
