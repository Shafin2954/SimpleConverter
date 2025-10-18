import 'package:flutter/material.dart';
import 'dual_unit_converter.dart';
import 'ad_banner.dart';

class AreaConverterPage extends StatelessWidget {
  const AreaConverterPage({super.key});

  final List<String> units = const [
    'm²', 'yd²', 'km²', 'cm²', 'mm²', 'ha', 'a', 'ft²', 'in²', 'mi²', 'ac'
  ];

  final Map<String, double> toSquareMeter = const {
    'm²': 1.0,
    'km²': 1e6,
    'cm²': 0.0001,
    'mm²': 0.000001,
    'ha': 10000.0,
    'a': 100.0,
    'ft²': 0.092903,
    'in²': 0.00064516,
    'yd²': 0.836127,
    'mi²': 2.59e6,
    'ac': 4046.8564224,
  };

  double _convert(double value, String from, String to) {
    if (from == to) return value;
    double inSqM = value * (toSquareMeter[from] ?? 1.0);
    return inSqM / (toSquareMeter[to] ?? 1.0);
  }

  String _scaleText(String from, String to) {
    if (from == to) return 'Same units';
    double scale = (toSquareMeter[from] ?? 1.0) / (toSquareMeter[to] ?? 1.0);
    return '1 $from = ${scale.toStringAsPrecision(8)} $to';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Area Converter')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: DualUnitConverter(
            units: units,
            scaleTextBuilder: _scaleText,
            convert: _convert,
            key: ValueKey(units.length),
            initialUnit1: units[0],
            initialUnit2: units[1],
          ),
        ),
      ),
      //bottomNavigationBar: const AdBanner(),
    );
  }
}
