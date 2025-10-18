import 'package:flutter/material.dart';
import 'ad_banner.dart';

class AgeCalculatorPage extends StatefulWidget {
  const AgeCalculatorPage({super.key});

  @override
  State<AgeCalculatorPage> createState() => _AgeCalculatorPageState();
}

class _AgeCalculatorPageState extends State<AgeCalculatorPage> {
  DateTime? _birthDate;
  DateTime _toDate = DateTime.now();
  String _ageText = '';

  void _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: _toDate,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _calculateAge();
      });
    }
  }

  void _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _birthDate ?? DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
        _calculateAge();
      });
    }
  }

  void _calculateAge() {
    if (_birthDate == null || _toDate.isBefore(_birthDate!)) {
      _ageText = '';
      return;
    }
    int years = _toDate.year - _birthDate!.year;
    int months = _toDate.month - _birthDate!.month;
    int days = _toDate.day - _birthDate!.day;
    if (days < 0) {
      months--;
      final prevMonth = DateTime(_toDate.year, _toDate.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    _ageText = '$years years $months months $days days';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Age Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SizedBox(width: 20,)),
            const Text('Birth Date:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickBirthDate,
                  child: Text(_birthDate == null ? 'Select Date' : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Calculate age up to:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _birthDate == null ? null : _pickToDate,
                  child: Text('${_toDate.year}-${_toDate.month.toString().padLeft(2, '0')}-${_toDate.day.toString().padLeft(2, '0')}'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_birthDate != null && _ageText.isNotEmpty)
              Center(child: Text('Age:', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),),
              Text(_ageText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Expanded(child: SizedBox(width: 20,)),
          ],
        ),
      ),
      //bottomNavigationBar: const AdBanner(),
    );
  }
}
