import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'statistics_repository.dart';

class StatisticsService {
  final StatisticsRepository _repository;
  final AudioHandler _audioHandler;
  Timer? _totalTimeTimer;
  Timer? _sessionTimer;
  int _totalListeningTime = 0;
  int _currentSessionTime = 0;

  StatisticsService(this._repository, this._audioHandler);

  Future<void> init() async {
    await _repository.saveInstallDate();
    _totalListeningTime = await _repository.getTotalListeningTime();

    _audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      if (isPlaying) {
        _startTimers();
      } else {
        _stopTimers();
      }
    });
  }

  Future<DateTime?> getInstallDate() {
    return _repository.getInstallDate();
  }

  Future<int> getTotalListeningTime() {
    return _repository.getTotalListeningTime();
  }

  Future<int> getLongestSession() {
    return _repository.getLongestSession();
  }

  Future<int> getShortestSession() {
    return _repository.getShortestSession();
  }

  void _startTimers() {
    _totalTimeTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _totalListeningTime++;
      if (_totalListeningTime % 10 == 0) {
        _repository.saveTotalListeningTime(_totalListeningTime);
      }
    });
    _sessionTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _currentSessionTime++;
    });
  }

  void _stopTimers() {
    _totalTimeTimer?.cancel();
    _totalTimeTimer = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _updateSessionStats();
    _currentSessionTime = 0;
  }

  Future<void> _updateSessionStats() async {
    if (_currentSessionTime == 0) return;

    final longestSession = await _repository.getLongestSession();
    if (_currentSessionTime > longestSession) {
      await _repository.saveLongestSession(_currentSessionTime);
    }

    final shortestSession = await _repository.getShortestSession();
    if (_currentSessionTime < shortestSession || shortestSession == 0) {
      await _repository.saveShortestSession(_currentSessionTime);
    }
  }

  void dispose() {
    _stopTimers();
    _repository.saveTotalListeningTime(_totalListeningTime);
  }
}
