import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CloudBubbleSvg extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final EdgeInsets padding;
  final Color bubbleColor;
  final double? maxWidth;
  /// 텍스트+패딩에 더해 최소 확보할 가로 여분(px)
  final double extraHorizontal;
  /// 텍스트+패딩에 더해 최소 확보할 세로 여분(px)
  final double extraVertical;

  const CloudBubbleSvg({
    Key? key,
    required this.text,
    this.style,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.bubbleColor = Colors.white,
    this.maxWidth,
    this.extraHorizontal = 20,
    this.extraVertical = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? DefaultTextStyle.of(context).style;

    // 1) 텍스트 사이즈 측정
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    // 레이아웃 가능한 최대 폭
    final constraintW = (maxWidth ?? double.infinity)
        - padding.horizontal
        - extraHorizontal;
    tp.layout(maxWidth: constraintW);

    final textW = tp.width;
    final textH = tp.height;

    // 2) 말풍선 크기 계산
    final boxW = textW + padding.horizontal + extraHorizontal;
    final boxH = textH + padding.vertical + extraVertical;

    return SizedBox(
      width: boxW,
      height: boxH,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 SVG
          SvgPicture.asset(
            'assets/images/cloud_bubble2.svg',
            width: boxW,
            height: boxH,
            fit: BoxFit.fill,
            colorFilter: ColorFilter.mode(bubbleColor, BlendMode.srcIn),
          ),

          // 텍스트
          Padding(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: boxW - padding.horizontal,
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
