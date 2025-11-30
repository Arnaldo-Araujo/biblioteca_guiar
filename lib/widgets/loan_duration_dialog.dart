import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoanDurationDialog extends StatefulWidget {
  final String title;
  final String confirmText;

  const LoanDurationDialog({
    super.key,
    this.title = 'Definir Prazo',
    this.confirmText = 'CONFIRMAR',
  });

  @override
  State<LoanDurationDialog> createState() => _LoanDurationDialogState();
}

class _LoanDurationDialogState extends State<LoanDurationDialog> {
  int _selectedDays = 7; // Default
  DateTime _calculatedDate = DateTime.now().add(const Duration(days: 7));

  void _updateDate(int days) {
    setState(() {
      _selectedDays = days;
      _calculatedDate = DateTime.now().add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Escolha o período do empréstimo:'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            children: [
              ChoiceChip(
                label: const Text('7 Dias'),
                selected: _selectedDays == 7,
                onSelected: (selected) {
                  if (selected) _updateDate(7);
                },
              ),
              ChoiceChip(
                label: const Text('14 Dias'),
                selected: _selectedDays == 14,
                onSelected: (selected) {
                  if (selected) _updateDate(14);
                },
              ),
              ChoiceChip(
                label: const Text('21 Dias'),
                selected: _selectedDays == 21,
                onSelected: (selected) {
                  if (selected) _updateDate(21);
                },
              ),
              ChoiceChip(
                label: const Text('30 Dias'),
                selected: _selectedDays == 30,
                onSelected: (selected) {
                  if (selected) _updateDate(30);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Devolução prevista para:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        dateFormat.format(_calculatedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _selectedDays);
          },
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
