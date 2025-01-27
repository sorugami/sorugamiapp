import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/settings/settings_local_data_source.dart';
import 'package:flutterquiz/ui/styles/theme/app_theme.dart';
import 'package:flutterquiz/utils/constants/string_labels.dart';

class ThemeState {
  const ThemeState(this.appTheme);

  final AppTheme appTheme;
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this.settingsLocalDataSource)
      : super(
          ThemeState(
            settingsLocalDataSource.theme == darkThemeKey
                ? AppTheme.dark
                : AppTheme.light,
          ),
        );

  SettingsLocalDataSource settingsLocalDataSource;

  void changeTheme(AppTheme appTheme) {
    settingsLocalDataSource.theme =
        appTheme == AppTheme.dark ? darkThemeKey : lightThemeKey;
    emit(ThemeState(appTheme));
  }
}
