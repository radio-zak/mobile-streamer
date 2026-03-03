import 'package:audio_service/audio_service.dart';
import 'page_manager.dart';
import 'streamer.dart';
import 'package:get_it/get_it.dart';
import 'schedule_service.dart';
import 'now_playing.dart';
import 'favorites_service.dart';

GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  getIt.registerSingleton<AudioHandler>(await initAudioService());
  getIt.registerLazySingleton<PageManager>(() => PageManager());
  getIt.registerLazySingleton<NowPlaying>(() => NowPlaying());
  getIt.registerLazySingleton<ScheduleService>(() => ScheduleService());

  // Initialize FavoritesService
  final favoritesService = FavoritesService();
  await favoritesService.init();
  getIt.registerSingleton<FavoritesService>(favoritesService);
}
