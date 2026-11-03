import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/android_soft_keyboard.dart';

void main() {
  final sentinel = '1' * 1024;

  test('Samsung Hangul commits survive composing-only changes', () {
    var previous = sentinel;
    var remote = '';
    void apply(String text, TextRange composing) {
      final edit = computeAndroidSoftKeyboardEdit(previous,
          TextEditingValue(text: sentinel + text, composing: composing));
      remote = String.fromCharCodes(remote.runes
              .take(remote.runes.length - edit.deleteCount)) +
          edit.insertedText;
      previous = edit.committedText;
    }
    apply('ㄱ', TextRange(start: 1024, end: 1025));
    expect(remote, '');
    apply('가', TextRange(start: 1024, end: 1025));
    expect(remote, '');
    apply('가', TextRange.empty);
    expect(remote, '가');
    apply('가ㄴ', TextRange(start: 1025, end: 1026));
    apply('가나', TextRange(start: 1025, end: 1026));
    apply('가나다', TextRange(start: 1026, end: 1027));
    apply('가나다', TextRange.empty);
    expect(remote, '가나다');
  });

  test('backspace before typing preserves the sentinel and corrects text', () {
    final back = computeAndroidSoftKeyboardEdit(sentinel,
        TextEditingValue(text: sentinel.substring(1)));
    expect(back.deleteCount, 1);
    expect(back.insertedText, '');
    final typed = computeAndroidSoftKeyboardEdit(back.committedText,
        TextEditingValue(text: back.committedText + 'abc 가나다'));
    expect(typed.insertedText, 'abc 가나다');
    final corrected = computeAndroidSoftKeyboardEdit(sentinel + 'ㄱ',
        TextEditingValue(text: sentinel + '가'));
    expect(corrected.deleteCount, 1);
    expect(corrected.insertedText, '가');
  });

  testWidgets('soft editor keys never reach remote physical-key handler',
      (tester) async {
    var remoteKeys = 0;
    await tester.pumpWidget(MaterialApp(home: Focus(
      onKeyEvent: (_, __) {
        remoteKeys++;
        return KeyEventResult.handled;
      },
      child: const AndroidSoftKeyboardBoundary(
          child: Material(child: TextField(autofocus: true))),
    )));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(remoteKeys, 0);
  });
}
