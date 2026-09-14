import 'package:flutter/material.dart';

import '../utils/dynamic_translator.dart';

class DynamicText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const DynamicText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: DynamicTranslator.translate(text),
      builder: (context, snapshot) {
        return Text(snapshot.data ?? text, style: style);
      },
    );
  }
}
