import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/leaderBoard/leaderboard_exception.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

@immutable
abstract class LeaderBoardDailyState {}

class LeaderBoardDailyInitial extends LeaderBoardDailyState {}

class LeaderBoardDailyProgress extends LeaderBoardDailyState {}

class LeaderBoardDailySuccess extends LeaderBoardDailyState {
  LeaderBoardDailySuccess(
    this.leaderBoardDetails,
    this.totalData, {
    required this.hasMore,
  });

  final List<Map<String, dynamic>> leaderBoardDetails;
  final int totalData;
  final bool hasMore;
}

class LeaderBoardDailyFailure extends LeaderBoardDailyState {
  LeaderBoardDailyFailure(this.errorMessage);

  final String errorMessage;
}

class LeaderBoardDailyCubit extends Cubit<LeaderBoardDailyState> {
  LeaderBoardDailyCubit() : super(LeaderBoardDailyInitial()) {}
  static late String profileD;
  static late String nameD;
  static late String scoreD;
  static late String rankD;

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks})> _fetchData({
    required String limit,
    DateTimeRange? dateTimeRange,
    String? offset,
  }) async {
    try {
      final body = <String, String>{
        limitKey: limit,
        offsetKey: offset ?? '',
        'start_date': DateFormat('yyy-MM-dd').format(dateTimeRange?.start ?? DateTime.now()),
        'end_date': DateFormat('yyy-MM-dd').format(dateTimeRange?.end ?? DateTime.now()),
      };

      if (offset == null) body.remove(offset);
      if (dateTimeRange == null) {
        body
          ..remove('start_date')
          ..remove('end_date');
      }

      final response = await http.post(
        Uri.parse(getDailyLeaderboardUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw LeaderBoardException(
          errorMessageCode: responseJson['message'].toString(),
        );
      }

      final total = int.parse(responseJson['total'] as String? ?? '0');
      final data = responseJson['data'] as Map<String, dynamic>;

      if (total != 0) {
        final myRank = data['my_rank'] as Map<String, dynamic>;

        nameD = myRank['name'].toString();
        rankD = myRank['user_rank'].toString();
        profileD = myRank[profileKey].toString();
        scoreD = myRank['score'].toString();
      } else {
        nameD = '';
        rankD = '';
        profileD = '';
        scoreD = '0';
      }

      return (
        total: total,
        otherUsersRanks: (data['other_users_rank'] as List).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      throw LeaderBoardException(errorMessageCode: e.toString());
    }
  }

  Future<void> fetchLeaderBoard(String limit, {DateTimeRange? dateTimeRange}) async {
    emit(LeaderBoardDailyProgress());
    await _fetchData(limit: limit, dateTimeRange: dateTimeRange).then((v) {
      emit(
        LeaderBoardDailySuccess(
          v.otherUsersRanks,
          v.total,
          hasMore: v.total > v.otherUsersRanks.length,
        ),
      );
    }).catchError((dynamic e) {
      emit(LeaderBoardDailyFailure(e.toString()));
    });
  }
}
