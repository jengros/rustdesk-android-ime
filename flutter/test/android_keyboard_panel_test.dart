import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/android_keyboard_panel.dart';

void main() {
  testWidgets('local composition sends once on keyboard submit without Enter',
      (tester) async {
    final draft = TextEditingController();
    final focus = FocusNode();
    final sent = <String>[];
    final completion = Completer<void>();
    var remoteKeys = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: AndroidKeyboardPanel(
        buffered: true,
        enabled: true,
        onModeChanged: (_) {},
        draft: draft,
        focusNode: focus,
        onSubmit: (text) async {
          sent.add(text);
          await completion.future;
          draft.clear();
        },
        onText: (_) => fail('Buffered editing must not send live text'),
        onBackspace: () => remoteKeys++,
        onEnter: () => remoteKeys++,
      ),
    )));
    await tester.pump();
    for (final text in ['abc ㄱ', 'abc 가', 'abc 가나다']) {
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
        composing: TextRange(start: 4, end: text.length),
      ));
      await tester.pump();
    }
    expect(sent, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    expect(sent, ['abc 가나다']);
    expect(remoteKeys, 0);
    completion.complete();
    await tester.pump();
    expect(draft.text, isEmpty);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    expect(sent, hasLength(1));
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.hasAnyClients, isTrue);
    tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: '다음', selection: TextSelection.collapsed(offset: 2)));
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(sent, ['abc 가나다', '다음']);
    expect(draft.text, isEmpty);
    expect(remoteKeys, 0);
    await tester.pumpWidget(const SizedBox());
    draft.dispose();
    focus.dispose();
  });

  testWidgets(
      'mode selection preserves unsent draft and live input still works',
      (tester) async {
    final draft = TextEditingController(text: '보내지 않은 글');
    final focus = FocusNode();
    var buffered = true;
    var remembered = true;
    var remote = '';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: StatefulBuilder(
          builder: (context, setState) => AndroidKeyboardPanel(
                buffered: buffered,
                enabled: true,
                onModeChanged: (value) => setState(() {
                  buffered = value;
                  remembered = value;
                }),
                draft: draft,
                focusNode: focus,
                onSubmit: (_) async =>
                    fail('Switching mode must not submit a draft'),
                onText: (text) => remote += text,
                onBackspace: () =>
                    remote = remote.characters.skipLast(1).join(),
                onEnter: () => remote += '\n',
              )),
    )));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('android-input-mode')),
        kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(remembered, isFalse);
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.hasAnyClients, isTrue);
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller,
        isNot(same(draft)));
    expect(remote, isEmpty);
    for (final text in ['ㄱ', '가', '가나']) {
      tester.testTextInput.updateEditingValue(TextEditingValue(
          text: text, selection: TextSelection.collapsed(offset: text.length)));
      await tester.pump();
    }
    expect(remote, '가나');
    await tester.tap(find.byKey(const ValueKey('android-input-mode')),
        kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(remembered, isTrue);
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.hasAnyClients, isTrue);
    expect(draft.text, '보내지 않은 글');
    expect(remote, '가나');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    draft.dispose();
    focus.dispose();
  });

  testWidgets('remote keys preserve draft; blocked or failed sends preserve it',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final draft = TextEditingController(text: 'abc 가나다');
    final focus = FocusNode();
    final keys = <String>[];
    var attempts = 0;
    var enabled = true;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: Column(children: [
        const Expanded(child: ColoredBox(color: Colors.black)),
        StatefulBuilder(builder: (context, setState) {
          update = setState;
          return AndroidKeyboardPanel(
            buffered: true,
            enabled: enabled,
            onModeChanged: (_) {},
            draft: draft,
            focusNode: focus,
            onSubmit: (_) async {
              attempts++;
            },
            onText: (_) => fail('Draft must not go through live input'),
            onBackspace: () => keys.add('back'),
            onEnter: () => keys.add('enter'),
          );
        }),
      ]),
    )));
    await tester.pump();
    await tester.tap(find.byTooltip('원격 Backspace 보내기'));
    await tester.tap(find.byTooltip('원격 Enter 보내기'));
    expect(keys, ['back', 'enter']);
    expect(draft.text, 'abc 가나다');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(attempts, 1);
    // The session did not confirm a successful send, so it kept the draft.
    expect(draft.text, 'abc 가나다');
    update(() => enabled = false);
    await tester.pump();
    await tester.tap(find.byTooltip('원격 Backspace 보내기'));
    await tester.tap(find.byTooltip('원격 Enter 보내기'));
    expect(keys, ['back', 'enter']);
    expect(draft.text, 'abc 가나다');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    draft.dispose();
    focus.dispose();
  });
}
