import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'length_converter_page.dart';
import 'weight_converter_page.dart';
import 'temperature_converter_page.dart';
import 'speed_converter_page.dart';
import 'volume_converter_page.dart';
import 'bmi_calculator_page.dart';
import 'create_custom_converter_page.dart';
import 'age_calculator_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:math_expressions/math_expressions.dart';
import 'package:http/http.dart' as http;
import 'area_converter_page.dart';
import 'base_converter_page.dart';
import 'grades_calculator_page.dart';
import 'ad_banner.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Converter',
      theme: ThemeData(
        fontFamily: 'CourierPrime',
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: AppBarTheme(
          // Remove const to use copyWith
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          // FIX: Start with the default app bar title style and modify it
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            // FIX: Inherit the default font family and only override the weight
            textStyle: const TextStyle().copyWith(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
        textTheme: Typography.englishLike2021
            .apply(fontFamily: 'CourierPrime')
            .copyWith(
              bodyLarge: const TextStyle(color: Colors.black),
              bodyMedium: const TextStyle(
                color: Colors.black,
              ), // This will now have CourierPrime
              bodySmall: const TextStyle(color: Colors.black),
            ),

        iconTheme: const IconThemeData(color: Colors.black),
        dividerColor: Colors.black12,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Simple Converter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool featureSent = false;
  bool featureSending = false;
  final TextEditingController featureController = TextEditingController();
  List<Map<String, dynamic>> customConverters = [];

  @override
  void initState() {
    super.initState();
    _loadCustomConverters();
  }

  @override
  void dispose() {
    featureController.dispose();
    super.dispose();
  }

  Future<bool> sendFeatureRequest(String feedback) async {
    const String scriptUrl =
        'https://script.google.com/macros/s/AKfycbyiA6hUuJovOOkaOLUDCJ82hyYiIae1rRcA-V69uOfzAqZDY3uA-oYH_ACmchcdHDLd/exec';
    if (scriptUrl.startsWith('YOUR_')) {
      return false;
    }
    try {
      final uri = Uri.parse(scriptUrl);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': feedback,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      // Accept any 2xx status code as success, and also treat empty or non-JSON responses as success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      // Some Apps Script deployments return 302 or 0, but the message is still delivered
      if (response.statusCode == 0 || response.statusCode == 302) {
        return true;
      }
      // If the response body contains 'success', treat as success
      if (response.body.toLowerCase().contains('success')) {
        return true;
      }
      return false;
    } catch (e) {
      // If the request completes without exception, treat as success
      return true;
    }
  }

  Future<void> _loadCustomConverters() async {
    final prefs = await SharedPreferences.getInstance();
    final converterStrings = prefs.getStringList('customConverters') ?? [];
    final List<Map<String, dynamic>> loadedConverters = [];

    for (final str in converterStrings) {
      // Decode the saved string into a map
      final Map<String, dynamic> data = jsonDecode(str);

      // --- THIS IS THE CRUCIAL FIX ---
      // Check if the 'variables' key is missing or null.
      // This can happen with converters saved before the fix.
      if (data['variables'] == null) {
        // If it's missing, regenerate it from 'numFields'
        final int numFields = data['numFields'] ?? 0;
        data['variables'] = List.generate(
          numFields,
          (index) => String.fromCharCode('A'.codeUnitAt(0) + index),
        );
      }
      // ---------------------------------

      loadedConverters.add(data);
    }

    setState(() {
      customConverters = loadedConverters;
    });
  }

  // void _navigateToCustomConverter(Map<String, dynamic> data) async {
  //   // Wait for the result from the runner page.
  //   // It will return 'true' if the converter was deleted.
  //   final result = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => CustomConverterRunnerPage(data: data),
  //     ),
  //   );
  //
  //   // If the result is true, it means a deletion happened.
  //   // We need to reload the converters to update the UI.
  //   if (result == true) {
  //     _loadCustomConverters();
  //   }
  // }

  Future<void> _saveCustomConverters() async {
    final prefs = await SharedPreferences.getInstance();
    final list = customConverters.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('customConverters', list);
  }

  Future<void> _deleteCustomConverter(String name) async {
    setState(() {
      // Remove the converter from the list by its name
      customConverters.removeWhere((converter) => converter['name'] == name);
    });
    // Save the updated list to SharedPreferences
    await _saveCustomConverters();
  }

  void _navigateToConverter(BuildContext context, String title) async {
    // Special case for creating a new converter remains the same
    if (title == 'Create New') {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateCustomConverterPage(),
        ),
      );

      if (result != null && mounted) {
        // Get all the data from the result map
        final String name = result['name'];
        final String formula = result['formula'];
        final int numFields = result['numFields'];
        final List<String> labels = result['labels']; // <-- Get the labels

        // Generate the internal variable names (A, B, C...)
        final List<String> variables = List.generate(
          numFields,
          (index) => String.fromCharCode('A'.codeUnitAt(0) + index),
        );

        setState(() {
          final newConverterData = {
            'name': name,
            'numFields': numFields,
            'formula': formula,
            'variables': variables,
            'labels': labels, // <-- FIX: Add the labels to the data being saved
          };

          // This part for updating or adding the new converter remains the same
          final existingIndex = customConverters.indexWhere(
            (e) => e['name'] == name,
          );
          if (existingIndex != -1) {
            customConverters[existingIndex] = newConverterData;
          } else {
            customConverters.add(newConverterData);
          }

          _saveCustomConverters();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved "$name"!')));
        });
      }
      return;
    }

    Widget? page;

    switch (title) {
      case 'Length':
        page = const LengthConverterPage();
        break;
      case 'Weight':
        page = const WeightConverterPage();
        break;
      case 'Temperature':
        page = const TemperatureConverterPage();
        break;
      case 'Speed':
        page = const SpeedConverterPage();
        break;
      case 'Volume':
        page = const VolumeConverterPage();
        break;
      case 'Area':
        page = AreaConverterPage();
        break;
      case 'Base Converter':
        page = const BaseConverterPage();
        break;
      case 'Grades Calculator':
        page = const GradesCalculatorPage();
        break;
      case 'BMI Calculator':
        page = const BMICalculatorPage();
        break;
      case 'Age Calculator':
        page = const AgeCalculatorPage();
        break;

      default:
        final customData = customConverters.firstWhere(
          (e) => e['name'] == title,
          orElse: () => <String, dynamic>{},
        );
        if (customData.isNotEmpty) {
          // --- MODIFICATION HERE ---
          // Pass the _deleteCustomConverter function to the runner page
          page = CustomConverterRunnerPage(
            data: customData,
            onDelete: () =>
                _deleteCustomConverter(title), // Pass the delete handler
          );
        } else {
          page = Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(child: Text('$title page coming soon!')),
          );
        }
        break;
    }

    if (page != null) {
      // We no longer need to check for a result, just navigate
      Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> gridTiles = [
      _buildConverterTile(context, 'Length', Icons.straighten, Colors.blue),
      _buildConverterTile(
        context,
        'Weight',
        Icons.monitor_weight_outlined,
        Colors.green,
      ),
      _buildConverterTile(
        context,
        'Temperature',
        Icons.thermostat,
        Colors.orange,
      ),
      _buildConverterTile(context, 'Speed', Icons.speed, Colors.red),
      _buildConverterTile(context, 'Volume', Icons.water_drop, Colors.purple),
      _buildConverterTile(
        context,
        'Area',
        Icons.crop_square,
        Colors.deepOrange,
      ),
      _buildConverterTile(
        context,
        'Base Converter',
        Icons.memory,
        Colors.blueGrey,
      ),
      _buildConverterTile(
        context,
        'Grades Calculator',
        Icons.school,
        Colors.teal,
      ),
      //_buildConverterTile(context, 'Currency', Icons.attach_money, Colors.teal),
      _buildConverterTile(
        context,
        'BMI Calculator',
        Icons.fitness_center,
        Colors.indigo,
      ),
      _buildConverterTile(
        context,
        'Age Calculator',
        Icons.cake,
        Colors.deepPurple,
      ),
      _buildConverterTile(
        context,
        'Create New',
        Icons.add_circle_outline,
        Colors.brown,
      ),
      ...customConverters.map((data) => _buildCustomTile(context, data)),
    ];

    // --- UI layout fix: move feedback button and card OUTSIDE the grid ---

    // --- Feedback button and card as scrollable grid items ---
    // Removed unused gridTilesWithFeedback variable

    return Scaffold(
      appBar: AppBar(
        // FIX: Explicitly use the AppBar's title text style from the theme
        title: Text(
          widget.title,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 32,
                crossAxisSpacing: 20,
                childAspectRatio: 0.95,
                shrinkWrap: true, // Important!
                physics: const NeverScrollableScrollPhysics(), // Important!
                children: gridTiles,
              ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: 320,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.feedback),
                    label: const Text(
                      'Ask for Features',
                    ), // Added const for performance
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(
                        fontFamily: 'CourierPrime',
                        fontWeight: FontWeight.bold,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      // Reset state before showing dialog
                      setState(() {
                        featureSending = false;
                        featureController.clear();
                      });

                      await showDialog<bool>(
                        context: context,
                        barrierDismissible:
                            false, // Prevent dismissing by tapping outside
                        builder: (BuildContext dialogContext) => StatefulBuilder(
                          builder: (context, setDialogState) => AlertDialog(
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ),
                            title: Text(
                              featureSent
                                  ? 'Thanks for reaching out!'
                                  : 'Request a Feature',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            content: SizedBox(
                              width: 400,
                              child: featureSent
                                  ? const Text(
                                      'Your feedback has been sent. We appreciate your input.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'You can request for more features in the app!',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: featureController,
                                          minLines: 2,
                                          maxLines: 5,
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              232,
                                              232,
                                              232,
                                            ),
                                          ),
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Type your feature request here...',
                                            hintStyle: TextStyle(
                                              color: Color.fromARGB(
                                                137,
                                                222,
                                                222,
                                                222,
                                              ),
                                            ),
                                            border: OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Color.fromARGB(
                                              255,
                                              0,
                                              0,
                                              0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            actions: [
                              if (featureSent)
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(true);
                                  },
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Color.fromARGB(179, 0, 0, 0),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: featureSending
                                          ? null
                                          : () async {
                                              final text = featureController
                                                  .text
                                                  .trim();
                                              if (text.isEmpty) return;

                                              setDialogState(() {
                                                featureSending = true;
                                              });

                                              final success =
                                                  await sendFeatureRequest(
                                                    text,
                                                  );

                                              if (!context.mounted) return;

                                              if (success) {
                                                setDialogState(() {
                                                  featureSending = false;
                                                  featureSent = true;
                                                });
                                              } else {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop(false);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Failed to send. Please try again.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                      child: featureSending
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Send',
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );

                      // Reset state after dialog closes
                      if (mounted) {
                        setState(() {
                          featureSent = false;
                          featureSending = false;
                          featureController.clear();
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConverterTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToConverter(context, title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTile(BuildContext context, Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToConverter(context, data['name'] as String),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: Text(
              data['name'] ?? 'Custom',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomConverterRunnerPage extends StatefulWidget {
  final Map<String, dynamic> data;

  final Future<void> Function()?
  onDelete; // --- NEW: Accept the onDelete function ---

  const CustomConverterRunnerPage({
    super.key,
    required this.data,
    this.onDelete, // --- NEW: Add to constructor ---
  });

  @override
  State<CustomConverterRunnerPage> createState() =>
      _CustomConverterRunnerPageState();
}

class _CustomConverterRunnerPageState extends State<CustomConverterRunnerPage> {
  late final List<TextEditingController> _controllers;
  double? _result;

  @override
  void initState() {
    super.initState();
    // Initialize a controller for each variable defined in the data
    _controllers = List.generate(
      (widget.data['variables'] as List).length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    final formula = widget.data['formula'];
    if (formula == null || formula.trim().isEmpty) {
      setState(() => _result = null);
      return;
    }

    try {
      final parser = Parser();
      final exp = parser.parse(formula);
      final ctx = ContextModel();

      // Bind all variables from their controllers
      for (int i = 0; i < _controllers.length; i++) {
        final label = (widget.data['variables'] as List)[i];
        final valueText = _controllers[i].text.trim();
        final value = double.tryParse(valueText) ?? 0.0;
        ctx.bindVariable(Variable(label), Number(value));
      }

      setState(() {
        _result = exp.evaluate(EvaluationType.REAL, ctx);
      });
    } catch (e) {
      setState(() => _result = null);
    }
  }

  Future<void> _deleteConverter() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete Converter'),
          content: const Text(
            'Are you sure you want to delete this converter? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    // If the user confirmed and the onDelete callback exists
    if (confirmed == true && widget.onDelete != null) {
      // Call the function that was passed from the home screen
      await widget.onDelete!();

      // Pop the page to return to the updated home screen
      if (mounted) {
        Navigator.of(context).pop(); // No need to return 'true' anymore
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- THIS IS THE FIX ---
    // Get the DESCRIPTIVE LABELS from the data. Fall back to variables (A, B...) if they don't exist.
    final List<dynamic> displayLabels =
        widget.data['labels'] ?? widget.data['variables'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.data['name'] ?? 'Custom Converter',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          // --- REVISED: The delete button ---
          // Only show the delete button if the onDelete function was provided
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Converter',
              onPressed: _deleteConverter,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          // Use the length of the labels list + 1 for the result
          itemCount: displayLabels.length + 1,
          itemBuilder: (context, index) {
            // --- If it's the last item, build the result box ---
            if (index == displayLabels.length) {
              return Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Result: ${_result != null ? _result!.toStringAsFixed(4) : '...'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            // --- Otherwise, build the variable input fields ---
            // Use the correct label from the displayLabels list
            final descriptiveLabel = displayLabels[index] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                controller: _controllers[index],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  // Display the descriptive label here
                  labelText: descriptiveLabel,
                  hintText: 'Enter value for $descriptiveLabel',
                ),
                onChanged: (_) => _calculate(),
              ),
            );
          },
        ),
      ),
      //bottomNavigationBar: const AdBanner(),
    );
  }
}
