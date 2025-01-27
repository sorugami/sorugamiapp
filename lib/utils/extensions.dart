import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/localization/app_localization_cubit.dart';

extension LocalizedLabelsExt on BuildContext {
  String? tr(String key) => read<AppLocalizationCubit>().tr(key) ?? key;
}

extension BuildContextExt on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  double get shortestSide => MediaQuery.sizeOf(this).shortestSide;

  void shouldPop<T extends Object?>([T? result]) {
    if (Navigator.canPop(this)) {
      Navigator.pop(this, result);
    }
  }

  void pushNamed(String routeName, {Object? arguments}) {
    Navigator.pushNamed(this, routeName, arguments: arguments);
  }

  bool get isXSmall => shortestSide < 600;

  bool get isSmall => shortestSide < 905;

  bool get isMedium => shortestSide < 1240;

  bool get isLarge => shortestSide < 1440;
}
