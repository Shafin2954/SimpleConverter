import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ad_banner.dart';

class CreateCustomConverterPage extends StatefulWidget {
  const CreateCustomConverterPage({super.key});

  @override
  State<CreateCustomConverterPage> createState() =>
      _CreateCustomConverterPageState();
}

class _CreateCustomConverterPageState extends State<CreateCustomConverterPage> {
  final List<TextEditingController> _valueControllers = [];
  final List<TextEditingController> _dialogLabelControllers = [];
  final FocusNode _formulaFocus = FocusNode();
  final TextEditingController _formulaController = TextEditingController();
  final TextEditingController _nameDialogController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start with two fields (for A and B) by default
    _addField();
    _addField();
  }

  @override
  void dispose() {
    // Dispose all our controllers
    _formulaController.dispose();
    _formulaFocus.dispose();
    _nameDialogController.dispose();
    for (var controller in _valueControllers) {
      controller.dispose();
    }
    for (var controller in _dialogLabelControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() {
      _valueControllers.add(TextEditingController());
    });
  }

  void _removeField(int index) {
    // Prevent removing all fields; we need at least one
    if (_valueControllers.length > 1) {
      setState(() {
        // Dispose controller before removing
        _valueControllers[index].dispose();
        _valueControllers.removeAt(index);
      });
    }
  }

  // Helper to get the letter for an index (0=A, 1=B, ...)
  String _getLetterForIndex(int index) {
    return String.fromCharCode('A'.codeUnitAt(0) + index);
  }

  // Helper to get all available unit letters (A, B, C...)
  List<String> _getUnitList() {
    List<String> units = [];
    for (int i = 0; i < _valueControllers.length; i++) {
      units.add(_getLetterForIndex(i));
    }
    return units;
  }

  double? _calculateResult() {
    if (_formulaController.text.trim().isEmpty) {
      return null;
    }

    try {
      final parser = Parser();
      final exp = parser.parse(_formulaController.text);
      final ctx = ContextModel();

      for (int i = 0; i < _valueControllers.length; i++) {
        final label = _getLetterForIndex(i);
        final valueText = _valueControllers[i].text.trim();
        final value = double.tryParse(valueText) ?? 0.0;
        ctx.bindVariable(Variable(label), Number(value));
      }

      return exp.evaluate(EvaluationType.REAL, ctx);
    } catch (e) {
      return null;
    }
  }

  Future<void> _showSaveDialog() async {
    if (_formulaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a formula before saving.')),
      );
      return;
    }

    // --- PREPARE CONTROLLERS FOR THE DIALOG ---
    _nameDialogController.clear();
    // Dispose any old controllers and create new ones for the current number of variables
    for (var controller in _dialogLabelControllers) {
      controller.dispose();
    }
    _dialogLabelControllers.clear();
    for (int i = 0; i < _valueControllers.length; i++) {
      _dialogLabelControllers.add(TextEditingController());
    }

    // --- SHOW THE NEW, MORE ADVANCED DIALOG ---
    final Map<String, dynamic>? resultData =
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Converter'),
          backgroundColor: Colors.white,
          // Use a scrollable view in case of many variables
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Field for the converter's name
                TextField(
                  controller: _nameDialogController,
                  decoration: const InputDecoration(
                    labelText: "Converter Name",
                    labelStyle: TextStyle(color: Colors.black),
                    hintText: "e.g., 'Total Rent'",
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                const Text('Enter descriptive names for variables:'),
                const SizedBox(height: 8),
                // Generate a list of TextFields for each variable
                ...List.generate(_valueControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: _dialogLabelControllers[index],
                      decoration: InputDecoration(
                        labelText: "Name for ${_getLetterForIndex(index)}",
                        labelStyle: TextStyle(color: Colors.black),
                        hintText: "e.g., 'grams', 'cups'",
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                // --- GATHER THE DATA FROM THE DIALOG ---
                final converterName = _nameDialogController.text;
                final labels = _dialogLabelControllers.map((controller) {
                  // Use the descriptive name, or default to the letter (A, B...) if empty
                  final text = controller.text.trim();
                  final index = _dialogLabelControllers.indexOf(controller);
                  return text.isNotEmpty ? text : _getLetterForIndex(index);
                }).toList();

                if (converterName.isNotEmpty) {
                  // Return a map containing all the data
                  Navigator.of(context).pop({
                    'name': converterName,
                    'labels': labels,
                  });
                }
              },
            ),
          ],
        );
      },
    );

    // --- PASS THE FINAL DATA BACK TO THE HOME PAGE ---
    if (resultData != null) {
      final newConverterData = {
        'name': resultData['name'],
        'labels': resultData['labels'], // The descriptive names from the dialog
        'formula': _formulaController.text.trim(),
        'numFields': _valueControllers.length,
      };
      // Pop the page and return the data
      Navigator.of(context).pop(newConverterData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _calculateResult();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Formula Converter',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _showSaveDialog,
            tooltip: 'Save Converter',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                // Add 2 extra items: one for the formula, one for the result
                itemCount: _valueControllers.length + 2,
                itemBuilder: (context, index) {
                  // --- Build the dynamic variable fields (A, B, C...) ---
                  if (index < _valueControllers.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${_getLetterForIndex(index)}:',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _valueControllers[index],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                hintText: 'Enter value',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _removeField(index),
                          ),
                        ],
                      ),
                    );
                  }
                  // --- Build the formula input field ---
                  else if (index == _valueControllers.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _addField,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Variable'),
                              ),
                            ),
                          ),
                          TextField(
                            controller: _formulaController,
                            focusNode: _formulaFocus,
                            decoration: InputDecoration(
                              labelText: 'Formula',
                              hintText: 'e.g., (A + B) / 2',
                              border: const OutlineInputBorder(),
                              helperText:
                              'Use variables: ${_getUnitList().join(', ')}',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 25),
                        ],
                      )
                    );
                  }
                  // --- Build the result display box ---
                  else {
                    return Text(
                        'Result: ${result != null ? result.toStringAsFixed(4) : '...'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                    );
                  }
                },
              ),
            ),
            // --- "Add Variable" Button at the very bottom ---

          ],
        ),
      ),
      //bottomNavigationBar: const AdBanner(),
    );
  }
}
