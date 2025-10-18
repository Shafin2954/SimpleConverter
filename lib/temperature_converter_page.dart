import 'package:flutter/material.dart';
import 'dual_unit_converter.dart';
import 'ad_banner.dart';

class TemperatureConverterPage extends StatelessWidget {
  const TemperatureConverterPage({super.key});

  static const units = [
    'Celsius',
    'Fahrenheit',
    'Kelvin',
    'Rankine'
  ];

  double _convert(double value, String from, String to) {
    if (from == to) return value;
    double celsius;
    // Convert from any to Celsius
    switch (from) {
      case 'Celsius':
        celsius = value;
        break;
      case 'Fahrenheit':
        celsius = (value - 32) * 5 / 9;
        break;
      case 'Kelvin':
        celsius = value - 273.15;
        break;
      case 'Rankine':
        celsius = (value - 491.67) * 5 / 9;
        break;
      default:
        celsius = value;
    }
    // Convert from Celsius to target
    switch (to) {
      case 'Celsius':
        return celsius;
      case 'Fahrenheit':
        return celsius * 9 / 5 + 32;
      case 'Kelvin':
        return celsius + 273.15;
      case 'Rankine':
        return (celsius + 273.15) * 9 / 5;
      default:
        return celsius;
    }
  }

  String _scaleText(String from, String to) {
    if (from == to) return 'Same units';
    if ((from == 'Celsius' && to == 'Fahrenheit') || (from == 'Fahrenheit' && to == 'Celsius')) {
      return 'Using scale: 0°C = 32°F';
    }
    if ((from == 'Celsius' && to == 'Kelvin') || (from == 'Kelvin' && to == 'Celsius')) {
      return 'Using scale: 0°C = 273.15K';
    }
    if ((from == 'Celsius' && to == 'Rankine') || (from == 'Rankine' && to == 'Celsius')) {
      return 'Using scale: 0°C = 491.67°R';
    }
    if ((from == 'Fahrenheit' && to == 'Kelvin') || (from == 'Kelvin' && to == 'Fahrenheit')) {
      return 'Using scale: 32°F = 273.15K';
    }
    if ((from == 'Fahrenheit' && to == 'Rankine') || (from == 'Rankine' && to == 'Fahrenheit')) {
      return 'Using scale: 32°F = 491.67°R';
    }
    if ((from == 'Kelvin' && to == 'Rankine') || (from == 'Rankine' && to == 'Kelvin')) {
      return 'Using scale: 273.15K = 491.67°R';
    }
    return 'Conversion uses standard formula.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Temperature Converter')),
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
