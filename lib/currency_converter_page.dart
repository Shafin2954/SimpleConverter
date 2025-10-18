import 'package:flutter/material.dart';
import 'dual_unit_converter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  // TODO: Replace with your actual API key from https://exchangerate.host/
  static const String _apiKey = 'b9dc74af712af75aa5e2499396d2e13c';
  List<String> units = [
    'USD', 'EUR', 'GBP', 'INR', 'JPY', 'CNY', 'AUD', 'CAD'
  ];
  Map<String, double> _toUSD = {
    'USD': 1.0,
    'EUR': 1 / 0.92,
    'GBP': 1 / 0.78,
    'INR': 1 / 83.0,
    'JPY': 1 / 160.0,
    'CNY': 1 / 7.25,
    'AUD': 1 / 1.5,
    'CAD': 1 / 1.36,
  };
  final Map<String, double> _customScales = {};
  bool _loading = false;
  String _selectedFrom = '';
  String _selectedTo = '';

  @override
  void initState() {
    super.initState();
    _loadCustomUnits();
    _loadRates();
  }

  Future<void> _loadCustomUnits() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('customCurrencyUnits') ?? [];
    setState(() {
      for (final u in custom) {
        if (!units.contains(u)) units.add(u);
      }
    });
  }
  

  Future<void> _saveCustomUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList('customCurrencyUnits') ?? [];
    if (!custom.contains(unit)) {
      custom.add(unit);
      await prefs.setStringList('customCurrencyUnits', custom);
    }
  }

  Future<void> _loadRates() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesStr = prefs.getString('currencyRates');
    if (ratesStr != null) {
      final map = jsonDecode(ratesStr) as Map<String, dynamic>;
      setState(() {
        _toUSD = map.map((k, v) => MapEntry(k, v.toDouble()));
      });
    }
  }

  Future<void> _fetchRates() async {
    setState(() { _loading = true; });
    try {
      final url = 'https://api.exchangerate.host/latest?base=USD&access_key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final Map<String, double> toUSD = {'USD': 1.0};
        for (final u in units) {
          if (u == 'USD') continue;
          final rate = rates[u];
          if (rate != null && rate is num) {
            toUSD[u] = 1.0 / rate.toDouble();
          }
        }
        setState(() { _toUSD = toUSD; });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currencyRates', jsonEncode(_toUSD));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rates updated!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch rates.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error fetching rates.')));
    }
    setState(() { _loading = false; });
  }

  double _convert(double value, String from, String to) {
    if (from == to) return value;
    final key = _customScaleKey(from, to);
    if (_customScales.containsKey(key)) {
      // Use custom scale: 1 from = scale to
      return value * _customScales[key]!;
    }
    double usd = value * (_toUSD[from] ?? 1.0);
    return usd / (_toUSD[to] ?? 1.0);
  }

  String _scaleText(String from, String to) {
    if (from == to) return 'Same units';
    final key = _customScaleKey(from, to);
    if (_customScales.containsKey(key)) {
      final scale = _customScales[key]!;
      return 'Using custom scale: 1 $from = ${scale.toStringAsPrecision(6)} $to';
    }
    double fromToUSD = _toUSD[from] ?? 1.0;
    double toToUSD = _toUSD[to] ?? 1.0;
    double scale = fromToUSD / toToUSD;
    return 'Using scale: 1 $from = ${scale.toStringAsPrecision(6)} $to';
  }

  String _customScaleKey(String from, String to) => '$from-$to';

  Future<void> _showCustomScaleDialog(String from, String to) async {
    final key = _customScaleKey(from, to);
    double? prev = _customScales[key];
    if (prev == null) {
      double fromToUSD = _toUSD[from] ?? 1.0;
      double toToUSD = _toUSD[to] ?? 1.0;
      prev = fromToUSD / toToUSD;
    }
    final controller = TextEditingController(text: prev.toString());
    await Future.delayed(Duration(milliseconds: 50));
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Set custom scale for $from → $to'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Scale',
              hintText: prev.toString(),
            ),
            onTap: () => controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
    if (result != null && double.tryParse(result) != null) {
      setState(() {
        _customScales[key] = double.parse(result);
      });
    }
  }

  Future<void> _handleAddUnit(String newUnit) async {
    // Try to fetch the rate for the new unit directly using the /convert endpoint
    setState(() { _loading = true; });
    final code = newUnit.toUpperCase();
    try {
      final url = 'https://api.exchangerate.host/convert?from=USD&to=$code&access_key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rate = data['result'];
        if (rate != null && rate is num && rate > 0) {
          setState(() {
            units.add(code);
            _toUSD[code] = 1.0 / rate.toDouble();
          });
          await _saveCustomUnit(code);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('currencyRates', jsonEncode(_toUSD));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $code')));
          setState(() { _loading = false; });
          return;
        }
      }
    } catch (_) {}
    setState(() { _loading = false; });
    // Not found, ask user for scale
    final scale = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final TextEditingController scaleController = TextEditingController();
        return AlertDialog(
          title: Text('Enter conversion rate for $code'),
          content: TextField(
            controller: scaleController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: 'How many $code = 1 USD?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(scaleController.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (scale != null && double.tryParse(scale) != null) {
      setState(() {
        units.add(code);
        _toUSD[code] = 1.0 / double.parse(scale);
      });
      await _saveCustomUnit(code);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currencyRates', jsonEncode(_toUSD));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $code')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize selected units if not set
    if (_selectedFrom.isEmpty) _selectedFrom = units[0];
    if (_selectedTo.isEmpty) _selectedTo = units.length > 1 ? units[1] : units[0];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
            tooltip: 'Update Rates',
            onPressed: _loading ? null : _fetchRates,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: StatefulBuilder(
            builder: (context, setStateSB) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DualUnitConverter(
                    units: units,
                    scaleTextBuilder: (from, to) => _scaleText(from, to),
                    convert: _convert,
                    key: ValueKey(units.length),
                    initialUnit1: _selectedFrom,
                    initialUnit2: _selectedTo,
                    onUnitChanged: (from, to) {
                      setStateSB(() {
                        _selectedFrom = from;
                        _selectedTo = to;
                      });
                    },
                    onAddUnit: (String? newUnit) async {
                      if (newUnit != null && !units.contains(newUnit.toUpperCase())) {
                        await _handleAddUnit(newUnit);
                        setStateSB(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _showCustomScaleDialog(_selectedFrom, _selectedTo),
                    child: Card(
                      color: Colors.grey[900],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          _scaleText(_selectedFrom, _selectedTo),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
