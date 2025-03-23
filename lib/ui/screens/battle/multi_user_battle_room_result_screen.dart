import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/ads/interstitial_ad_cubit.dart';
import 'package:flutterquiz/features/badges/cubits/badges_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_score_and_coins_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/features/quiz/models/user_battle_room_details.dart';
import 'package:flutterquiz/ui/widgets/already_logged_in_dialog.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/ui/widgets/custom_image.dart';
import 'package:flutterquiz/ui/widgets/custom_rounded_button.dart';
import 'package:flutterquiz/utils/constants/assets_constants.dart';
import 'package:flutterquiz/utils/constants/error_message_keys.dart';
import 'package:flutterquiz/utils/constants/fonts.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

class MultiUserBattleRoomResultScreen extends StatefulWidget {
  const MultiUserBattleRoomResultScreen({
    required this.users,
    required this.entryFee,
    required this.totalQuestions,
    super.key,
  });

  final List<UserBattleRoomDetails?> users;
  final int entryFee;
  final int totalQuestions;

  @override
  State<MultiUserBattleRoomResultScreen> createState() => _MultiUserBattleRoomResultScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>?;
    return CupertinoPageRoute(
      builder: (_) => BlocProvider<UpdateScoreAndCoinsCubit>(
        create: (_) => UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
        child: MultiUserBattleRoomResultScreen(
          users: args!['user'] as List<UserBattleRoomDetails?>,
          entryFee: args['entryFee'] as int,
          totalQuestions: args['totalQuestions'] as int,
        ),
      ),
    );
  }
}

class _MultiUserBattleRoomResultScreenState extends State<MultiUserBattleRoomResultScreen> {
  List<Map<String, dynamic>> usersWithRank = [];

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      context.read<InterstitialAdCubit>().showAd(context);
    });
    getResultAndUpdateCoins();
    super.initState();
  }

  void getResultAndUpdateCoins() {
    // Kullanıcıları ve rütbeleri oluşturma
    for (final element in widget.users) {
      usersWithRank.add({'user': element});
    }
    final points = usersWithRank.map((d) => (d['user'] as UserBattleRoomDetails).correctAnswers).toList()
      ..sort((first, second) => second.compareTo(first)); // Doğru cevap sayısına göre büyükten küçüğe sırala

    for (final userDetails in usersWithRank) {
      final rank = points.indexOf((userDetails['user'] as UserBattleRoomDetails).correctAnswers) + 1;
      userDetails.addAll({'rank': rank});
    }
    usersWithRank.sort(
      (first, second) => int.parse(first['rank'].toString()).compareTo(int.parse(second['rank'].toString())),
    );

    // UI güncellemeleri için gecikmeli bir eylem
    Future.delayed(Duration.zero, () {
      final currentUser = usersWithRank.where((element) => (element['user'] as UserBattleRoomDetails).uid == context.read<UserDetailsCubit>().userId()).toList().first;

      // Rozet güncellemesi (kazanan için)
      if (currentUser['rank'] == 1 && context.read<BadgesCubit>().isBadgeLocked('clash_winner')) {
        context.read<BadgesCubit>().setBadge(badgeType: 'clash_winner');
      }

      // Puan güncelleme her kullanıcı için
      for (final userDetails in usersWithRank) {
        int scoreToAdd;
        if (userDetails['rank'] == 1) {
          scoreToAdd = 10 + (userDetails['user'] as UserBattleRoomDetails).correctAnswers * 2; // Kazanan için ekstra puan
        } else {
          scoreToAdd = (userDetails['user'] as UserBattleRoomDetails).correctAnswers * 2; // Diğer kullanıcılar için puan
        }

        userDetails['score'] = scoreToAdd;

        // Puan güncellemesi
        if ((userDetails['user'] as UserBattleRoomDetails).uid == context.read<UserDetailsCubit>().userId()) {
          context.read<UpdateScoreAndCoinsCubit>().updateScore(scoreToAdd);
        }
      }

      // UI'da gösterilen bilgileri güncelle
      setState(() {});
    });
  }

  Widget _buildUserDetailsContainer(
    UserBattleRoomDetails userBattleRoomDetails,
    int rank,
    int score,
    Size size,
    bool showStars,
    AlignmentGeometry alignment,
    EdgeInsetsGeometry edgeInsetsGeometry,
    Color color,
  ) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                QImage.circular(
                  width: 52,
                  height: 52,
                  imageUrl: userBattleRoomDetails.profileUrl,
                ),
                Center(
                  child: SvgPicture.asset(
                    Assets.hexagonFrame,
                    width: 60,
                    height: 60,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                userBattleRoomDetails.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeights.bold,
                  color: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${userBattleRoomDetails.correctAnswers}/${widget.totalQuestions}',
                    style: TextStyle(
                      fontWeight: FontWeights.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Puan: $score', // 👈 puanı göster
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTopDetailsContainer(
    UserBattleRoomDetails userBattleRoomDetails,
    int rank,
    int score,
    Size size,
    bool showStars,
    AlignmentGeometry alignment,
    EdgeInsetsGeometry edgeInsetsGeometry,
    Color color,
  ) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: edgeInsetsGeometry,
        height: size.height,
        width: size.width,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                QImage.circular(
                  width: 100,
                  height: 100,
                  imageUrl: userBattleRoomDetails.profileUrl,
                ),
                Center(
                  child: SvgPicture.asset(Assets.hexagonFrame),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              userBattleRoomDetails.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeights.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onTertiary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${userBattleRoomDetails.correctAnswers}/${widget.totalQuestions}',
                    style: TextStyle(
                      fontWeight: FontWeights.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score: $score', // 👈 puanı göster
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdateScoreAndCoinsCubit, UpdateScoreAndCoinsState>(
      listener: (context, state) {
        if (state is UpdateScoreAndCoinsFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
          }
        }
      },
      child: Scaffold(
        appBar: QAppBar(
          roundedAppBar: false,
          title: Text(
            context.tr('groupBattleResult')!,
          ),
        ),
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: context.height * .7,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: context.height * UiUtils.hzMarginPct,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rank 1
                    _buildUserTopDetailsContainer(
                      usersWithRank.first['user'] as UserBattleRoomDetails,
                      usersWithRank.first['rank'] as int,
                      usersWithRank.first['score'] as int,
                      Size(
                        context.width * (0.475),
                        context.height * (0.35),
                      ),
                      true,
                      AlignmentDirectional.centerStart,
                      EdgeInsetsDirectional.only(
                        start: 10,
                        top: context.height * (0.025),
                      ),
                      Colors.green,
                    ),

                    //user 2
                    if (usersWithRank.length == 2)
                      _buildUserDetailsContainer(
                        usersWithRank[1]['user'] as UserBattleRoomDetails,
                        usersWithRank[1]['rank'] as int,
                        usersWithRank[1]['score'] as int,
                        Size(
                          context.width * (0.15),
                          context.height * (0.08),
                        ),
                        false,
                        AlignmentDirectional.centerStart,
                        EdgeInsetsDirectional.zero,
                        Colors.redAccent,
                      )
                    else
                      _buildUserDetailsContainer(
                        usersWithRank[1]['user'] as UserBattleRoomDetails,
                        usersWithRank[1]['rank'] as int,
                        usersWithRank[1]['score'] as int,
                        Size(
                          context.width * (0.38),
                          context.height * (0.28),
                        ),
                        false,
                        AlignmentDirectional.center,
                        EdgeInsetsDirectional.only(
                          start: context.width * (0.3),
                          bottom: context.height * (0.42),
                        ),
                        Colors.redAccent,
                      ),
                    const SizedBox(height: 12),

                    //user 3
                    if (usersWithRank.length > 2)
                      _buildUserDetailsContainer(
                        usersWithRank[2]['user'] as UserBattleRoomDetails,
                        usersWithRank[2]['rank'] as int,
                        usersWithRank[2]['score'] as int,
                        Size(
                          context.width * (0.36),
                          context.height * (0.25),
                        ),
                        false,
                        AlignmentDirectional.centerEnd,
                        EdgeInsetsDirectional.only(
                          end: 10,
                          top: context.height * (0.1),
                        ),
                        Colors.redAccent,
                      )
                    else
                      const SizedBox(),

                    const SizedBox(height: 12),

                    //user 4
                    if (usersWithRank.length == 4)
                      _buildUserDetailsContainer(
                        usersWithRank.last['user'] as UserBattleRoomDetails,
                        usersWithRank.last['rank'] as int,
                        usersWithRank.last['score'] as int,
                        Size(
                          context.width * (0.35),
                          context.height * (0.25),
                        ),
                        false,
                        AlignmentDirectional.center,
                        EdgeInsetsDirectional.only(
                          start: context.width * (0.3),
                          top: context.height * (0.575),
                        ),
                        Colors.redAccent,
                      )
                    else
                      const SizedBox(),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: usersWithRank.length == 4 ? 20 : 50.0,
                ),
                //if total 4 user than padding will be 20 else 50
                child: CustomRoundedButton(
                  widthPercentage: 0.85,
                  backgroundColor: Theme.of(context).primaryColor,
                  buttonTitle: context.tr('homeBtn'),
                  radius: 5,
                  showBorder: false,
                  fontWeight: FontWeight.bold,
                  height: 40,
                  elevation: 5,
                  titleColor: Theme.of(context).colorScheme.surface,
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      Routes.home,
                      (_) => false,
                      arguments: false,
                    );
                  },
                  textSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
