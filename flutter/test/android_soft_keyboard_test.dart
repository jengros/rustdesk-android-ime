import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/android_soft_keyboard.dart';

void main() {
  testWidgets('Hangul composition is visible without space and no filler leaks',
      (tester) async {
    var remote = '';
    await tester.pumpWidget(MaterialApp(home: Material(
      child: AndroidSoftKeyboardInput(
        onText: (text) => remote += text,
        onBackspace: () => remote = remote.characters.skipLast(1).join(),
        onEnter: () => remote += '\n',
      ),
    )));
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty);
    for (final text in ['a', 'ab', 'abc ', 'abc ㄱ', 'abc 가',
      'abc 가ㄴ', 'abc 가나', 'abc 가나ㄷ', 'abc 가나다']) {
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
        composing: TextRange(start: text.length - 1, end: text.length),
      ));
      await tester.pump();
      expect(remote, text);
    }
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'abc 가나다', selection: TextSelection.collapsed(offset: 7)));
    await tester.pump();
    expect(remote, 'abc 가나다');
  });

  testWidgets('raw Backspace deletes existing and locally typed remote text',
      (tester) async {
    var remote = '기존';
    await tester.pumpWidget(MaterialApp(home: Material(
      child: AndroidSoftKeyboardInput(
        onText: (text) => remote += text,
        onBackspace: () => remote = remote.characters.skipLast(1).join(),
        onEnter: () => remote += '\n',
      ),
    )));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(remote, '기');
    await tester.enterText(find.byType(TextField), 'abc 가나다');
    expect(remote, '기abc 가나다');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(remote, '기abc 가나');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(remote, '기abc 가');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(remote, '기abc 가\n');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(remote, '기abc 가');
  });

  testWidgets('held Delete and Enter run once per event and real 1 is preserved',
      (tester) async {
    var remote = 'abcdef';
    var remoteKeys = 0;
    await tester.pumpWidget(MaterialApp(home: Material(child: Focus(
      onKeyEvent: (_, __) {
        remoteKeys++;
        return KeyEventResult.handled;
      },
      child: AndroidSoftKeyboardInput(
        onText: (text) => remote += text,
        onBackspace: () => remote = remote.characters.skipLast(1).join(),
        onEnter: () => remote += '\n',
      ),
    ))));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);
    expect(remote, 'abc');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.enterText(find.byType(TextField), '1');
    expect(remote, 'abc\n1');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(remoteKeys, 0);
  });
}
