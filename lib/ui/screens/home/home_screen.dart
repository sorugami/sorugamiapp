import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/ads/interstitial_ad_cubit.dart';
import 'package:flutterquiz/features/ads/rewarded_ad_cubit.dart';
import 'package:flutterquiz/features/auth/auth_repository.dart';
import 'package:flutterquiz/features/auth/cubits/refer_and_earn_cubit.dart';
import 'package:flutterquiz/features/badges/cubits/badges_cubit.dart';
import 'package:flutterquiz/features/battle_room/cubits/battle_room_cubit.dart';
import 'package:flutterquiz/features/battle_room/cubits/multi_user_battle_room_cubit.dart';
import 'package:flutterquiz/features/exam/cubits/exam_cubit.dart';
import 'package:flutterquiz/features/leaderboard/cubit/leaderboard_daily_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_score_and_coins_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/profile_management_local_data_source.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/features/quiz/cubits/contest_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quiz_category_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quizzone_category_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/subcategory_cubit.dart';
import 'package:flutterquiz/features/quiz/models/contest.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/ui/screens/battle/create_or_join_screen.dart';
import 'package:flutterquiz/ui/screens/home/widgets/all.dart';
import 'package:flutterquiz/ui/widgets/all.dart';
import 'package:flutterquiz/ui/widgets/blinking_text_widget.dart';
import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:popover/popover.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.isGuest, super.key});

  final bool isGuest;

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static Route<HomeScreen> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<ReferAndEarnCubit>(
            create: (_) => ReferAndEarnCubit(AuthRepository()),
          ),
          BlocProvider<UpdateScoreAndCoinsCubit>(
            create: (_) => UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
          ),
          BlocProvider<UpdateUserDetailCubit>(
            create: (_) => UpdateUserDetailCubit(ProfileManagementRepository()),
          ),
          BlocProvider<LeaderBoardDailyCubit>(
            create: (_) => LeaderBoardDailyCubit(),
          ),
        ],
        child: HomeScreen(isGuest: routeSettings.arguments! as bool),
      ),
    );
  }
}

typedef ZoneType = ({String title, String img, String desc, String informationTitle, String informationDescription});

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  /// Quiz Zone globals
  int oldCategoriesToShowCount = 0;
  int oldContestsToShowCount = 0;
  bool isCateListExpanded = false;
  bool isContestsListExpanded = false;
  bool canExpandCategoryList = false;
  bool canExpandContestsList = true;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final battleZones = <ZoneType>[
    (
      title: 'groupPlay',
      img: Assets.groupBattleIcon,
      desc: 'desGroupPlay',
      informationDescription: 'Gurup Savaşı Açıklaması',
      informationTitle: 'Gurup Savaşı',
    ),
    (
      title: 'battleQuiz',
      img: Assets.oneVsOneIcon,
      desc: 'desBattleQuiz',
      informationDescription: '1 v\\s 1 Savaş Açıklama',
      informationTitle: '1 v\\s 1 Savaş ',
    ),
  ];

  final examZones = <ZoneType>[
    (
      title: 'exam',
      img: Assets.examQuizIcon,
      desc: 'desExam',
      informationDescription: 'Sınav açıklaması',
      informationTitle: 'Sınav',
    ),
    (
      title: 'selfChallenge',
      img: Assets.selfChallengeIcon,
      desc: 'challengeYourselfLbl',
      informationDescription: 'Kendini Test Et açıklaması',
      informationTitle: 'Kendini Test Et',
    ),
  ];

  final playDifferentZones = <ZoneType>[
    (
      title: 'dailyQuiz',
      img: Assets.dailyQuizIcon,
      desc: 'desDailyQuiz',
      informationDescription: 'Günlük Sınav açıklaması',
      informationTitle: 'Günlük Sınav'
    ),
    (
      title: 'funAndLearn',
      img: Assets.funNLearnIcon,
      desc: 'desFunAndLearn',
      informationDescription: 'Dikkatini Görelim açıklaması',
      informationTitle: 'Dikkatini Görelim'
    ),
    (
      title: 'guessTheWord',
      img: Assets.guessTheWordIcon,
      desc: 'desGuessTheWord',
      informationDescription: 'Kelime Oyunu Açıklaması',
      informationTitle: 'Kelime Oyunu'
    ),
    (
      title: 'audioQuestions',
      img: Assets.audioQuizIcon,
      desc: 'desAudioQuestions',
      informationDescription: 'Sesli Sorular açıklaması',
      informationTitle: 'Sesli Sorular açıklaması'
    ),
    (
      title: 'mathMania',
      img: Assets.mathsQuizIcon,
      desc: 'desMathMania',
      informationDescription: 'Özel Sınavlar açıklaması',
      informationTitle: 'Özel Sınavlar'
    ),
    (
      title: 'truefalse',
      img: Assets.trueFalseQuizIcon,
      desc: 'desTrueFalse',
      informationDescription: 'Doğru Yanlış açıklaması',
      informationTitle: 'Doğru\'Yanlış'
    ),
  ];

  // Screen dimensions
  double get scrWidth => context.width;

  double get scrHeight => context.height;

  // HomeScreen horizontal margin, change from here
  double get hzMargin => scrWidth * UiUtils.hzMarginPct;

  double get _statusBarPadding => MediaQuery.of(context).padding.top;

  // TextStyles
  // check build() method
  late var _boldTextStyle = TextStyle(
    fontWeight: FontWeights.bold,
    fontSize: 18,
    color: Theme.of(context).colorScheme.onTertiary,
  );

  ///
  late String _currLangId;
  late final SystemConfigCubit _sysConfigCubit;
  final _quizZoneId = UiUtils.getCategoryTypeNumberFromQuizType(QuizTypes.quizZone);

  @override
  void initState() {
    super.initState();
    showAppUnderMaintenanceDialog();
    setQuizMenu();
    _initLocalNotification();
    checkForUpdates();
    setupInteractedMessage();

    /// Create Ads
    Future.delayed(Duration.zero, () async {
      await context.read<RewardedAdCubit>().createDailyRewardAd(context);
      context.read<InterstitialAdCubit>().createInterstitialAd(context);
    });

    WidgetsBinding.instance.addObserver(this);

    ///
    _currLangId = UiUtils.getCurrentQuizLanguageId(context);
    _sysConfigCubit = context.read<SystemConfigCubit>();
    final quizCubit = context.read<QuizCategoryCubit>();
    final quizZoneCubit = context.read<QuizoneCategoryCubit>();

    if (widget.isGuest) {
      quizCubit.getQuizCategory(languageId: _currLangId, type: _quizZoneId);
      quizZoneCubit.getQuizCategory(languageId: _currLangId);
    } else {
      fetchUserDetails();

      quizCubit.getQuizCategoryWithUserId(
        languageId: _currLangId,
        type: _quizZoneId,
      );
      quizZoneCubit.getQuizCategoryWithUserId(languageId: _currLangId);
      context.read<ContestCubit>().getContest(languageId: _currLangId);
    }
  }

  void showAppUnderMaintenanceDialog() {
    Future.delayed(Duration.zero, () {
      if (_sysConfigCubit.isAppUnderMaintenance) {
        showDialog<void>(
          context: context,
          builder: (_) => const AppUnderMaintenanceDialog(),
        );
      }
    });
  }

  Future<void> _initLocalNotification() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onTapLocalNotification,
    );

    /// Request Permissions for IOS
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions();
    }
  }

  void setQuizMenu() {
    Future.delayed(Duration.zero, () {
      if (!_sysConfigCubit.isDailyQuizEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'dailyQuiz');
      }

      if (!_sysConfigCubit.isTrueFalseQuizEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'truefalse');
      }

      if (!_sysConfigCubit.isFunNLearnEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'funAndLearn');
      }

      if (!_sysConfigCubit.isGuessTheWordEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'guessTheWord');
      }

      if (!_sysConfigCubit.isAudioQuizEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'audioQuestions');
      }

      if (!_sysConfigCubit.isMathQuizEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'mathMania');
      }

      if (!_sysConfigCubit.isExamQuizEnabled) {
        examZones.removeWhere((e) => e.title == 'exam');
      }

      if (!_sysConfigCubit.isSelfChallengeQuizEnabled) {
        examZones.removeWhere((e) => e.title == 'selfChallenge');
      }

      if (!_sysConfigCubit.isGroupBattleEnabled) {
        battleZones.removeWhere((e) => e.title == 'groupPlay');
      }

      if (!_sysConfigCubit.isOneVsOneBattleEnabled && !_sysConfigCubit.isRandomBattleEnabled) {
        battleZones.removeWhere((e) => e.title == 'battleQuiz');
      }
      setState(() {});
    });
  }

  late bool showUpdateContainer = false;

  Future<void> checkForUpdates() async {
    await Future<void>.delayed(Duration.zero);
    if (_sysConfigCubit.isForceUpdateEnable) {
      try {
        final forceUpdate = await UiUtils.forceUpdate(_sysConfigCubit.appVersion);

        if (forceUpdate) {
          setState(() => showUpdateContainer = true);
        }
      } on Exception catch (e) {
        log('Force Update Error', error: e);
      }
    }
  }

  Future<void> setupInteractedMessage() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        announcement: true,
        provisional: true,
      );
    } else {
      final isGranted = (await Permission.notification.status).isGranted;
      if (!isGranted) await Permission.notification.request();
    }
    await FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    // handle background notification
    FirebaseMessaging.onBackgroundMessage(UiUtils.onBackgroundMessage);
    //handle foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Notification arrives : ${message.toMap()}');
      final data = message.data;
      log(data.toString(), name: 'notification data msg');
      final title = data['title'].toString();
      final body = data['body'].toString();
      final type = data['type'].toString();
      final image = data['image'].toString();

      //if notification type is badges then update badges in cubit list
      if (type == 'badges') {
        Future.delayed(Duration.zero, () {
          context.read<BadgesCubit>().unlockBadge(data['badge_type'] as String);
        });
      }

      if (type == 'payment_request') {
        Future.delayed(Duration.zero, () {
          context.read<UserDetailsCubit>().updateCoins(
                addCoin: true,
                coins: int.parse(data['coins'] as String),
              );
        });
      }
      log(image, name: 'notification image data');
      //payload is some data you want to pass in local notification
      if (image != 'null' && image.isNotEmpty) {
        log('image ${image.runtimeType}');
        generateImageNotification(title, body, image, type, type);
      } else {
        generateSimpleNotification(title, body, type);
      }
    });
  }

  //quiz_type according to the notification category
  QuizTypes _getQuizTypeFromCategory(String category) {
    return switch (category) {
      'audio-question-category' => QuizTypes.audioQuestions,
      'guess-the-word-category' => QuizTypes.guessTheWord,
      'fun-n-learn-category' => QuizTypes.funAndLearn,
      _ => QuizTypes.quizZone,
    };
  }

  // notification type is category then move to category screen
  Future<void> _handleMessage(RemoteMessage message) async {
    try {
      if (message.data['type'].toString().contains('category')) {
        await Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': _getQuizTypeFromCategory(message.data['type'] as String),
          },
        );
      } else if (message.data['type'] == 'badges') {
        //if user open app by tapping
        UiUtils.updateBadgesLocally(context);
        await Navigator.of(context).pushNamed(Routes.badges);
      } else if (message.data['type'] == 'payment_request') {
        await Navigator.of(context).pushNamed(Routes.wallet);
      }
    } on Exception catch (e) {
      log(e.toString(), error: e);
    }
  }

  Future<void> _onTapLocalNotification(NotificationResponse? payload) async {
    final type = payload!.payload ?? '';
    if (type == 'badges') {
      await Navigator.of(context).pushNamed(Routes.badges);
    } else if (type.contains('category')) {
      await Navigator.of(context).pushNamed(
        Routes.category,
        arguments: {
          'quizType': _getQuizTypeFromCategory(type),
        },
      );
    } else if (type == 'payment_request') {
      await Navigator.of(context).pushNamed(Routes.wallet);
    }
  }

  Future<void> generateImageNotification(
    String title,
    String msg,
    String image,
    String payloads,
    String type,
  ) async {
    final largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    final bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: msg,
      htmlFormatSummaryText: true,
    );
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      packageName,
      appName,
      icon: '@drawable/ic_notification',
      channelDescription: appName,
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation,
    );
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      msg,
      platformChannelSpecifics,
      payload: payloads,
    );
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }

  // notification on foreground
  Future<void> generateSimpleNotification(
    String title,
    String body,
    String payloads,
  ) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      packageName, //channel id
      appName, //channel name
      channelDescription: appName,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@drawable/ic_notification',
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payloads,
    );
  }

  @override
  void dispose() {
    ProfileManagementLocalDataSource.updateReversedCoins(0);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    //show you left the game
    if (state == AppLifecycleState.resumed) {
      UiUtils.needToUpdateCoinsLocally(context);
    } else {
      ProfileManagementLocalDataSource.updateReversedCoins(0);
    }
  }

  void _onTapProfile() => Navigator.of(context).pushNamed(
        Routes.menuScreen,
        arguments: widget.isGuest,
      );

  void _onTapLeaderboard() => Navigator.of(context).pushNamed(
        widget.isGuest ? Routes.login : Routes.leaderBoard,
      );

  void _onPressedZone(String index) {
    if (widget.isGuest) {
      _showLoginDialog();
      return;
    }

    switch (index) {
      case 'dailyQuiz':
        Navigator.of(context).pushNamed(
          Routes.quiz,
          arguments: {
            'quizType': QuizTypes.dailyQuiz,
            'numberOfPlayer': 1,
            'quizName': 'Daily Quiz',
          },
        );
        return;
      case 'funAndLearn':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.funAndLearn,
          },
        );
        return;
      case 'guessTheWord':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.guessTheWord,
          },
        );
        return;
      case 'audioQuestions':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.audioQuestions,
          },
        );
        return;
      case 'mathMania':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.mathMania,
          },
        );
        return;
      case 'truefalse':
        Navigator.of(context).pushNamed(
          Routes.quiz,
          arguments: {
            'quizType': QuizTypes.trueAndFalse,
            'numberOfPlayer': 1,
            'quizName': 'True/False Quiz',
          },
        );
        return;
    }
  }

  void _onPressedSelfExam(String index) {
    if (widget.isGuest) {
      _showLoginDialog();
      return;
    }

    if (index == 'exam') {
      context.read<ExamCubit>().updateState(ExamInitial());
      Navigator.of(context).pushNamed(Routes.exams);
    } else if (index == 'selfChallenge') {
      context.read<QuizCategoryCubit>().updateState(QuizCategoryInitial());
      context.read<SubCategoryCubit>().updateState(SubCategoryInitial());
      Navigator.of(context).pushNamed(Routes.selfChallenge);
    }
  }

  void _onPressedBattle(String index) {
    if (widget.isGuest) {
      _showLoginDialog();
      return;
    }

    context.read<QuizCategoryCubit>().updateState(QuizCategoryInitial());
    if (index == 'groupPlay') {
      context.read<MultiUserBattleRoomCubit>().updateState(MultiUserBattleRoomInitial());

      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => BlocProvider<UpdateScoreAndCoinsCubit>(
            create: (context) => UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
            child: CreateOrJoinRoomScreen(
              quizType: QuizTypes.groupPlay,
              title: context.tr('groupPlay')!,
            ),
          ),
        ),
      );
    } else if (index == 'battleQuiz') {
      context.read<BattleRoomCubit>().updateState(
            BattleRoomInitial(),
            cancelSubscription: true,
          );

      if (_sysConfigCubit.isRandomBattleEnabled) {
        Navigator.of(context).pushNamed(Routes.randomBattle);
      } else {
        Navigator.of(context).push(
          CupertinoPageRoute<CreateOrJoinRoomScreen>(
            builder: (_) => BlocProvider<UpdateScoreAndCoinsCubit>(
              create: (_) => UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
              child: CreateOrJoinRoomScreen(
                quizType: QuizTypes.oneVsOneBattle,
                title: context.tr('playWithFrdLbl')!,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showLoginDialog() {
    return showLoginDialog(
      context,
      onTapYes: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(Routes.login);
      },
    );
  }

  late String _userName = context.tr('guest')!;
  late String _userProfileImg = Assets.profile('2.png');

  Widget _buildProfileContainer() {
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: _onTapProfile,
        child: Container(
          margin: EdgeInsets.only(
            top: _statusBarPadding * .2,
            left: hzMargin,
            right: hzMargin,
          ),
          width: scrWidth,
          child: LayoutBuilder(
            builder: (_, constraint) {
              final size = context;

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    width: constraint.maxWidth * 0.15,
                    height: constraint.maxWidth * 0.15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: QImage.circular(imageUrl: _userProfileImg),
                  ),
                  SizedBox(width: size.width * .03),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: constraint.maxWidth * 0.5,
                        child: Text(
                          '${context.tr(helloKey)!} ${widget.isGuest ? context.tr('guest')! : _userName}',
                          maxLines: 1,
                          style: _boldTextStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        context.tr(letsPlay)!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                          decorationColor: Theme.of(context).primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  const Spacer(),

                  /// LeaderBoard
                  Container(
                    width: size.width * 0.11,
                    height: size.width * 0.11,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: _onTapLeaderboard,
                      icon: widget.isGuest
                          ? const Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                            )
                          : QImage(
                              imageUrl: Assets.leaderboardIcon,
                              color: Colors.white,
                              width: size.width * 0.08,
                              height: size.width * 0.08,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  /// Settings
                  Container(
                    width: size.width * 0.11,
                    height: size.width * 0.11,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(Routes.settings);
                      },
                      icon: QImage(
                        imageUrl: Assets.settingsIcon,
                        color: Colors.white,
                        width: size.width * 0.08,
                        height: size.width * 0.08,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategory() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hzMargin),
          child: Row(
            children: [
              Text(
                context.tr('quizZone')!,
                style: _boldTextStyle,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.isGuest
                    ? _showLoginDialog()
                    : Navigator.of(context).pushNamed(
                        Routes.category,
                        arguments: {'quizType': QuizTypes.quizZone},
                      ),
                child: const BlinkingTextWidget(viewAllKey: viewAllKey),
              ),
            ],
          ),
        ),
        Wrap(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    margin: EdgeInsets.only(
                      left: hzMargin,
                      right: hzMargin,
                      top: 10,
                      bottom: 26,
                    ),
                    width: context.width,
                    child: quizZoneCategories(),
                  ),
                ),

                /// Expand Arrow
                if (canExpandCategoryList) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    // Position the center bottom arrow, from here
                    bottom: -9,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isCateListExpanded = !isCateListExpanded;
                        }),
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            !isCateListExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContests(Contest livecontest, void Function() onTapPlayNow) {
    return Column(
      children: [
        Wrap(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    width: context.width,
                    child: buildLiveList(livecontest),
                  ),
                ),

                /// Expand Arrow
                if (canExpandContestsList) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    // Position the center bottom arrow, from here
                    bottom: -9,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                        shape: BoxShape.circle,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isContestsListExpanded = !isContestsListExpanded;
                        }),
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            !isContestsListExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget quizZoneCategories() {
    return BlocConsumer<QuizoneCategoryCubit, QuizoneCategoryState>(
      bloc: context.read<QuizoneCategoryCubit>(),
      listener: (context, state) {
        if (state is QuizoneCategoryFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
          }
        }
      },
      builder: (context, state) {
        if (state is QuizoneCategoryFailure) {
          return ErrorContainer(
            showRTryButton: false,
            showBackButton: false,
            showErrorImage: false,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: () {
              context.read<QuizoneCategoryCubit>().getQuizCategoryWithUserId(
                    languageId: UiUtils.getCurrentQuizLanguageId(context),
                  );
            },
          );
        }

        if (state is QuizoneCategorySuccess) {
          final categories = state.categories
            ..removeWhere((element) {
              if (element.categoryName == 'Doğru Yanlış') {
                return true;
              } else if (element.categoryName == 'Savaş Soruları') {
                return true;
              } else {
                return false;
              }
            });
          final int categoriesToShowCount;

          /// Min/Max Categories to Show.
          const minCount = 2;

          /// need to check old cate list with new cate list, when we change languages.
          /// and rebuild the list.
          if (oldCategoriesToShowCount != categories.length) {
            Future.delayed(Duration.zero, () {
              oldCategoriesToShowCount = categories.length;
              canExpandCategoryList = oldCategoriesToShowCount > minCount;
              setState(() {});
            });
          }

          if (!isCateListExpanded) {
            categoriesToShowCount = categories.length <= minCount ? categories.length : minCount;
          } else {
            categoriesToShowCount = categories.length;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: GestureDetector(
                  onTap: () {
                    showPopover(
                      context: context,
                      bodyBuilder: (context) {
                        return CategoryInformationBubbleWidget(
                          title: 'informationTitle',
                          description: 'informationDescription',
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
              ),
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 10),
                shrinkWrap: true,
                itemCount: categoriesToShowCount,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  final category = categories[i];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    onTap: () {
                      if (widget.isGuest) {
                        _showLoginDialog();
                        return;
                      }

                      if (category.isPremium && !category.hasUnlocked) {
                        showUnlockPremiumCategoryDialog(
                          context,
                          categoryId: category.id!,
                          categoryName: category.categoryName!,
                          requiredCoins: category.requiredCoins,
                          isQuizZone: true,
                        );
                        return;
                      }

                      //noOf means how many subcategory it has
                      //if subcategory is 0 then check for level
                      if (category.noOf == '0') {
                        //means this category does not have level
                        if (category.maxLevel == '0') {
                          //direct move to quiz screen pass level as 0
                          Navigator.of(context).pushNamed(
                            Routes.quiz,
                            arguments: {
                              'numberOfPlayer': 1,
                              'quizType': QuizTypes.quizZone,
                              'categoryId': category.id,
                              'subcategoryId': '',
                              'level': '0',
                              'subcategoryMaxLevel': '0',
                              'unlockedLevel': 0,
                              'contestId': '',
                              'comprehensionId': '',
                              'quizName': 'Quiz Zone',
                              'showRetryButton': category.noOfQues! != '0',
                            },
                          );
                        } else {
                          Navigator.of(context).pushNamed(
                            Routes.levels,
                            arguments: {
                              'Category': category,
                            },
                          );
                        }
                      } else {
                        Navigator.of(context).pushNamed(
                          Routes.subcategoryAndLevel,
                          arguments: {
                            'category_id': category.id,
                            'category_name': category.categoryName,
                          },
                        );
                      }
                    },
                    horizontalTitleGap: 15,
                    leading: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: QImage(
                            imageUrl: category.image!,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),

                    /// right_arrow
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PremiumCategoryAccessBadge(
                          hasUnlocked: category.hasUnlocked,
                          isPremium: category.isPremium,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.onTertiary,
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      category.categoryName!,
                      style: _boldTextStyle.copyWith(fontSize: 16),
                    ),
                    subtitle: Text(
                      category.noOf == '0'
                          ? "${context.tr("questionLbl")}: ${category.noOfQues!}"
                          : "${context.tr('subCategoriesLbl')}: ${category.noOf}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        }

        return const Center(child: CircularProgressContainer());
      },
    );
  }

  Widget _buildBattle() {
    return battleZones.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
              left: hzMargin,
              right: hzMargin,
              top: scrHeight * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Zone Title: Battle
                Text(
                  context.tr(battleOfTheDayKey) ?? battleOfTheDayKey, //
                  style: _boldTextStyle,
                ),

                /// Categories
                GridView.count(
                  // Create a grid with 2 columns. If you change the scrollDirection to
                  // horizontal, this produces 2 rows.
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 20,
                  padding: EdgeInsets.only(top: _statusBarPadding * 0.2),
                  crossAxisSpacing: 20,
                  physics: const NeverScrollableScrollPhysics(),
                  // Generate 100 widgets that display their index in the List.
                  children: List.generate(
                    battleZones.length,
                    (i) => QuizGridCard(
                      onTap: () => _onPressedBattle(battleZones[i].title),
                      title: context.tr(battleZones[i].title)!,
                      desc: context.tr(battleZones[i].desc)!,
                      informationTitle: context.tr(battleZones[i].informationTitle)!,
                      informationDescription: context.tr(battleZones[i].informationDescription)!,
                      img: battleZones[i].img,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget _buildExamSelf() {
    return examZones.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
              left: hzMargin,
              right: hzMargin,
              top: scrHeight * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(selfExamZoneKey) ?? selfExamZoneKey,
                  style: _boldTextStyle,
                ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 20,
                  padding: EdgeInsets.only(top: _statusBarPadding * 0.2),
                  crossAxisSpacing: 20,
                  physics: const NeverScrollableScrollPhysics(),
                  // Generate 100 widgets that display their index in the List.
                  children: List.generate(
                    examZones.length,
                    (i) => QuizGridCard(
                      onTap: () => _onPressedSelfExam(examZones[i].title),
                      title: context.tr(examZones[i].title)!,
                      desc: context.tr(examZones[i].desc)!,
                      informationTitle: context.tr(examZones[i].informationTitle)!,
                      informationDescription: context.tr(examZones[i].informationDescription)!,
                      img: examZones[i].img,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget _buildZones() {
    return Padding(
      padding: EdgeInsets.only(
        left: hzMargin,
        right: hzMargin,
        top: scrHeight * 0.04,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (playDifferentZones.isNotEmpty)
            Text(
              context.tr(playDifferentZoneKey) ?? playDifferentZoneKey,
              style: _boldTextStyle,
            )
          else
            const SizedBox(),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 20,
            padding: EdgeInsets.only(
              top: _statusBarPadding * 0.2,
              bottom: _statusBarPadding * 0.6,
            ),
            crossAxisSpacing: 20,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              playDifferentZones.length,
              (i) => QuizGridCard(
                onTap: () => _onPressedZone(playDifferentZones[i].title),
                title: context.tr(playDifferentZones[i].title)!,
                desc: context.tr(playDifferentZones[i].desc)!,
                informationTitle: context.tr(playDifferentZones[i].informationTitle)!,
                informationDescription: context.tr(playDifferentZones[i].informationDescription)!,
                img: playDifferentZones[i].img,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAds() {
    var clicked = false;
    return BlocBuilder<RewardedAdCubit, RewardedAdState>(
      builder: (context, state) {
        if (state is RewardedAdLoaded && context.read<UserDetailsCubit>().isDailyAdAvailable) {
          return GestureDetector(
            onTap: () async {
              if (!clicked) {
                await context.read<RewardedAdCubit>().showDailyAd(context: context);
                clicked = true;
              }
            },
            child: Container(
              margin: EdgeInsets.only(
                left: hzMargin,
                right: hzMargin,
                top: scrHeight * 0.02,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
              ),
              width: scrWidth,
              height: scrWidth * 0.3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      Assets.dailyCoins,
                      width: scrWidth * .23,
                      height: scrWidth * .23,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Text(
                          context.tr('dailyAdsTitle')!,
                          maxLines: 2,
                          style: TextStyle(
                            fontWeight: FontWeights.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${context.tr("get")!} "
                        '${_sysConfigCubit.coinsPerDailyAdView} '
                        "${context.tr("dailyAdsDesc")!}",
                        style: TextStyle(
                          fontWeight: FontWeights.regular,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: .6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget buildLiveList(Contest data) {
    final int contestsToShowCount;
    const minCount = 1;
    final contestsDetailsLength = data.contestDetails.length;

    if (oldContestsToShowCount != contestsDetailsLength) {
      Future.delayed(Duration.zero, () {
        oldContestsToShowCount = contestsDetailsLength;
        canExpandContestsList = oldContestsToShowCount > minCount;
        setState(() {});
      });
    }

    if (!isContestsListExpanded) {
      contestsToShowCount = contestsDetailsLength <= minCount ? contestsDetailsLength : minCount;
    } else {
      contestsToShowCount = contestsDetailsLength;
    }

    return data.errorMessage.isNotEmpty
        ? contestErrorContainer(data)
        : ListView.builder(
            padding: const EdgeInsets.only(bottom: 10),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contestsToShowCount,
            itemBuilder: (_, i) {
              return ContestCard(
                contestDetails: data.contestDetails[i],
                contestType: 1,
              );
            },
          );
  }

  ErrorContainer contestErrorContainer(Contest data) {
    return ErrorContainer(
      showBackButton: false,
      errorMessage: convertErrorCodeToLanguageKey(data.errorMessage),
      onTapRetry: () => context.read<ContestCubit>().getContest(
            languageId: UiUtils.getCurrentQuizLanguageId(context),
          ),
      showErrorImage: true,
    );
  }

  Widget _buildLiveContestSection() {
    void onTapViewAll() {
      if (_sysConfigCubit.isContestEnabled) {
        Navigator.of(context).pushNamed(Routes.contest);
      } else {
        UiUtils.showSnackBar(
          context.tr(currentlyNotAvailableKey)!,
          context,
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hzMargin, vertical: 10),
      child: Column(
        children: [
          /// Contest Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr(contest) ?? contest,
                style: _boldTextStyle,
              ),
              GestureDetector(
                onTap: onTapViewAll,
                child: const BlinkingTextWidget(viewAllKey: viewAllKey),
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// Contest Card
          BlocConsumer<ContestCubit, ContestState>(
            bloc: context.read<ContestCubit>(),
            listener: (context, state) {
              if (state is ContestFailure) {
                if (state.errorMessage == errorCodeUnauthorizedAccess) {
                  showAlreadyLoggedInDialog(context);
                }
              }
            },
            builder: (context, state) {
              if (state is ContestFailure) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    context.tr(
                      convertErrorCodeToLanguageKey(state.errorMessage),
                    )!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeights.regular,
                      color: Theme.of(context).primaryColor,
                    ),
                    maxLines: 2,
                  ),
                );
              }

              if (state is ContestSuccess) {
                final colorScheme = Theme.of(context).colorScheme;

                ///
                final live = state.contestList.live;

                /// No Contest
                if (live.errorMessage.isNotEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      context.tr(
                        convertErrorCodeToLanguageKey(live.errorMessage),
                      )!,
                      style: _boldTextStyle.copyWith(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                }

                final contest = live.contestDetails.first;
                final entryFee = int.parse(contest.entry!);

                void onTapPlayNow() {
                  final userDetailsCubit = context.read<UserDetailsCubit>();

                  if (int.parse(userDetailsCubit.getCoins()!) >= entryFee) {
                    context.read<UpdateScoreAndCoinsCubit>().updateCoins(
                          coins: entryFee,
                          addCoin: false,
                          title: context.tr(playedContestKey) ?? '-',
                        );
                    userDetailsCubit.updateCoins(
                      addCoin: false,
                      coins: entryFee,
                    );

                    Navigator.of(context).pushNamed(
                      Routes.quiz,
                      arguments: {
                        'numberOfPlayer': 1,
                        'quizType': QuizTypes.contest,
                        'contestId': contest.id,
                        'quizName': 'Contest',
                      },
                    );
                  } else {
                    UiUtils.showSnackBar(
                      context.tr(noCoinsMsg)!,
                      context,
                    );
                  }
                }

                return _buildContests(state.contestList.live, onTapPlayNow);
              }

              return const Center(child: CircularProgressContainer());
            },
          ),
        ],
      ),
    );
  }

  String _userRank = '0';
  String _userCoins = '0';
  String _userScore = '0';

  Widget _buildHome() {
    return Stack(
      children: [
        RefreshIndicator(
          color: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          onRefresh: () async {
            fetchUserDetails();

            _currLangId = UiUtils.getCurrentQuizLanguageId(context);
            final quizCubit = context.read<QuizCategoryCubit>();
            final quizZoneCubit = context.read<QuizoneCategoryCubit>();

            if (widget.isGuest) {
              await quizCubit.getQuizCategory(
                languageId: _currLangId,
                type: _quizZoneId,
              );
              await quizZoneCubit.getQuizCategory(languageId: _currLangId);
            } else {
              await quizCubit.getQuizCategoryWithUserId(
                languageId: _currLangId,
                type: _quizZoneId,
              );

              await quizZoneCubit.getQuizCategoryWithUserId(
                languageId: _currLangId,
              );
              await context.read<ContestCubit>().getContest(languageId: _currLangId);
            }
            setState(() {});
          },
          child: ListView(
            children: [
              _buildProfileContainer(),
              UserAchievements(
                userRank: _userRank.isEmpty ? '0' : _userRank,
                userCoins: _userCoins,
                userScore: _userScore.isEmpty ? '0' : _userScore,
                isGuest: widget.isGuest,
              ),
              BlocBuilder<QuizoneCategoryCubit, QuizoneCategoryState>(
                builder: (context, state) {
                  if (state is QuizoneCategoryFailure && state.errorMessage == errorCodeDataNotFound) {
                    return const SizedBox.shrink();
                  }

                  if (_sysConfigCubit.isQuizZoneEnabled) {
                    return _buildCategory();
                  }

                  return const SizedBox.shrink();
                },
              ),
              if (_sysConfigCubit.isAdsEnable && _sysConfigCubit.isDailyAdsEnabled && !widget.isGuest) ...[
                _buildDailyAds(),
              ],
              if (_sysConfigCubit.isContestEnabled && !widget.isGuest) ...[
                _buildLiveContestSection(),
              ],
              _buildBattle(),
              _buildExamSelf(),
              _buildZones(),
            ],
          ),
        ),
        if (showUpdateContainer) const UpdateAppContainer(),
      ],
    );
  }

  void fetchUserDetails() {
    context.read<UserDetailsCubit>().fetchUserDetails();
    context.read<LeaderBoardDailyCubit>().fetchLeaderBoard('1');
  }

  bool profileComplete = false;

  @override
  Widget build(BuildContext context) {
    /// need to add this here, cause textStyle doesn't update automatically when changing theme.
    _boldTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: Theme.of(context).colorScheme.onTertiary,
    );

    return Scaffold(
      body: SafeArea(
        child: widget.isGuest
            ? _buildHome()

            /// Build home with User
            : BlocConsumer<UserDetailsCubit, UserDetailsState>(
                bloc: context.read<UserDetailsCubit>(),
                listener: (context, state) {
                  if (state is UserDetailsFetchSuccess) {
                    UiUtils.fetchBookmarkAndBadges(
                      context: context,
                      userId: state.userProfile.userId!,
                    );
                    if (state.userProfile.profileUrl!.isEmpty || state.userProfile.name!.isEmpty) {
                      if (!profileComplete) {
                        profileComplete = true;

                        Navigator.of(context).pushNamed(
                          Routes.selectProfile,
                          arguments: false,
                        );
                      }
                      return;
                    }
                  } else if (state is UserDetailsFetchFailure) {
                    if (state.errorMessage == errorCodeUnauthorizedAccess) {
                      showAlreadyLoggedInDialog(context);
                    }
                  }
                },
                builder: (context, state) {
                  if (state is UserDetailsFetchInProgress || state is UserDetailsInitial) {
                    return const Center(child: CircularProgressContainer());
                  }
                  if (state is UserDetailsFetchFailure) {
                    return Center(
                      child: ErrorContainer(
                        showBackButton: true,
                        errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
                        onTapRetry: fetchUserDetails,
                        showErrorImage: true,
                      ),
                    );
                  }

                  final user = (state as UserDetailsFetchSuccess).userProfile;

                  _userName = user.name!;
                  _userProfileImg = user.profileUrl!;
                  _userRank = LeaderBoardDailyCubit.rankD;
                  _userCoins = user.coins!;
                  _userScore = LeaderBoardDailyCubit.scoreD;

                  return _buildHome();
                },
              ),
      ),
    );
  }
}

class ContestCard extends StatefulWidget {
  const ContestCard({required this.contestDetails, required this.contestType});

  final ContestDetails contestDetails;
  final int contestType;

  @override
  State<ContestCard> createState() => ContestCardState();
}

class ContestCardState extends State<ContestCard> {
  void _handleOnTap() {
    if (int.parse(context.read<UserDetailsCubit>().getCoins()!) >= int.parse(widget.contestDetails.entry!)) {
      context.read<UpdateScoreAndCoinsCubit>().updateCoins(
            coins: int.parse(widget.contestDetails.entry!),
            addCoin: false,
            title: context.tr(playedContestKey) ?? '-',
          );

      context.read<UserDetailsCubit>().updateCoins(
            addCoin: false,
            coins: int.parse(widget.contestDetails.entry!),
          );
      Navigator.of(context).pushNamed(
        Routes.quiz,
        arguments: {
          'numberOfPlayer': 1,
          'quizType': QuizTypes.contest,
          'contestId': widget.contestDetails.id,
          'quizName': 'Contest',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boldTextStyle = TextStyle(
      fontSize: 14,
      color: Theme.of(context).colorScheme.onTertiary,
      fontWeight: FontWeight.bold,
    );
    final normalTextStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeights.regular,
      color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.6),
    );
    final size = context;

    final verticalDivider = SizedBox(
      width: 1,
      height: 30,
      child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
    );

    return Container(
      margin: const EdgeInsets.all(15),
      width: size.width * .9,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          UiUtils.buildBoxShadow(
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: _handleOnTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: widget.contestDetails.image!,
                placeholder: (_, i) => const Center(
                  child: CircularProgressContainer(),
                ),
                imageBuilder: (_, img) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(image: img, fit: BoxFit.cover),
                    ),
                    height: 171,
                    width: size.width,
                  );
                },
                errorWidget: (_, i, e) => Center(
                  child: Icon(
                    Icons.error,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: size.width * .78),
                    child: Text(
                      widget.contestDetails.name!,
                      style: boldTextStyle,
                    ),
                  ),
                  if (widget.contestDetails.description!.length > 50)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      height: 30,
                      width: 30,
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            widget.contestDetails.showDescription = !widget.contestDetails.showDescription!;
                          });
                        },
                        child: Icon(
                          widget.contestDetails.showDescription!
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Theme.of(context).colorScheme.onTertiary,
                          size: 30,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                ],
              ),
              SizedBox(
                width: !widget.contestDetails.showDescription! ? size.width * .75 : size.width,
                child: Text(
                  widget.contestDetails.description!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.3),
                  ),
                  maxLines: !widget.contestDetails.showDescription! ? 1 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                color: Theme.of(context).scaffoldBackgroundColor,
                height: 0,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('entryFeesLbl')!,
                        style: normalTextStyle,
                      ),
                      Text(
                        '${widget.contestDetails.entry!} ${context.tr('coinsLbl')!}',
                        style: boldTextStyle,
                      ),
                    ],
                  ),

                  ///
                  verticalDivider,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('endsOnLbl')!,
                        style: normalTextStyle,
                      ),
                      Text(
                        widget.contestDetails.endDate!,
                        style: boldTextStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
