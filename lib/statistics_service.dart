import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'statistics_repository.dart';

class StatisticsService {
  final StatisticsRepository _repository;
  final AudioHandler _audioHandler;
  Timer? _timer;
  int _totalListeningTime = 0;

  StatisticsService(this._repository, this._audioHandler);

  Future<void> init() async {
    await _repository.saveInstallDate();
    _totalListeningTime = await _repository.getTotalListeningTime();

    _audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      if (isPlaying) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  Future<DateTime?> getInstallDate() {
    return _repository.getInstallDate();
  }

  Future<int> getTotalListeningTime() {
    return _repository.getTotalListeningTime();
  }

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _totalListeningTime++;
      if (_totalListeningTime % 10 == 0) {
        _repository.saveTotalListeningTime(_totalListeningTime);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _stopTimer();
    _repository.saveTotalListeningTime(_totalListeningTime);
  }
}
