import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/localization/quiz_language_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/contest_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quiz_category_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quizzone_category_cubit.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/ui/widgets/custom_rounded_button.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

Future<void> showQuizLanguageSelectorSheet(BuildContext context) async {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: UiUtils.bottomSheetTopRadius,
    ),
    builder: (_) => const _QuizLanguageSelectorWidget(),
  );
}

class _QuizLanguageSelectorWidget extends StatelessWidget {
  const _QuizLanguageSelectorWidget();

  @override
  Widget build(BuildContext context) {
    final supportedLanguages =
        context.read<SystemConfigCubit>().supportedQuizLanguages;

    final size = context;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: UiUtils.bottomSheetTopRadius,
      ),
      padding: EdgeInsets.only(top: size.height * .02),
      child: BlocConsumer<QuizLanguageCubit, QuizLanguageState>(
        listener: (context, state) {
          final currLanguageId = UiUtils.getCurrentQuizLanguageId(context);

          context.read<QuizCategoryCubit>().getQuizCategoryWithUserId(
                languageId: currLanguageId,
                type: UiUtils.getCategoryTypeNumberFromQuizType(
                  QuizTypes.quizZone,
                ),
              );
          context
              .read<QuizoneCategoryCubit>()
              .getQuizCategoryWithUserId(languageId: currLanguageId);

          context.read<ContestCubit>().getContest(languageId: currLanguageId);
        },
        builder: (context, state) {
          final textStyle = TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onTertiary,
          );

          var currLangId = state.languageId;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * UiUtils.hzMarginPct,
            ),
            child: Column(
              children: [
                Text(
                  context.tr('quizLanguage')!,
                  style: textStyle,
                ),
                const Divider(),
                Container(
                  margin: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minHeight: size.height * .2,
                    maxHeight: size.height * .4,
                  ),
                  child: ListView.separated(
                    itemBuilder: (_, i) {
                      final supportedLanguage = supportedLanguages[i];
                      final languageId = supportedLanguage.id;

                      final colorScheme = Theme.of(context).colorScheme;

                      return Container(
                        decoration: BoxDecoration(
                          color: currLangId == languageId
                              ? Theme.of(context).primaryColor
                              : colorScheme.onTertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: RadioListTile(
                          toggleable: true,
                          activeColor: Colors.white,
                          value: languageId,
                          title: Text(
                            supportedLanguage.language,
                            style: textStyle.copyWith(
                              color: currLangId == languageId
                                  ? Colors.white
                                  : colorScheme.onTertiary,
                            ),
                          ),
                          groupValue: currLangId,
                          onChanged: (value) {
                            currLangId = value!;

                            if (state.languageId != languageId) {
                              context.read<QuizLanguageCubit>().languageId =
                                  languageId;
                            }
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemCount: supportedLanguages.length,
                  ),
                ),
                const Spacer(),
                CustomRoundedButton(
                  onTap: Navigator.of(context).pop,
                  widthPercentage: 1,
                  backgroundColor: Theme.of(context).primaryColor,
                  buttonTitle: context.tr('save'),
                  radius: 8,
                  showBorder: false,
                  height: 45,
                ),
                const Expanded(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }
}
