import 'package:flutter/material.dart';

import 'android_soft_keyboard.dart';

class AndroidKeyboardPanel extends StatefulWidget {
  final bool buffered;
  final bool enabled;
  final ValueChanged<bool> onModeChanged;
  final TextEditingController draft;
  final FocusNode focusNode;
  final Future<void> Function(String) onSubmit;
  final ValueChanged<String> onText;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;

  const AndroidKeyboardPanel({
    super.key,
    required this.buffered,
    required this.enabled,
    required this.onModeChanged,
    required this.draft,
    required this.focusNode,
    required this.onSubmit,
    required this.onText,
    required this.onBackspace,
    required this.onEnter,
  });

  @override
  State<AndroidKeyboardPanel> createState() => _AndroidKeyboardPanelState();
}

class _AndroidKeyboardPanelState extends State<AndroidKeyboardPanel> {
  bool _sending = false;

  Future<void> _submit() async {
    final text = widget.draft.text;
    if (_sending || !widget.enabled || text.isEmpty) return;
    setState(() => _sending = true);
    try {
      // The session owns the draft and clears it only after a successful send,
      // including when this panel was hidden while the send was in flight.
      await widget.onSubmit(text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextFieldTapRegion(
          child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 4,
        child: SafeArea(
          top: false,
          child: Row(children: [
            ExcludeFocus(
              child: IconButton(
                key: const ValueKey('android-input-mode'),
                tooltip: widget.buffered
                    ? '텍스트 전송 모드 · 눌러서 실시간 입력'
                    : '실시간 입력 모드 · 눌러서 텍스트 전송',
                icon:
                    Icon(widget.buffered ? Icons.text_fields : Icons.keyboard),
                onPressed: _sending
                    ? null
                    : () => widget.onModeChanged(!widget.buffered),
              ),
            ),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Visibility(
                  visible: !widget.buffered,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('실시간 입력'),
                  ),
                ),
                SizedBox(
                  width: widget.buffered ? null : 0,
                  height: widget.buffered ? null : 0,
                  child: AndroidSoftKeyboardInput(
                    focusNode: widget.focusNode,
                    buffered: widget.buffered,
                    draft: widget.draft,
                    enabled: widget.enabled,
                    readOnly: _sending,
                    onSubmitted: (_) => _submit(),
                    onText: widget.onText,
                    onBackspace: widget.onBackspace,
                    onEnter: widget.onEnter,
                  ),
                ),
              ]),
            ),
            if (widget.buffered) ...[
              ExcludeFocus(
                child: IconButton(
                  tooltip: '원격 Backspace 보내기',
                  icon: const Icon(Icons.backspace_outlined),
                  onPressed:
                      widget.enabled && !_sending ? widget.onBackspace : null,
                ),
              ),
              ExcludeFocus(
                child: IconButton(
                  tooltip: '원격 Enter 보내기',
                  icon: const Icon(Icons.keyboard_return),
                  onPressed:
                      widget.enabled && !_sending ? widget.onEnter : null,
                ),
              ),
            ],
          ]),
        ),
      ));
}
