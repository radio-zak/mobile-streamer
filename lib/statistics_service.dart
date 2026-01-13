import 'statistics_repository.dart';

class StatisticsService {
  final StatisticsRepository _repository;

  StatisticsService(this._repository);

  Future<void> init() async {
    await _repository.saveInstallDate();
  }
}
