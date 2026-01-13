import 'package:audio_service/audio_service.dart';
import 'page_manager.dart';
import 'statistics_repository.dart';
import 'statistics_service.dart';
import 'streamer.dart';
import 'package:get_it/get_it.dart';
import 'schedule_service.dart';
import 'now_playing.dart';

GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  getIt.registerSingleton<AudioHandler>(await initAudioService());
  getIt.registerLazySingleton<PageManager>(() => PageManager());
  getIt.registerLazySingleton<NowPlaying>(() => NowPlaying());
  getIt.registerLazySingleton<ScheduleService>(() => ScheduleService());

  // Statistics
  getIt.registerLazySingleton<StatisticsRepository>(() => StatisticsRepository());
  getIt.registerLazySingleton<StatisticsService>(
      () => StatisticsService(getIt<StatisticsRepository>()));
}
