import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/leaderBoard/leaderboard_exception.dart';
import 'package:flutterquiz/features/profile_management/models/information_model.dart';
import 'package:flutterquiz/features/profile_management/models/user_profile.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:flutterquiz/utils/constants/constants.dart';
import 'package:http/http.dart' as http;

@immutable
abstract class UserDetailsState {}

class UserDetailsInitial extends UserDetailsState {}

class UserDetailsFetchInProgress extends UserDetailsState {}

class UserDetailsFetchSuccess extends UserDetailsState {
  UserDetailsFetchSuccess(this.userProfile);

  final UserProfile userProfile;
}

class UserDetailsFetchFailure extends UserDetailsState {
  UserDetailsFetchFailure(this.errorMessage);

  final String errorMessage;
}

class UserDetailsCubit extends Cubit<UserDetailsState> {
  UserDetailsCubit(this._profileManagementRepository) : super(UserDetailsInitial());
  final ProfileManagementRepository _profileManagementRepository;

  Future<List<InformationModel>> fetchAllInformations() async {
    List<InformationModel> allInformations = [];
    final collection = FirebaseFirestore.instance.collection('informations');

    // Dokümanları direkt olarak çek
    final snapshot = await collection.get();
    for (var doc in snapshot.docs) {
      allInformations.add(InformationModel.fromMap(doc.data()));
    }

    return allInformations;
  }

  String rankM = '0';

  //to fetch user details form remote
  Future<void> fetchUserDetails() async {
    emit(UserDetailsFetchInProgress());

    try {
      final userProfile = await _profileManagementRepository.getUserDetailsById();
      await _fetchData(limit: '20');
      emit(UserDetailsFetchSuccess(userProfile));
    } on Exception catch (e) {
      emit(UserDetailsFetchFailure(e.toString()));
    }
  }

  //
  // ignore: avoid_bool_literals_in_conditional_expressions
  bool get isDailyAdAvailable => (state is UserDetailsFetchSuccess) ? (state as UserDetailsFetchSuccess).userProfile.isDailyAdsAvailable ?? false : false;

  Future<bool> watchedDailyAd() async {
    return _profileManagementRepository.watchedDailyAd();
  }

  String getUserName() => state is UserDetailsFetchSuccess ? (state as UserDetailsFetchSuccess).userProfile.name! : '';

  String userId() => state is UserDetailsFetchSuccess ? (state as UserDetailsFetchSuccess).userProfile.userId! : '';

  String getUserFirebaseId() => state is UserDetailsFetchSuccess ? (state as UserDetailsFetchSuccess).userProfile.firebaseId! : '';

  String? getUserMobile() => state is UserDetailsFetchSuccess ? (state as UserDetailsFetchSuccess).userProfile.mobileNumber : '';

  String? getUserEmail() => state is UserDetailsFetchSuccess ? (state as UserDetailsFetchSuccess).userProfile.email : '';

  void updateUserProfileUrl(String profileUrl) {
    if (state is UserDetailsFetchSuccess) {
      final oldUserDetails = (state as UserDetailsFetchSuccess).userProfile;

      emit(
        UserDetailsFetchSuccess(
          oldUserDetails.copyWith(profileUrl: profileUrl),
        ),
      );
    }
  }

  void updateUserProfile({
    String? profileUrl,
    String? name,
    String? allTimeRank,
    String? allTimeScore,
    String? coins,
    String? status,
    String? mobile,
    String? email,
    String? adsRemovedForUser,
  }) {
    if (state is UserDetailsFetchSuccess) {
      final oldUserDetails = (state as UserDetailsFetchSuccess).userProfile;
      final userDetails = oldUserDetails.copyWith(
        email: email,
        mobile: mobile,
        coins: coins,
        allTimeRank: allTimeRank,
        allTimeScore: allTimeScore,
        name: name,
        profileUrl: profileUrl,
        status: status,
        adsRemovedForUser: adsRemovedForUser,
      );

      emit(UserDetailsFetchSuccess(userDetails));
    }
  }

  //update only coins (this will be call only when updating coins after using lifeline )
  void updateCoins({int? coins, bool? addCoin}) {
    //
    if (state is UserDetailsFetchSuccess) {
      final oldUserDetails = (state as UserDetailsFetchSuccess).userProfile;

      final currentCoins = int.parse(oldUserDetails.coins!);
      log('Coins : $currentCoins');
      final updatedCoins = addCoin! ? (currentCoins + coins!) : (currentCoins - coins!);
      log('After Update Coins: $updatedCoins');
      final userDetails = oldUserDetails.copyWith(
        coins: updatedCoins.toString(),
      );
      emit(UserDetailsFetchSuccess(userDetails));
    }
  }

  //update score
  void updateScore(int? score) {
    if (state is UserDetailsFetchSuccess) {
      final oldUserDetails = (state as UserDetailsFetchSuccess).userProfile;
      final currentScore = int.parse(oldUserDetails.allTimeScore!);
      final userDetails = oldUserDetails.copyWith(
        allTimeScore: (currentScore + score!).toString(),
      );
      emit(UserDetailsFetchSuccess(userDetails));
    }
  }

  String? getCoins() => state is UserDetailsFetchSuccess ? (state as UserDetailsFetchSuccess).userProfile.coins : '0';

  UserProfile getUserProfile() => state is UserDetailsFetchSuccess ? (state as UserDetailsFetchSuccess).userProfile : UserProfile();

  //
  // ignore: avoid_bool_literals_in_conditional_expressions
  bool removeAds() => state is UserDetailsFetchSuccess ? (state as UserDetailsFetchSuccess).userProfile.adsRemovedForUser == '1' : false;

  Future<({int total, List<Map<String, dynamic>> otherUsersRanks})> _fetchData({
    required String limit,
    String? offset,
  }) async {
    try {
      final body = <String, String>{
        limitKey: limit,
        offsetKey: offset ?? '',
      };
      if (offset == null) {
        body.remove(offset);
      }
      final response = await http.post(
        Uri.parse(getMonthlyLeaderboardUrl),
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

        rankM = myRank[userRankKey].toString();
      } else {
        rankM = '';
      }

      return (
        total: total,
        otherUsersRanks: (data['other_users_rank'] as List).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      throw LeaderBoardException(errorMessageCode: e.toString());
    }
  }
}
