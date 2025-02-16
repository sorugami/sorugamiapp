import 'package:flutter/material.dart';
import 'package:flutterquiz/utils/extensions.dart';

class BlinkingTextWidget extends StatefulWidget {
  const BlinkingTextWidget({
    required this.viewAllKey,
    super.key,
  });

  final String viewAllKey;

  @override
  _BlinkingTextWidgetState createState() => _BlinkingTextWidgetState();
}

class _BlinkingTextWidgetState extends State<BlinkingTextWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    // Animasyon controller'ını başlatıyoruz
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(
        reverse:
            true); // Tersine animasyon yaptırarak yanıp sönmesini sağlıyoruz
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme'den renk bilgilerini almak için bu metod kullanılabilir
    _colorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.onTertiary.withAlpha(0x99),
      end: Theme.of(context).colorScheme.primary,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          context.tr(widget.viewAllKey) ?? widget.viewAllKey,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _colorAnimation.value,
            decoration: TextDecoration.underline,
            decorationColor: _colorAnimation.value,
          ),
        );
      },
    );
  }
}
