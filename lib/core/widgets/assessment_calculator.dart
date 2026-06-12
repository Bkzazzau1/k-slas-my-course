import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AssessmentCalculatorButton extends StatelessWidget {
  const AssessmentCalculatorButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton.filledTonal(
        tooltip: 'Calculator',
        onPressed: () => AssessmentCalculatorDialog.show(),
        icon: const Icon(Icons.calculate_rounded),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => AssessmentCalculatorDialog.show(),
      icon: const Icon(Icons.calculate_rounded),
      label: const Text('Calculator'),
    );
  }
}

class AssessmentCalculatorDialog extends StatefulWidget {
  const AssessmentCalculatorDialog({super.key});

  static Future<void> show() {
    return Get.dialog<void>(
      const AssessmentCalculatorDialog(),
      barrierDismissible: true,
    );
  }

  @override
  State<AssessmentCalculatorDialog> createState() => _AssessmentCalculatorDialogState();
}

class _AssessmentCalculatorDialogState extends State<AssessmentCalculatorDialog> {
  String display = '0';
  double? stored;
  String? op;
  bool replaceNext = false;

  void press(String value) {
    setState(() {
      if (display == 'Error') {
        display = '0';
        stored = null;
        op = null;
      }
      if (value == 'C') {
        display = '0';
        stored = null;
        op = null;
        replaceNext = false;
        return;
      }
      if (value == 'DEL') {
        if (replaceNext || display.length <= 1) {
          display = '0';
          replaceNext = false;
        } else {
          display = display.substring(0, display.length - 1);
        }
        return;
      }
      if (value == '.') {
        if (replaceNext) {
          display = '0.';
          replaceNext = false;
        } else if (!display.contains('.')) {
          display += '.';
        }
        return;
      }
      if ('0123456789'.contains(value)) {
        if (replaceNext || display == '0') {
          display = value;
          replaceNext = false;
        } else {
          display += value;
        }
        return;
      }
      if (value == '+/-') {
        if (display != '0') display = display.startsWith('-') ? display.substring(1) : '-$display';
        return;
      }
      if (value == '=') {
        calculate();
        op = null;
        stored = null;
        replaceNext = true;
        return;
      }
      if (['+', '-', '*', '/'].contains(value)) {
        if (stored != null && op != null && !replaceNext) calculate();
        stored = double.tryParse(display);
        op = value;
        replaceNext = true;
      }
    });
  }

  void calculate() {
    final current = double.tryParse(display);
    if (stored == null || current == null || op == null) return;
    double result;
    switch (op) {
      case '+':
        result = stored! + current;
        break;
      case '-':
        result = stored! - current;
        break;
      case '*':
        result = stored! * current;
        break;
      case '/':
        result = current == 0 ? double.nan : stored! / current;
        break;
      default:
        result = current;
    }
    if (result.isNaN || result.isInfinite) {
      display = 'Error';
      return;
    }
    display = formatNumber(result);
  }

  String formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    final fixed = value.toStringAsFixed(8);
    return fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final buttons = ['C', 'DEL', '+/-', '/', '7', '8', '9', '*', '4', '5', '6', '-', '1', '2', '3', '+', '0', '.', '='];

    return AlertDialog(
      title: const Text('Assessment calculator'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              itemCount: buttons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, index) {
                final label = buttons[index];
                return FilledButton.tonal(
                  onPressed: () => press(label),
                  child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back<void>(), child: const Text('Close')),
      ],
    );
  }
}
