import 'package:flutter/material.dart';
import 'dual_unit_converter.dart';
import 'ad_banner.dart';

class VolumeConverterPage extends StatelessWidget {
  const VolumeConverterPage({super.key});

  static const units = [
    'Liter',
    'Gallon',
    'Milliliter',
    'Quart',
    'Pint',
    'Cup',
    'Fluid Ounce',
    'Cubic Meter'
  ];

  static const _toLiter = {
    'Liter': 1.0,
    'Milliliter': 0.001,
    'Gallon': 3.78541,
    'Quart': 0.946353,
    'Pint': 0.473176,
    'Cup': 0.24,
    'Fluid Ounce': 0.0295735,
    'Cubic Meter': 1000.0,
  };

  double _convert(double value, String from, String to) {
    if (from == to) return value;
    double liters = value * (_toLiter[from] ?? 1.0);
    return liters / (_toLiter[to] ?? 1.0);
  }

  String _scaleText(String from, String to) {
    if (from == to) return 'Same units';
    double fromToLiter = _toLiter[from] ?? 1.0;
    double toToLiter = _toLiter[to] ?? 1.0;
    double scale = fromToLiter / toToLiter;
    return 'Using scale: 1 $from = ${scale.toStringAsPrecision(6)} $to';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volume Converter')),
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
