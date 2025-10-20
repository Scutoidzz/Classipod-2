import 'package:flutter/cupertino.dart';

class AboutListTile extends StatelessWidget {
  final String titleText;
  final String valueText;
  const AboutListTile({
    super.key,
    required this.titleText,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    return SizedBox(
      height: 30,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titleText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
