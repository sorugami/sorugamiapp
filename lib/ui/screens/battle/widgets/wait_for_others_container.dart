import 'package:flutter/material.dart';
import 'package:flutterquiz/ui/screens/battle/widgets/rectangle_user_profile_container.dart';
import 'package:flutterquiz/ui/widgets/question_background_card.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

class WaitForOthersContainer extends StatelessWidget {
  const WaitForOthersContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top +
            context.height *
                RectangleUserProfileContainer.userDetailsHeightPercentage *
                2.75,
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          const QuestionBackgroundCard(
            heightPercentage: UiUtils.questionContainerHeightPercentage - 0.045,
            opacity: 0.7,
            topMarginPercentage: 0.05,
            widthPercentage: 0.65,
          ),
          const QuestionBackgroundCard(
            heightPercentage: UiUtils.questionContainerHeightPercentage - 0.045,
            opacity: 0.85,
            topMarginPercentage: 0.03,
            widthPercentage: 0.75,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            width: context.width * (0.85),
            height: context.height * UiUtils.questionContainerHeightPercentage,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(context.tr('waitOtherComplete')!),
            ),
          ),
        ],
      ),
    );
  }
}
