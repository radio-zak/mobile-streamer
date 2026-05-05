import 'package:flutter/material.dart';
import 'package:zakstreamer/service_locator.dart';
import 'package:zakstreamer/recently_played_service.dart';
import 'package:logging/logging.dart';

class RecentlyPlayedPage extends StatefulWidget {
  const RecentlyPlayedPage({super.key});

  @override
  State<RecentlyPlayedPage> createState() => _RecentlyPlayedPageState();
}

class _RecentlyPlayedPageState extends State<RecentlyPlayedPage> {
  List<RecentlyPlayedEntry>? _entries;
  Object? _error;
  bool _isLoading = true;

  final log = Logger('RecentlyPlayed');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await getIt<RecentlyPlayedService>().fetchRecentlyPlayed();
      if (!mounted) return;
      setState(() {
        _entries = data;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      log.severe('Error fetching recently played: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Text(
          'Ostatnio grane',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _fetchData();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Nie udało się załadować listy.\nBłąd: $_error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    if (_entries == null || _entries!.isEmpty) {
      return Center(
        child: Text(
          'Brak danych o ostatnio granych utworach.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _entries!.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 84,
        endIndent: 16,
        color: Color(0xFF333333),
      ),
      itemBuilder: (context, index) {
        final entry = _entries![index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Okładka lub Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 52,
                  height: 52,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: entry.imageUrl != null
                      ? Image.network(
                          entry.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildPlaceholder(isLoading: true);
                          },
                        )
                      : _buildPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),
              // Tytuł i Artysta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Czas
              Text(
                entry.time,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Center(
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary.withAlpha(100),
              ),
            )
          : Icon(
              Icons.music_note,
              color: Theme.of(context).colorScheme.primary.withAlpha(150),
            ),
    );
  }
}
