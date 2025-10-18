import 'package:flutter/material.dart';
import 'dual_unit_converter.dart';
import 'ad_banner.dart';
class LengthConverterPage extends StatelessWidget {
  const LengthConverterPage({super.key});

  static const units = [
    'Inch',
    'Centimeter',
    'Meter',
    'Kilometer',
    'Foot',
    'Yard',
    'Mile'
  ];

  static const _toMeter = {
    'Inch': 0.0254,
    'Centimeter': 0.01,
    'Meter': 1.0,
    'Kilometer': 1000.0,
    'Foot': 0.3048,
    'Yard': 0.9144,
    'Mile': 1609.344,
  };

  double _convert(double value, String from, String to) {
    if (from == to) return value;
    double meters = value * (_toMeter[from] ?? 1.0);
    return meters / (_toMeter[to] ?? 1.0);
  }

  String _scaleText(String from, String to) {
    if (from == to) return 'Same units';
    double fromToMeter = _toMeter[from] ?? 1.0;
    double toToMeter = _toMeter[to] ?? 1.0;
    double scale = fromToMeter / toToMeter;
    return 'Using scale: 1 $from = ${scale.toStringAsPrecision(6)} $to';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Length Converter')),
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
