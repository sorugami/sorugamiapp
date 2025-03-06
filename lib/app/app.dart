import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/ads/interstitial_ad_cubit.dart';
import 'package:flutterquiz/features/ads/rewarded_ad_cubit.dart';
import 'package:flutterquiz/features/auth/auth_repository.dart';
import 'package:flutterquiz/features/auth/cubits/auth_cubit.dart';
import 'package:flutterquiz/features/badges/badges_repository.dart';
import 'package:flutterquiz/features/badges/cubits/badges_cubit.dart';
import 'package:flutterquiz/features/battle_room/battle_room_repository.dart';
import 'package:flutterquiz/features/battle_room/cubits/battle_room_cubit.dart';
import 'package:flutterquiz/features/battle_room/cubits/multi_user_battle_room_cubit.dart';
import 'package:flutterquiz/features/bookmark/bookmark_repository.dart';
import 'package:flutterquiz/features/bookmark/cubits/audio_question_bookmark_cubit.dart';
import 'package:flutterquiz/features/bookmark/cubits/bookmark_cubit.dart';
import 'package:flutterquiz/features/bookmark/cubits/guess_the_word_bookmark_cubit.dart';
import 'package:flutterquiz/features/exam/cubits/exam_cubit.dart';
import 'package:flutterquiz/features/exam/exam_repository.dart';
import 'package:flutterquiz/features/localization/app_localization_cubit.dart';
import 'package:flutterquiz/features/localization/quiz_language_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/features/quiz/cubits/comprehension_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/contest_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quiz_category_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quizzone_category_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/subcategory_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/unlock_premium_category_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/unlocked_level_cubit.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';
import 'package:flutterquiz/features/settings/settings_cubit.dart';
import 'package:flutterquiz/features/settings/settings_local_data_source.dart';
import 'package:flutterquiz/features/settings/settings_repository.dart';
import 'package:flutterquiz/features/statistic/cubits/statistics_cubit.dart';
import 'package:flutterquiz/features/statistic/statistic_repository.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/features/system_config/system_config_repository.dart';
import 'package:flutterquiz/ui/styles/theme/app_theme.dart';
import 'package:flutterquiz/ui/styles/theme/theme_cubit.dart';
import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<Widget> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);

  // Local phone storage
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(authBox);
  await Hive.openBox<dynamic>(settingsBox);
  await Hive.openBox<dynamic>(userDetailsBox);
  await Hive.openBox<dynamic>(examBox);

  return const MyApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    precacheImage(const AssetImage(Assets.mapFinded), context);
    precacheImage(const AssetImage(Assets.mapFinding), context);
    precacheImage(const AssetImage(Assets.scratchCardCover), context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(SettingsLocalDataSource()),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(SettingsRepository()),
        ),
        BlocProvider<AuthCubit>(create: (_) => AuthCubit(AuthRepository())),
        BlocProvider<AppLocalizationCubit>(
          create: (_) => AppLocalizationCubit(SettingsRepository()),
        ),
        BlocProvider<QuizLanguageCubit>(
          create: (_) => QuizLanguageCubit(SettingsLocalDataSource()),
        ),
        BlocProvider<UserDetailsCubit>(
          create: (_) => UserDetailsCubit(ProfileManagementRepository()),
        ),
        //bookmark questions of quiz zone
        BlocProvider<BookmarkCubit>(
          create: (_) => BookmarkCubit(BookmarkRepository()),
        ),
        BlocProvider<GuessTheWordBookmarkCubit>(
          create: (_) => GuessTheWordBookmarkCubit(BookmarkRepository()),
        ),
        BlocProvider<AudioQuestionBookmarkCubit>(
          create: (_) => AudioQuestionBookmarkCubit(BookmarkRepository()),
        ),
        BlocProvider<MultiUserBattleRoomCubit>(
          create: (_) => MultiUserBattleRoomCubit(BattleRoomRepository()),
        ),
        BlocProvider<BattleRoomCubit>(
          create: (_) => BattleRoomCubit(BattleRoomRepository()),
        ),
        BlocProvider<SystemConfigCubit>(
          create: (_) => SystemConfigCubit(SystemConfigRepository()),
        ),
        BlocProvider<BadgesCubit>(
          create: (_) => BadgesCubit(BadgesRepository()),
        ),
        BlocProvider<StatisticCubit>(
          create: (_) => StatisticCubit(StatisticRepository()),
        ),
        BlocProvider<InterstitialAdCubit>(create: (_) => InterstitialAdCubit()),
        BlocProvider<RewardedAdCubit>(create: (_) => RewardedAdCubit()),
        BlocProvider<ExamCubit>(create: (_) => ExamCubit(ExamRepository())),
        BlocProvider<ComprehensionCubit>(
          create: (_) => ComprehensionCubit(QuizRepository()),
        ),
        BlocProvider<ContestCubit>(
          create: (_) => ContestCubit(QuizRepository()),
        ),
        //
        BlocProvider<QuizCategoryCubit>(
          create: (_) => QuizCategoryCubit(QuizRepository()),
        ),
        BlocProvider<QuizoneCategoryCubit>(
          create: (_) => QuizoneCategoryCubit(QuizRepository()),
        ),
        BlocProvider<UnlockedLevelCubit>(
          create: (_) => UnlockedLevelCubit(QuizRepository()),
        ),
        BlocProvider<SubCategoryCubit>(
          create: (_) => SubCategoryCubit(QuizRepository()),
        ),
        BlocProvider<UnlockPremiumCategoryCubit>(
          create: (_) => UnlockPremiumCategoryCubit(QuizRepository()),
        ),
      ],
      child: Builder(
        builder: (context) {
          final currentTheme = context.select<ThemeCubit, AppTheme>(
            (bloc) => bloc.state.appTheme,
          );
          final isRTL = context.select<AppLocalizationCubit, bool>(
            (bloc) => bloc.state.language.isRTL,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: (currentTheme == AppTheme.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
                .copyWith(statusBarColor: Colors.transparent),
            child: MaterialApp(
              title: appName,
              builder: (_, widget) {
                return ScrollConfiguration(
                  behavior: const _GlobalScrollBehavior(),
                  child: Directionality(
                    textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                    child: widget!,
                  ),
                );
              },
              theme: appThemeData[currentTheme],
              debugShowCheckedModeBanner: false,
              initialRoute: Routes.splash,
              onGenerateRoute: Routes.onGenerateRouted,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('tr', 'TR'), // Türkçe yerel ayarı
                Locale('en', 'US'), // İngilizce yerel ayarı
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlobalScrollBehavior extends ScrollBehavior {
  const _GlobalScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(_) => const BouncingScrollPhysics();
}
