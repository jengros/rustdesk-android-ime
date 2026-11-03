import 'package:flutter/widgets.dart';

class AndroidSoftKeyboardEdit {
  final String committedText;
  final int deleteCount;
  final String insertedText;

  const AndroidSoftKeyboardEdit(
      this.committedText, this.deleteCount, this.insertedText);
}

AndroidSoftKeyboardEdit computeAndroidSoftKeyboardEdit(
    String previous, TextEditingValue value) {
  final composing = value.composing;
  final current = value.isComposingRangeValid && !composing.isCollapsed
      ? value.text.replaceRange(composing.start, composing.end, '')
      : value.text;
  // A paste can replace the whole hidden sentinel buffer.
  if (previous.startsWith('1') &&
      current.isNotEmpty &&
      !current.startsWith('1')) {
    previous = '';
  }
  final before = previous.runes.toList();
  final after = current.runes.toList();
  var common = 0;
  while (common < before.length &&
      common < after.length &&
      before[common] == after[common]) {
    common++;
  }
  return AndroidSoftKeyboardEdit(current, before.length - common,
      String.fromCharCodes(after.skip(common)));
}

// Keep IME key events out of the remote physical-key handler while allowing
// Android to perform the edit. Returning handled would swallow some IME edits.
class AndroidSoftKeyboardBoundary extends StatelessWidget {
  final Widget child;

  const AndroidSoftKeyboardBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Focus(
      onKeyEvent: (_, __) => KeyEventResult.skipRemainingHandlers,
      child: child);
}
