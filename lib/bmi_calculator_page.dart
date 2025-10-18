import 'package:flutter/material.dart';
import 'ad_banner.dart';

class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({super.key});

  @override
  State<BMICalculatorPage> createState() => _BMICalculatorPageState();
}

class _BMICalculatorPageState extends State<BMICalculatorPage> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final FocusNode weightFocus = FocusNode();
  final FocusNode heightFocus = FocusNode();

  String weightUnit = 'kg';
  String heightUnit = 'inch';

  double? get _weight {
    final w = double.tryParse(weightController.text);
    if (w == null) return null;
    return weightUnit == 'kg' ? w : w * 0.45359237;
  }

  double? get _height {
    final h = double.tryParse(heightController.text);
    if (h == null) return null;
    return heightUnit == 'cm' ? h / 100 : h * 0.0254;
  }

  double? get _bmi {
    final w = _weight;
    final h = _height;
    if (w == null || h == null || h == 0) return null;
    return w / (h * h);
  }

  String get _bmiCategory {
    final bmi = _bmi;
    if (bmi == null) return '';
    if (bmi < 16) return 'Severe Thinness';
    if (bmi < 17) return 'Moderate Thinness';
    if (bmi < 18.5) return 'Mild Thinness';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    if (bmi < 35) return 'Obese Class I';
    if (bmi < 40) return 'Obese Class II';
    return 'Obese Class III';
  }

  Color get _bmiColor {
    final bmi = _bmi;
    if (bmi == null) return Colors.grey;
    if (bmi < 16) return Colors.red.shade900;
    if (bmi < 17) return Colors.red;
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.yellow.shade700;
    if (bmi < 35) return Colors.orange.shade700;
    if (bmi < 40) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    weightFocus.addListener(() {
      if (weightFocus.hasFocus) {
        weightController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: weightController.text.length,
        );
      }
    });
    heightFocus.addListener(() {
      if (heightFocus.hasFocus) {
        heightController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: heightController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    weightFocus.dispose();
    heightFocus.dispose();
    super.dispose();
  }

  Widget _inputRow({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String unit,
    required List<String> units,
    required ValueChanged<String?> onUnitChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.black,
              iconEnabledColor: Colors.white,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              value: unit,
              items: units
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: onUnitChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bmiBar() {
    final bmi = _bmi ?? 0;
    final ranges = [16, 17, 18.5, 25, 30, 35, 40];
    final colors = [
      Colors.red.shade900,
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.yellow.shade700,
      Colors.orange.shade700,
      Colors.deepOrange,
      Colors.red,
    ];
    final labels = [
      '<16',
      '16-17',
      '17-18.5',
      '18.5-25',
      '25-30',
      '30-35',
      '35-40',
      '>40',
    ];
    int idx = ranges.indexWhere((r) => bmi < r);
    if (idx == -1) idx = ranges.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Standard Scale',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(colors.length, (i) {
            return Expanded(
              child: Container(
                height: 24,
                color: colors[i],
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: i == idx ? Colors.black : Colors.white,
                      fontWeight: i == idx
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BMI Calculator')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputRow(
                label: 'Weight',
                controller: weightController,
                focusNode: weightFocus,
                unit: weightUnit,
                units: const ['kg', 'lb'],
                onUnitChanged: (u) => setState(() => weightUnit = u ?? 'kg'),
              ),
              const SizedBox(height: 16),
              _inputRow(
                label: 'Height',
                controller: heightController,
                focusNode: heightFocus,
                unit: heightUnit,
                units: const ['cm', 'inch'],
                onUnitChanged: (u) => setState(() => heightUnit = u ?? 'cm'),
              ),
              const SizedBox(height: 24),
              Text(
                _bmi == null
                    ? 'BMI: '
                    : 'BMI: ${_bmi!.toStringAsFixed(2)} ($_bmiCategory)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _bmiColor,
                ),
              ),
              const SizedBox(height: 24),
              _bmiBar(),
            ],
          ),
        ),
      ),
      //bottomNavigationBar: const AdBanner(),
    );
  }
}
