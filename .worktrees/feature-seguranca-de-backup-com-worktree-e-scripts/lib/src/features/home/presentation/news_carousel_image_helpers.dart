import 'package:flutter/foundation.dart';
import 'package:odyssey/src/features/news/data/news_image_fetcher.dart';

final Map<int, String> _carouselImages = {};

Future<void> preloadCarouselImages(List<Map<String, String>> news) async {
  if (news.isEmpty) return;
  final futures = <Future>[];
  for (int i = 0; i < news.length && i < 6; i++) {
    final url = news[i]['url'] ?? '';
    if (url.isEmpty) continue;
    futures.add(_loadImage(i, url));
  }
  await Future.wait(futures);
}

Future<void> _loadImage(int index, String url) async {
  try {
    final res = await fetchImageForUrl(url);
    if (res != null && res.isNotEmpty) {
      _carouselImages[index] = res;
    }
  } catch (e) {
    if (kDebugMode) debugPrint('[NewsCarousel] preload image failed: $e');
  }
}

String? getCarouselImage(int index) => _carouselImages[index];
