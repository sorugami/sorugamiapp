import 'package:flutter/material.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/utils/constants/fonts.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class UserAchievements extends StatelessWidget {
  const UserAchievements({
    required this.isGuest,
    super.key,
    this.userRank = '0',
    this.userCoins = '0',
    this.userScore = '0',
  });

  final String userRank;
  final String userCoins;
  final String userScore;
  final bool isGuest;

  static const _verticalDivider = VerticalDivider(
    color: Color(0x99FFFFFF),
    indent: 12,
    endIndent: 14,
    thickness: 2,
  );

  @override
  Widget build(BuildContext context) {
    final rank = context.tr('rankLbl')!;
    final coins = context.tr('coinsLbl')!;
    final score = context.tr('scoreLbl')!;

    void onTapCoins() => Navigator.of(context).pushNamed(
          isGuest ? Routes.login : Routes.coinHistory,
        );

    void onTapLeaderboard() => Navigator.of(context).pushNamed(
          isGuest ? Routes.login : Routes.leaderBoard,
        );

    return LayoutBuilder(
      builder: (_, constraints) {
        final size = context;
        final numberFormat = NumberFormat.compact();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 105,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12.5,
                horizontal: 20,
              ),
              margin: EdgeInsets.symmetric(
                vertical: (size.height * UiUtils.vtMarginPct) - 10,
                horizontal: size.width * UiUtils.hzMarginPct,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: onTapLeaderboard,
                    child: _Achievement(
                      title: rank,
                      value: numberFormat.format(double.parse(userRank)),
                    ),
                  ),
                  _verticalDivider,
                  GestureDetector(
                    onTap: onTapCoins,
                    child: _Achievement(
                      title: coins,
                      value: numberFormat.format(double.parse(userCoins)),
                    ),
                  ),
                  _verticalDivider,
                  GestureDetector(
                    onTap: onTapCoins,
                    child: _Achievement(
                      title: score,
                      value: numberFormat.format(double.parse(userScore)),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await _launchURL();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 16,
                ),
                margin: EdgeInsets.symmetric(
                      horizontal: size.width * UiUtils.hzMarginPct,
                    ) +
                    EdgeInsets.only(
                      bottom: size.height * UiUtils.vtMarginPct,
                    ),
                child: Center(
                  child: Text(
                    'Ödülleri görmek için tıklayınız.',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 14,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          decorationColor: Colors.white,
                          fontWeight: FontWeights.bold,
                        ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
}

class _Achievement extends StatelessWidget {
  const _Achievement({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeights.bold,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeights.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
