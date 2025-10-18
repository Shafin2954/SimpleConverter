import 'package:flutter/material.dart';
import 'ad_banner.dart';

class GradesCalculatorPage extends StatefulWidget {
  const GradesCalculatorPage({super.key});

  @override
  State<GradesCalculatorPage> createState() => _GradesCalculatorPageState();
}

class _GradesCalculatorPageState extends State<GradesCalculatorPage> {
  final List<TextEditingController> _controllers = [];
  double _average = 0.0;

  @override
  void initState() {
    super.initState();
    // Start with 2 fields by default
    _addField();
    _addField();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addField() {
    final controller = TextEditingController();
    controller.addListener(_calculateAverage);
    setState(() {
      _controllers.add(controller);
    });
  }

  void _removeField(int index) {
    _controllers[index].dispose();
    setState(() {
      _controllers.removeAt(index);
      _calculateAverage();
    });
  }

  void _calculateAverage() {
    double sum = 0;
    int count = 0;

    for (var controller in _controllers) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        final grade = double.tryParse(text);
        if (grade != null) {
          sum += grade;
          count++;
        }
      }
    }

    setState(() {
      _average = count > 0 ? sum / count : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grades Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        // We will no longer use a Column here, the ListView will manage everything.
        child: ListView.builder(
          // The item count is the number of fields + the button + the result text
          itemCount: _controllers.length + 2,
          itemBuilder: (context, index) {
            // --- 1. Build the TextFields ---
            if (index < _controllers.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      'Subject ${(index + 1).toString().padLeft(2, '0')}:',
                      // Use copyWith to inherit the font family
                      style: const TextStyle().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controllers[index],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        // The TextField will correctly inherit the font from the theme
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          hintText: 'Enter grade',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeField(index),
                      color: Colors.red,
                    ),
                  ],
                ),
              );
            }
            // --- 2. Build the "Add Subject" Button ---
            else if (index == _controllers.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0), // Add spacing
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subject'),
                    // The style will be correctly inherited from your ElevatedButtonTheme
                  ),
                ),
              );
            }
            // --- 3. Build the Average Result Text ---
            else {
              return Column(
                  children: [
                    SizedBox(height: 20,),
                    Text(
                  'Average: ${_average.toStringAsFixed(2)}',
                  // Use copyWith to inherit the font family
                  style: const TextStyle().copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
              ),]
              );
            }
          },
        ),
      ),
      //bottomNavigationBar: const AdBanner(),
    );
  }
}