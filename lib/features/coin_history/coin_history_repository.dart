import 'package:flutterquiz/features/coin_history/coin_history_remote_data_source.dart';
import 'package:flutterquiz/features/coin_history/models/coin_history.dart';

class CoinHistoryRepository {
  factory CoinHistoryRepository() {
    _coinHistoryRepository._coinHistoryRemoteDataSource =
        CoinHistoryRemoteDataSource();
    return _coinHistoryRepository;
  }

  CoinHistoryRepository._internal();

  static final CoinHistoryRepository _coinHistoryRepository =
      CoinHistoryRepository._internal();

  late CoinHistoryRemoteDataSource _coinHistoryRemoteDataSource;

  // then sending again to Map.
  Future<({int total, List<CoinHistory> data})> getCoinHistory({
    required String offset,
    required String limit,
  }) async {
    final (:total, :data) = await _coinHistoryRemoteDataSource.getCoinHistory(
      limit: limit,
      offset: offset,
    );

    return (
      total: total,
      data: data.map(CoinHistory.fromJson).toList(),
    );
  }
}
