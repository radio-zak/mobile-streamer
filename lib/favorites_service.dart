import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_shows';
  final _logger = Logger('FavoritesService');
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Adds a show to favorites
  Future<void> addFavorite(String showTitle) async {
    try {
      final favorites = _prefs.getStringList(_favoritesKey) ?? [];
      if (!favorites.contains(showTitle)) {
        favorites.add(showTitle);
        await _prefs.setStringList(_favoritesKey, favorites);
        _logger.info('Added favorite: $showTitle');
      }
    } catch (e) {
      _logger.severe('Failed to add favorite: $e');
    }
  }

  /// Removes a show from favorites
  Future<void> removeFavorite(String showTitle) async {
    try {
      final favorites = _prefs.getStringList(_favoritesKey) ?? [];
      favorites.remove(showTitle);
      await _prefs.setStringList(_favoritesKey, favorites);
      _logger.info('Removed favorite: $showTitle');
    } catch (e) {
      _logger.severe('Failed to remove favorite: $e');
    }
  }

  /// Checks if a show is in favorites
  bool isFavorite(String showTitle) {
    try {
      final favorites = _prefs.getStringList(_favoritesKey) ?? [];
      return favorites.contains(showTitle);
    } catch (e) {
      _logger.severe('Failed to check favorite: $e');
      return false;
    }
  }

  /// Gets all favorites
  List<String> getFavorites() {
    try {
      return _prefs.getStringList(_favoritesKey) ?? [];
    } catch (e) {
      _logger.severe('Failed to get favorites: $e');
      return [];
    }
  }
}

