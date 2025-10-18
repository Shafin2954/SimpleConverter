import 'package:flutter/material.dart';
import 'dual_unit_converter.dart';
import 'ad_banner.dart';

class WeightConverterPage extends StatelessWidget {
  const WeightConverterPage({super.key});

  static const units = [
    'Kilogram',
    'Gram',
    'Pound',
    'Ounce',
    'Tonne',
    'Stone'
  ];

  static const _toKg = {
    'Kilogram': 1.0,
    'Gram': 0.001,
    'Pound': 0.45359237,
    'Ounce': 0.0283495231,
    'Tonne': 1000.0,
    'Stone': 6.35029318,
  };

  double _convert(double value, String from, String to) {
    if (from == to) return value;
    double kg = value * (_toKg[from] ?? 1.0);
    return kg / (_toKg[to] ?? 1.0);
  }

  String _scaleText(String from, String to) {
    if (from == to) return 'Same units';
    double fromToKg = _toKg[from] ?? 1.0;
    double toToKg = _toKg[to] ?? 1.0;
    double scale = fromToKg / toToKg;
    return 'Using scale: 1 $from = ${scale.toStringAsPrecision(6)} $to';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weight Converter')),
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
