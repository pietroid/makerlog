import 'package:clitter/clitter.dart';

/// Keyboard-driven numbered options list. Arrow up/down moves the
/// highlight, Enter commits the selected option back to the parent as
/// plain text — the parent decides what to do with it (typically:
/// treat it as if the user had typed it).
///
/// The picker only renders options; it does not render labels or
/// prompt copy. The caller supplies the [options] verbatim.
class OptionsPicker extends StatefulWidget {
  final List<String> options;
  final void Function(String option) onSelected;

  /// When set, the picker ignores Enter while the predicate returns
  /// false. Typical use: gate Enter so it only triggers when a sibling
  /// TextField is empty, avoiding a double-submit.
  final bool Function()? shouldHandleEnter;

  OptionsPicker({
    required this.options,
    required this.onSelected,
    this.shouldHandleEnter,
    super.key,
  });

  @override
  State<OptionsPicker> createState() => _OptionsPickerState();
}

class _OptionsPickerState extends State<OptionsPicker> {
  int _index = 0;

  @override
  void didUpdateWidget(OptionsPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.options.length) _index = 0;
  }

  void _handleKey(KeyEvent event) {
    if (widget.options.isEmpty) return;
    switch (event.type) {
      case KeyType.arrowUp:
        setState(() {
          _index = (_index - 1) % widget.options.length;
          if (_index < 0) _index += widget.options.length;
        });
      case KeyType.arrowDown:
        setState(() {
          _index = (_index + 1) % widget.options.length;
        });
      case KeyType.enter:
        if (widget.shouldHandleEnter != null &&
            !widget.shouldHandleEnter!()) {
          return;
        }
        widget.onSelected(widget.options[_index]);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return SizedBox(height: 0);
    return KeyboardListener(
      onKeyEvent: _handleKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < widget.options.length; i++)
            _OptionRow(
              number: i + 1,
              label: widget.options[i],
              selected: i == _index,
            ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final int number;
  final String label;
  final bool selected;

  _OptionRow({
    required this.number,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final marker = selected ? '❯' : ' ';
    final color = selected ? Color.brightCyan : Color.brightBlack;
    final labelColor = selected ? Color.brightWhite : Color.white;
    return Row(
      children: [
        Text(
          '$marker $number. ',
          style: TextStyle(
            color: color,
            fontWeight: selected ? FontWeight.bold : FontWeight.regular,
          ),
        ),
        Text(label, style: TextStyle(color: labelColor)),
      ],
    );
  }
}
