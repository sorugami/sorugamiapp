import 'package:flutterquiz/features/report_question/report_question_exception.dart';
import 'package:flutterquiz/features/report_question/report_question_remote_data_source.dart';

class ReportQuestionRepository {
  factory ReportQuestionRepository() {
    _reportQuestionRepository._reportQuestionRemoteDataSource =
        ReportQuestionRemoteDataSource();
    return _reportQuestionRepository;
  }

  ReportQuestionRepository._internal();

  static final ReportQuestionRepository _reportQuestionRepository =
      ReportQuestionRepository._internal();
  late ReportQuestionRemoteDataSource _reportQuestionRemoteDataSource;

  Future<void> reportQuestion({
    required String questionId,
    required String message,
  }) async {
    try {
      await _reportQuestionRemoteDataSource.reportQuestion(
        message: message,
        questionId: questionId,
      );
    } catch (e) {
      throw ReportQuestionException(errorMessageCode: e.toString());
    }
  }
}
