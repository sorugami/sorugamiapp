import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutterquiz/features/system_config/model/supported_question_language.dart';
import 'package:flutterquiz/features/system_config/model/system_config_model.dart';
import 'package:flutterquiz/features/system_config/model/system_language.dart';
import 'package:flutterquiz/features/system_config/system_config_exception.dart';
import 'package:flutterquiz/features/system_config/system_config_remote_data_source.dart';
import 'package:flutterquiz/utils/constants/error_message_keys.dart';

class SystemConfigRepository {
  factory SystemConfigRepository() {
    _systemConfigRepository._systemConfigRemoteDataSource =
        SystemConfigRemoteDataSource();
    return _systemConfigRepository;
  }

  SystemConfigRepository._internal();

  static final SystemConfigRepository _systemConfigRepository =
      SystemConfigRepository._internal();
  late SystemConfigRemoteDataSource _systemConfigRemoteDataSource;

  Future<SystemConfigModel> getSystemConfig() async {
    try {
      final result = await _systemConfigRemoteDataSource.getSystemConfig();
      log(name: 'System Config', result.toString());
      return SystemConfigModel.fromJson(result);
    } catch (e) {
      log(name: 'System Config Exception', e.toString());
      throw SystemConfigException(errorMessageCode: e.toString());
    }
  }

  Future<List<QuizLanguage>> getSupportedQuestionLanguages() async {
    try {
      final result =
          await _systemConfigRemoteDataSource.getSupportedQuestionLanguages();
      return result.map((e) => QuizLanguage.fromJson(Map.from(e))).toList();
    } catch (e) {
      throw SystemConfigException(errorMessageCode: e.toString());
    }
  }

  Future<List<SystemLanguage>> getSupportedLanguageList() async {
    try {
      final result =
          await _systemConfigRemoteDataSource.getSupportedLanguageList();

      return result.map(SystemLanguage.fromJson).toList();
    } catch (e) {
      throw SystemConfigException(errorMessageCode: e.toString());
    }
  }

  Future<String> getAppSettings(String type) async {
    try {
      final result = await _systemConfigRemoteDataSource.getAppSettings(type);
      return result;
    } catch (e) {
      throw SystemConfigException(errorMessageCode: e.toString());
    }
  }

  Future<List<String>> getImagesFromFile(String fileName) async {
    try {
      final result = await rootBundle.loadString(fileName);
      final images = (jsonDecode(result) as Map)['images'] as List;
      return images.map((e) => e.toString()).toList();
    } on Exception catch (_) {
      throw SystemConfigException(errorMessageCode: errorCodeDefaultMessage);
    }
  }
}
