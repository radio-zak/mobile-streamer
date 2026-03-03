import 'package:flutter/material.dart';
import 'package:zakstreamer/service_locator.dart';
import 'package:zakstreamer/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final String showTitle;
  final VoidCallback? onFavoriteChanged;

  const FavoriteButton({
    super.key,
    required this.showTitle,
    this.onFavoriteChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = getIt<FavoritesService>().isFavorite(widget.showTitle);
  }

  Future<void> _toggleFavorite() async {
    final favoritesService = getIt<FavoritesService>();

    if (_isFavorite) {
      await favoritesService.removeFavorite(widget.showTitle);
    } else {
      await favoritesService.addFavorite(widget.showTitle);
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    widget.onFavoriteChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: _toggleFavorite,
      tooltip: _isFavorite ? 'Usuń z ulubionych' : 'Dodaj do ulubionych',
    );
  }
}

