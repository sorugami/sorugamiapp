import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/ui/widgets/custom_image.dart';
import 'package:flutterquiz/utils/constants/fonts.dart';
import 'package:popover/popover.dart';

class QuizGridCard extends StatelessWidget {
  const QuizGridCard({
    required this.title,
    required this.desc,
    required this.img,
    required this.informationTitle,
    required this.informationDescription,
    super.key,
    this.onTap,
    this.iconOnRight = true,
  });

  final String title;
  final String desc;
  final String img;
  final String informationTitle;
  final String informationDescription;
  final bool iconOnRight;
  final void Function()? onTap;

  ///
  static const _borderRadius = 10.0;
  static const _padding = EdgeInsets.all(12);
  static const _iconBorderRadius = 6.0;
  static const _iconMargin = EdgeInsets.all(5);

  static const _boxShadow = [
    BoxShadow(
      offset: Offset(0, 50),
      blurRadius: 30,
      spreadRadius: 5,
      color: Color(0xff45536d),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (_, constraints) {
          final cSize = constraints.maxWidth;
          final iconSize = cSize * .28;
          final iconColor = Theme.of(context).primaryColor;

          return Stack(
            children: [
              /// Box Shadow
              Positioned(
                top: 0,
                left: cSize * 0.2,
                right: cSize * 0.2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    boxShadow: _boxShadow,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(cSize * .525),
                    ),
                  ),
                  width: cSize,
                  height: cSize * .6,
                ),
              ),

              /// Card
              Container(
                width: cSize,
                height: cSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_borderRadius),
                  color: Theme.of(context).colorScheme.surface,
                ),
                padding: _padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontWeight: FontWeights.semiBold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// Description
                    Expanded(
                      child: Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeights.regular,
                          color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),

                    /// Svg Icon
                    Align(
                      alignment: iconOnRight ? Alignment.bottomRight : Alignment.bottomLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              showPopover(
                                context: context,
                                bodyBuilder: (context) {
                                  return CategoryInformationBubbleWidget(
                                    title: informationTitle,
                                    description: informationDescription,
                                  );
                                },
                                onPop: () => print('Popover was popped!'),
                                direction: PopoverDirection.bottom,
                                width: 300,
                                height: 200,
                              );
                            },
                            child: Text(
                              'Detaylar',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(_iconBorderRadius),
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                            padding: _iconMargin,
                            width: iconSize,
                            height: iconSize,
                            child: QImage(
                              imageUrl: img,
                              color: iconColor,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CategoryInformationBubbleWidget extends StatelessWidget {
  const CategoryInformationBubbleWidget({
    super.key,
    this.title,
    this.description,
  });

  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Icon(Icons.info_outline, color: Theme.of(context).disabledColor, size: 14),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    description ?? 'Sizin için en detaylı açıklamayı hazırlıyoruz.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
