import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/quiz/cubits/subcategory_cubit.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/quiz/models/subcategory.dart';
import 'package:flutterquiz/ui/widgets/already_logged_in_dialog.dart';
import 'package:flutterquiz/ui/widgets/banner_ad_container.dart';
import 'package:flutterquiz/ui/widgets/circular_progress_container.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/ui/widgets/error_container.dart';
import 'package:flutterquiz/utils/constants/assets_constants.dart';
import 'package:flutterquiz/utils/constants/error_message_keys.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

class SubCategoryScreen extends StatefulWidget {
  const SubCategoryScreen({
    required this.categoryId,
    required this.quizType,
    required this.categoryName,
    required this.isPremiumCategory,
    super.key,
  });

  final String categoryId;
  final QuizTypes quizType;
  final String categoryName;
  final bool isPremiumCategory;

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments! as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => SubCategoryScreen(
        categoryId: args['categoryId'] as String,
        quizType: args['quizType'] as QuizTypes,
        categoryName: args['category_name'] as String,
        isPremiumCategory: args['isPremiumCategory'] as bool? ?? false,
      ),
    );
  }
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  void getSubCategory() {
    Future.delayed(Duration.zero, () {
      context.read<SubCategoryCubit>().fetchSubCategory(widget.categoryId);
    });
  }

  @override
  void initState() {
    super.initState();
    getSubCategory();
  }

  void handleListTileTap(Subcategory subCategory) {
    if (widget.quizType == QuizTypes.guessTheWord) {
      Navigator.of(context).pushNamed(
        Routes.guessTheWord,
        arguments: {
          'type': 'subcategory',
          'typeId': subCategory.id,
          'isPlayed': subCategory.isPlayed,
          'isPremiumCategory': widget.isPremiumCategory,
        },
      );
    } else if (widget.quizType == QuizTypes.funAndLearn) {
      Navigator.of(context).pushNamed(
        Routes.funAndLearnTitle,
        arguments: {
          'type': 'subcategory',
          'typeId': subCategory.id,
          'title': subCategory.subcategoryName,
          'isPremiumCategory': widget.isPremiumCategory,
        },
      );
    } else if (widget.quizType == QuizTypes.audioQuestions) {
      Navigator.of(context).pushNamed(
        Routes.quiz,
        arguments: {
          'numberOfPlayer': 1,
          'quizType': QuizTypes.audioQuestions,
          'subcategoryId': subCategory.id,
          'isPlayed': subCategory.isPlayed,
          'isPremiumCategory': widget.isPremiumCategory,
        },
      );
    } else if (widget.quizType == QuizTypes.mathMania) {
      Navigator.of(context).pushNamed(
        Routes.quiz,
        arguments: {
          'numberOfPlayer': 1,
          'quizType': QuizTypes.mathMania,
          'subcategoryId': subCategory.id,
          'isPlayed': subCategory.isPlayed,
          'isPremiumCategory': widget.isPremiumCategory,
        },
      );
    }
  }

  Widget _buildSubCategory() {
    return BlocConsumer<SubCategoryCubit, SubCategoryState>(
      bloc: context.read<SubCategoryCubit>(),
      listener: (context, state) {
        if (state is SubCategoryFetchFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
          }
        }
      },
      builder: (context, state) {
        if (state is SubCategoryFetchInProgress ||
            state is SubCategoryInitial) {
          return const Center(child: CircularProgressContainer());
        }

        if (state is SubCategoryFetchFailure) {
          return Center(
            child: ErrorContainer(
              showBackButton: false,
              showErrorImage: true,
              errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
              onTapRetry: getSubCategory,
            ),
          );
        }

        final subcategories =
            (state as SubCategoryFetchSuccess).subcategoryList;
        return ListView.separated(
          padding: EdgeInsets.symmetric(
            vertical: context.height * UiUtils.vtMarginPct,
            horizontal: context.width * UiUtils.hzMarginPct,
          ),
          shrinkWrap: true,
          itemCount: subcategories.length,
          physics: const AlwaysScrollableScrollPhysics(),
          separatorBuilder: (_, i) =>
              const SizedBox(height: UiUtils.listTileGap),
          itemBuilder: (BuildContext context, int index) {
            final subcategory = subcategories[index];

            return GestureDetector(
              onTap: () => handleListTileTap(subcategory),
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: boxConstraints.maxWidth * (0.1),
                        right: boxConstraints.maxWidth * (0.1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            boxShadow: const [
                              BoxShadow(
                                offset: Offset(0, 25),
                                blurRadius: 5,
                                spreadRadius: 2,
                                color: Color(0x40808080),
                              ),
                            ],
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(
                                boxConstraints.maxWidth * .525,
                              ),
                            ),
                          ),
                          width: boxConstraints.maxWidth,
                          height: 50,
                        ),
                      ),
                      Positioned(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(12),
                          width: boxConstraints.maxWidth,
                          child: Row(
                            children: [
                              /// Leading Image
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiary
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                padding: const EdgeInsets.all(5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1),
                                  child: CachedNetworkImage(
                                    fit: BoxFit.fill,
                                    memCacheWidth: 50,
                                    memCacheHeight: 50,
                                    placeholder: (_, __) => const SizedBox(),
                                    imageUrl: subcategory.image!,
                                    errorWidget: (_, i, e) => const Image(
                                      image: AssetImage(Assets.icLauncher),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              /// title
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subcategory.subcategoryName!,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onTertiary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "${context.tr(widget.quizType == QuizTypes.funAndLearn ? "comprehensiveLbl" : "questions")!}: ${subcategory.noOfQue!}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onTertiary
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              /// right arrow
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiary
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  size: 30,
                                  color:
                                      Theme.of(context).colorScheme.onTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QAppBar(
        title: Text(widget.categoryName),
        roundedAppBar: false,
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _buildSubCategory(),
          ),

          /// Banner Ad
          const Align(
            alignment: Alignment.bottomCenter,
            child: BannerAdContainer(),
          ),
        ],
      ),
    );
  }
}
