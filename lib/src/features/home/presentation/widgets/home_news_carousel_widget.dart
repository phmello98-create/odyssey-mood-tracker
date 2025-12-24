// lib/src/features/home/presentation/widgets/home_news_carousel_widget.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:odyssey/src/features/news/presentation/news_screen.dart';
import 'package:odyssey/src/features/news/data/news_image_fetcher.dart';
import 'package:odyssey/src/utils/widgets/odyssey_card.dart';

/// Widget de carrossel de notícias para a home screen
///
/// Exibe notícias do Google News RSS com auto-slide e imagens.
/// Extraído de home_screen.dart para melhor organização.
class HomeNewsCarouselWidget extends StatefulWidget {
  const HomeNewsCarouselWidget({super.key});

  @override
  State<HomeNewsCarouselWidget> createState() => _HomeNewsCarouselWidgetState();
}

class _HomeNewsCarouselWidgetState extends State<HomeNewsCarouselWidget> {
  List<Map<String, String>> _news = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Timer? _autoSlideTimer;

  final Map<int, String> _images = {};
  final Set<int> _loadingImages = {};

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);

    try {
      final articles = await _fetchNewsFromRSS();
      if (mounted) {
        setState(() {
          _news = articles;
          _isLoading = false;
        });
        _startAutoSlide();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    // kick off image loads
    if (_news.isNotEmpty) {
      for (int i = 0; i < _news.length && i < 6; i++) {
        _loadImageForIndex(i);
      }
    }
  }

  String? _getCarouselImage(int index) {
    if (_images.containsKey(index)) return _images[index];
    return null;
  }

  Future<void> _loadImageForIndex(int index) async {
    if (_images.containsKey(index)) return;
    if (_loadingImages.contains(index)) return;
    _loadingImages.add(index);
    try {
      if (index >= _news.length) return;
      final article = _news[index];
      final url = (article['url'] ?? '').toString();

      if (url.isEmpty) return;

      final fastImage = await fetchImageForUrl(url);
      if (fastImage != null && fastImage.isNotEmpty) {
        _images[index] = fastImage;
        if (mounted) setState(() {});
        return;
      }
    } catch (e) {
      debugPrint('[NewsCarousel] image fetch failed for index $index: $e');
    } finally {
      _loadingImages.remove(index);
      if (mounted) setState(() {});
    }
  }

  Future<List<Map<String, String>>> _fetchNewsFromRSS() async {
    try {
      // Google News RSS via RSS2JSON
      final apiUrl = Uri.parse(
        'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent('https://news.google.com/rss?hl=pt-BR&gl=BR&ceid=BR:pt-419')}',
      );

      final response = await http
          .get(apiUrl)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok' && data['items'] != null) {
          return (data['items'] as List)
              .take(6)
              .map(
                (item) => {
                  'title': _stripHtml(item['title'] ?? ''),
                  'source': (item['author'] ?? 'Google News') as String,
                  'url': (item['link'] ?? '') as String,
                },
              )
              .where((n) => n['title']!.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('RSS fetch error: $e');
    }

    // Fallback: Wikipedia
    try {
      final now = DateTime.now();
      final url = Uri.parse(
        'https://pt.wikipedia.org/api/rest_v1/feed/featured/${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}',
      );

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final articles = <Map<String, String>>[];

        if (data['mostread'] != null && data['mostread']['articles'] != null) {
          for (var article in (data['mostread']['articles'] as List).take(6)) {
            if (article['title'] != null &&
                !article['title'].toString().contains(':')) {
              articles.add({
                'title':
                    article['titles']?['normalized'] ?? article['title'] ?? '',
                'source': 'Wikipedia',
                'url': 'https://pt.wikipedia.org/wiki/${article['title']}',
              });
            }
          }
        }

        return articles;
      }
    } catch (e) {
      debugPrint('Wikipedia fetch error: $e');
    }

    return [];
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_news.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _news.length;
          });
        }
      });
    }
  }

  void _nextNews() {
    if (_news.isNotEmpty) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _news.length;
      });
      _startAutoSlide();
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    try {
      var cleaned = url.trim();
      if (cleaned.isEmpty) return;
      if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
        cleaned = 'https://$cleaned';
      }
      final uri = Uri.parse(Uri.encodeFull(cleaned));
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const accentColor = Color(0xFFFF6B6B);

    return OdysseyCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      backgroundColor: colors.surface,
      borderColor: accentColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, accentColor),

          const SizedBox(height: 14),

          // Content
          _buildContent(context, accentColor),

          // Indicators
          if (_news.length > 1) ...[
            const SizedBox(height: 12),
            _buildIndicators(accentColor),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accentColor) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.newspaper_rounded, color: accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notícias',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              if (_news.isNotEmpty)
                Text(
                  '${_currentIndex + 1}/${_news.length}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        // Next button
        if (_news.isNotEmpty)
          GestureDetector(
            onTap: _nextNews,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.skip_next_rounded,
                color: accentColor,
                size: 18,
              ),
            ),
          ),
        const SizedBox(width: 8),
        // See more button
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Ver mais',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Color accentColor) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_news.isEmpty) {
      return GestureDetector(
        onTap: _loadNews,
        child: Row(
          children: [
            Icon(Icons.refresh, size: 16, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              'Toque para carregar notícias',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        final news = _news[_currentIndex];
        if (news['url']?.isNotEmpty == true) {
          _openUrl(news['url']!);
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) {
            _nextNews();
          } else if (details.primaryVelocity! > 0 && _currentIndex > 0) {
            setState(() => _currentIndex--);
            _startAutoSlide();
          }
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          key: ValueKey(_currentIndex),
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading image
              Container(
                width: 64,
                height: 64,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _getCarouselImage(_currentIndex) != null
                    ? Image.network(
                        _getCarouselImage(_currentIndex)!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white24,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.public, color: Colors.white24),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _news[_currentIndex]['title'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.public,
                          size: 12,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _news[_currentIndex]['source'] ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.open_in_new, size: 12, color: accentColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicators(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_news.length.clamp(0, 6), (index) {
        final isActive = index == _currentIndex;
        return Container(
          width: isActive ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? accentColor : accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
