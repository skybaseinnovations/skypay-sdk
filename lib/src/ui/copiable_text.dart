import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SkyCopiableText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const SkyCopiableText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style:
                  style ??
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.copy, size: 14, color: Colors.blue),
        ],
      ),
    );
  }
}
