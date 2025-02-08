import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutterquiz/features/leaderBoard/cubit/leaderboard_all_time_cubit.dart';
import 'package:flutterquiz/features/leaderBoard/cubit/leaderboard_daily_cubit.dart';
import 'package:flutterquiz/features/leaderBoard/cubit/leaderboard_monthly_cubit.dart';
import 'package:flutterquiz/ui/widgets/already_logged_in_dialog.dart';
import 'package:flutterquiz/ui/widgets/circular_progress_container.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/ui/widgets/custom_image.dart';
import 'package:flutterquiz/ui/widgets/error_container.dart';
import 'package:flutterquiz/utils/constants/error_message_keys.dart';
import 'package:flutterquiz/utils/constants/fonts.dart';
import 'package:flutterquiz/utils/constants/string_labels.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

class LeaderBoardScreen extends StatefulWidget {
  const LeaderBoardScreen({super.key});

  @override
  State<LeaderBoardScreen> createState() => _LeaderBoardScreen();

  static Route<LeaderBoardScreen> route() {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<LeaderBoardMonthlyCubit>(
            create: (_) => LeaderBoardMonthlyCubit(),
          ),
          BlocProvider<LeaderBoardDailyCubit>(
            create: (_) => LeaderBoardDailyCubit(),
          ),
          BlocProvider<LeaderBoardAllTimeCubit>(
            create: (_) => LeaderBoardAllTimeCubit(),
          ),
        ],
        child: const LeaderBoardScreen(),
      ),
    );
  }
}

class _LeaderBoardScreen extends State<LeaderBoardScreen> {
  final controllerM = ScrollController();
  final controllerA = ScrollController();
  final controllerD = ScrollController();

  @override
  void initState() {
    controllerM.addListener(scrollListenerM);
    controllerA.addListener(scrollListenerA);
    controllerD.addListener(scrollListenerD);

    Future.delayed(
      Duration.zero,
      () {
        context.read<LeaderBoardDailyCubit>().fetchLeaderBoard('20');
        context.read<LeaderBoardMonthlyCubit>().fetchLeaderBoard('20');
        context.read<LeaderBoardAllTimeCubit>().fetchLeaderBoard('20');
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    controllerM.removeListener(scrollListenerM);
    controllerA.removeListener(scrollListenerA);
    controllerD.removeListener(scrollListenerD);
    super.dispose();
  }

  void scrollListenerM() {
    if (controllerM.position.maxScrollExtent == controllerM.offset) {
      if (context.read<LeaderBoardMonthlyCubit>().hasMoreData()) {
        context.read<LeaderBoardMonthlyCubit>().fetchMoreLeaderBoardData('20');
      }
    }
  }

  void scrollListenerA() {
    if (controllerA.position.maxScrollExtent == controllerA.offset) {
      if (context.read<LeaderBoardAllTimeCubit>().hasMoreData()) {
        context.read<LeaderBoardAllTimeCubit>().fetchMoreLeaderBoardData('20');
      }
    }
  }

  void scrollListenerD() {
    if (controllerD.position.maxScrollExtent == controllerD.offset) {
      if (context.read<LeaderBoardDailyCubit>().hasMoreData()) {
        context.read<LeaderBoardDailyCubit>().fetchMoreLeaderBoardData('20');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: QAppBar(
          elevation: 0,
          title: Text(
            context.tr('leaderboardLbl')!,
          ),
          bottom: TabBar(
            tabAlignment: TabAlignment.fill,
            tabs: [
              Tab(
                text: context.tr('allTimeLbl'),
              ),
              Tab(
                text: context.tr('monthLbl'),
              ),
              Tab(
                text: context.tr('dailyLbl'),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            allTimeLeaderBoard(),
            monthlyLeaderBoard(),
            dailyLeaderBoard(),
          ],
        ),
      ),
    );
  }

  void fetchMonthlyLeaderBoard() => context.read<LeaderBoardMonthlyCubit>().fetchLeaderBoard('20');

  void fetchDailyLeaderBoard() => context.read<LeaderBoardDailyCubit>().fetchLeaderBoard('20');

  void fetchAllTimeLeaderBoard() => context.read<LeaderBoardAllTimeCubit>().fetchLeaderBoard('20');

  Widget noLeaderboard(VoidCallback onTapRetry) => Center(
        child: ErrorContainer(
          topMargin: 0,
          errorMessage: 'noLeaderboardLbl',
          onTapRetry: onTapRetry,
          showErrorImage: false,
        ),
      );

  Widget dailyLeaderBoard() {
    return BlocConsumer<LeaderBoardDailyCubit, LeaderBoardDailyState>(
      bloc: context.read<LeaderBoardDailyCubit>(),
      listener: (context, state) {
        if (state is LeaderBoardDailyFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);

            return;
          }
        }
      },
      builder: (context, state) {
        if (state is LeaderBoardDailyFailure) {
          return ErrorContainer(
            showBackButton: false,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: fetchDailyLeaderBoard,
            showErrorImage: true,
            errorMessageColor: Theme.of(context).primaryColor,
          );
        }

        ///
        if (state is LeaderBoardDailySuccess) {
          final dailyList = state.leaderBoardDetails;
          final hasMore = state.hasMore;

          /// API returns empty list if there is no leaderboard data.
          if (dailyList.isEmpty) {
            return noLeaderboard(fetchDailyLeaderBoard);
          }

          log(name: 'Leaderboard Daily', jsonEncode(dailyList));
          log(name: 'Leaderboard Daily', 'Has More: $hasMore');

          return SizedBox(
            height: context.height * 0.6,
            child: Column(
              children: [
                topThreeRanks(dailyList),
                leaderBoardList(dailyList, controllerD, hasMore: hasMore),
                if (LeaderBoardDailyCubit.scoreD != '0' && int.parse(LeaderBoardDailyCubit.rankD) > 3)
                  myRank(
                    LeaderBoardDailyCubit.rankD,
                    LeaderBoardDailyCubit.profileD,
                    LeaderBoardDailyCubit.scoreD,
                  ),
                const SizedBox(height: 36),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressContainer());
      },
    );
  }

  Widget monthlyLeaderBoard() {
    return BlocConsumer<LeaderBoardMonthlyCubit, LeaderBoardMonthlyState>(
      bloc: context.read<LeaderBoardMonthlyCubit>(),
      listener: (context, state) {
        if (state is LeaderBoardMonthlyFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);

            return;
          }
        }
      },
      builder: (context, state) {
        if (state is LeaderBoardMonthlyFailure) {
          return ErrorContainer(
            showBackButton: false,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: fetchMonthlyLeaderBoard,
            showErrorImage: true,
            errorMessageColor: Theme.of(context).primaryColor,
          );
        }

        ///
        if (state is LeaderBoardMonthlySuccess) {
          final monthlyList = state.leaderBoardDetails;
          final hasMore = state.hasMore;

          /// API returns empty list if there is no leaderboard data.
          if (monthlyList.isEmpty) {
            return noLeaderboard(fetchMonthlyLeaderBoard);
          }

          log(name: 'Leaderboard Monthly', jsonEncode(monthlyList));
          log(name: 'Leaderboard Monthly', 'Has More: $hasMore');

          return SizedBox(
            height: context.height * .6,
            child: Column(
              children: [
                topThreeRanks(monthlyList),
                leaderBoardList(monthlyList, controllerM, hasMore: hasMore),
                if (LeaderBoardMonthlyCubit.scoreM != '0' && int.parse(LeaderBoardMonthlyCubit.rankM) > 3)
                  myRank(
                    LeaderBoardMonthlyCubit.rankM,
                    LeaderBoardMonthlyCubit.profileM,
                    LeaderBoardMonthlyCubit.scoreM,
                  ),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressContainer());
      },
    );
  }

  Widget allTimeLeaderBoard() {
    return BlocConsumer<LeaderBoardAllTimeCubit, LeaderBoardAllTimeState>(
      bloc: context.read<LeaderBoardAllTimeCubit>(),
      listener: (context, state) {
        if (state is LeaderBoardAllTimeFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
          }
        }
      },
      builder: (context, state) {
        if (state is LeaderBoardAllTimeFailure) {
          return ErrorContainer(
            showBackButton: false,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: fetchAllTimeLeaderBoard,
            showErrorImage: true,
            errorMessageColor: Theme.of(context).primaryColor,
          );
        }

        ///
        if (state is LeaderBoardAllTimeSuccess) {
          final allTimeList = state.leaderBoardDetails;
          final hasMore = state.hasMore;

          /// API returns empty list if there is no leaderboard data.
          if (allTimeList.isEmpty) {
            return noLeaderboard(fetchDailyLeaderBoard);
          }

          log(name: 'Leaderboard All Time', jsonEncode(allTimeList));
          log(name: 'Leaderboard All Time', 'Has More: $hasMore');

          return SizedBox(
            height: context.height * .6,
            child: Column(
              children: [
                topThreeRanks(allTimeList),
                leaderBoardList(allTimeList, controllerA, hasMore: hasMore),
                if (LeaderBoardAllTimeCubit.scoreA != '0' && int.parse(LeaderBoardAllTimeCubit.rankA) > 3)
                  myRank(
                    LeaderBoardAllTimeCubit.rankA,
                    LeaderBoardAllTimeCubit.profileA,
                    LeaderBoardAllTimeCubit.scoreA,
                  ),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressContainer());
      },
    );
  }

  Widget topThreeRanks(List<Map<String, dynamic>> circleList) {
    final height = context.height;
    final width = context.width;

    Widget rank(double maxHeight, int idx) {
      final onTertiary = Theme.of(context).colorScheme.onTertiary;
      final imageSize = idx == 0 ? maxHeight * .40 : maxHeight * .35;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: idx == 0 ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            SizedBox(
              height: imageSize,
              width: imageSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: onTertiary.withValues(alpha: .3),
                        ),
                      ),
                      child: QImage.circular(
                        imageUrl: circleList[idx]['profile'] as String,
                        width: double.maxFinite,
                        height: double.maxFinite,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: idx == 0 ? -12 : -10,
                    left: 0,
                    right: 0,
                    child: rankCircle(
                      (idx + 1).toString(),
                      size: idx == 0 ? 30 : 25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              circleList[idx]['name']!.toString().isNotEmpty ? circleList[idx]['name']!.toString() : '...',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeights.regular,
                color: onTertiary.withValues(alpha: .8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              circleList[idx]['score'] as String? ?? '...',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeights.bold,
                color: onTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      width: width,
      height: height * 0.31,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = constraints.maxHeight;

                return Row(
                  children: [
                    /// Rank 2
                    Expanded(
                      flex: 2,
                      child: circleList.length > 1 ? rank(maxHeight, 1) : const SizedBox.shrink(),
                    ),

                    /// Rank 1
                    Expanded(
                      flex: 3,
                      child: circleList.isNotEmpty ? rank(maxHeight, 0) : const SizedBox.shrink(),
                    ),

                    /// Rank 3
                    Expanded(
                      flex: 2,
                      child: circleList.length > 2 ? rank(maxHeight, 2) : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: GestureDetector(
              onTap: () async {
                await _launchURL();
              },
              child: Text(
                'Ödülleri görmek için tıklayınız.',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).primaryColor,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.sorugami.com/oduller/');
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception("Could not launch $url");
      }
    } catch (e) {
      print("Error launching URL: $e");
      rethrow; // Optionally rethrow the error if needed
    }
  }

  Widget rankCircle(String text, {double size = 25}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: colorScheme.surface,
          ),
        ),
      ),
    );
  }

  Widget leaderBoardList(
    List<Map<String, dynamic>> leaderBoardList,
    ScrollController controller, {
    required bool hasMore,
  }) {
    if (leaderBoardList.length <= 3) return const SizedBox();

    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.onTertiary,
      fontSize: 16,
    );
    final width = context.width;
    final height = context.height;

    return Expanded(
      child: Container(
        height: height * .45,
        padding: EdgeInsets.only(top: 5, left: width * .02, right: width * .02),
        child: ListView.separated(
          controller: controller,
          shrinkWrap: true,
          itemCount: leaderBoardList.length,
          separatorBuilder: (_, i) => i > 2
              ? Divider(
                  color: Colors.black26,
                  thickness: .5,
                  indent: width * 0.03,
                  endIndent: width * 0.03,
                )
              : const SizedBox(),
          itemBuilder: (context, index) {
            final leaderBoard = leaderBoardList[index];

            return index > 2
                ? (hasMore && index == (leaderBoardList.length - 1))
                    ? const Center(child: CircularProgressContainer())
                    : Row(
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              leaderBoard['user_rank'] as String,
                              style: textStyle,
                            ),
                          ),
                          Expanded(
                            flex: 9,
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(right: 20),
                              title: Text(
                                leaderBoard['name'] as String? ?? '...',
                                overflow: TextOverflow.ellipsis,
                                style: textStyle,
                              ),
                              leading: Container(
                                width: width * .12,
                                height: height * .3,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: QImage.circular(
                                  imageUrl: leaderBoard['profile'] as String? ?? '',
                                  width: double.maxFinite,
                                  height: double.maxFinite,
                                ),
                              ),
                              trailing: SizedBox(
                                width: width * .12,
                                child: Center(
                                  child: Text(
                                    UiUtils.formatNumber(
                                      int.parse(
                                        leaderBoard['score'] as String? ?? '0',
                                      ),
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    style: textStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                : const SizedBox();
          },
        ),
      ),
    );
  }

  Widget myRank(String rank, String profile, String score) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(color: colorScheme.onTertiary, fontSize: 16);
    final height = context.height;
    final width = context.width;

    return Container(
      decoration: BoxDecoration(color: colorScheme.surface),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: width * 0.03),
        title: Row(
          children: [
            Center(child: Text(rank, style: textStyle)),
            Container(
              margin: const EdgeInsets.only(left: 10),
              height: height * .06,
              width: width * .13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                ),
              ),
              child: QImage.circular(
                imageUrl: profile,
                width: double.maxFinite,
                height: double.maxFinite,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.tr(myRankKey)!,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ],
        ),
        trailing: Text(
          score,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: textStyle,
        ),
      ),
    );
  }
}
