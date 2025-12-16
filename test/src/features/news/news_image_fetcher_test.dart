import 'package:flutter_test/flutter_test.dart';
import 'package:odyssey/src/features/news/data/news_image_fetcher.dart' as fetcher;
import 'package:odyssey/src/features/news/data/news_utils.dart' as u;

void main() {
  group('news_image_fetcher', () {
    test('returns og:image from http fetcher', () async {
      const url = 'https://example.com/a1';
      Future<u.FetchResult?> fakeHttp(String url, Map<String, String>? headers) async {
        return u.FetchResult('<html><head><meta property="og:image" content="https://cdn.example.com/http.jpg"></head><body></body></html>', url);
      }
      final result = await fetcher.fetchImageForUrl(url, httpFetcher: fakeHttp, webviewFetcher: (u, h) async => null);
      expect(result, 'https://cdn.example.com/http.jpg');
    }, timeout: const Timeout(Duration(seconds: 4)));

    test('prefers webview fetcher when host demands it', () async {
      const url = 'https://g1.example/article1'; // g1 is in the webviewHosts list
      Future<u.FetchResult?> fakeWebview(String url, Map<String, String>? headers) async {
        return u.FetchResult('<html><head><meta property="og:image" content="https://cdn.example.com/web.jpg"></head></html>', url);
      }
      final result = await fetcher.fetchImageForUrl(url, httpFetcher: (u, h) async => null, webviewFetcher: fakeWebview);
      expect(result, 'https://cdn.example.com/web.jpg');
    });

    test('falls back to http if webview returns null', () async {
      const url = 'https://g1.example/article2';
      Future<u.FetchResult?> fakeWebview(String url, Map<String, String>? headers) async => null;
      Future<u.FetchResult?> fakeHttp(String url, Map<String, String>? headers) async {
        return u.FetchResult('<meta property="og:image" content="https://cdn.example.com/http2.jpg">', url);
      }

      final result = await fetcher.fetchImageForUrl(url, httpFetcher: fakeHttp, webviewFetcher: fakeWebview);
      expect(result, 'https://cdn.example.com/http2.jpg');
    });

    test('follows external link and extracts image', () async {
      const url = 'https://news.google.com/wrapper1';
      Future<u.FetchResult?> fakeHttp(String uUrl, Map<String, String>? headers) async {
        if (uUrl.contains('news.google.com')) {
          // wrapper with encoded external link
          return u.FetchResult('<a href="/r?url=https%3A%2F%2Fexternal.com%2Fart">link</a>', uUrl);
        }
        if (uUrl.contains('external.com')) {
          return u.FetchResult('<meta property="og:image" content="https://external.com/hero.png">', uUrl);
        }
        return null;
      }

      final res = await fetcher.fetchImageForUrl(url, httpFetcher: fakeHttp, webviewFetcher: (u, h) async => null);
      expect(res, 'https://external.com/hero.png');
    });

    test('deduplicates in-flight requests', () async {
      const url = 'https://dedupe.example/test';
      int called = 0;
      Future<u.FetchResult?> fakeHttp(String urlParam, Map<String, String>? h) async {
        called++;
        await Future.delayed(const Duration(milliseconds: 60));
        return u.FetchResult('<meta property="og:image" content="https://cdn.example.com/dedupe.jpg">', urlParam);
      }

      final results = await Future.wait([
        fetcher.fetchImageForUrl(url, httpFetcher: fakeHttp, webviewFetcher: (u, h) async => null),
        fetcher.fetchImageForUrl(url, httpFetcher: fakeHttp, webviewFetcher: (u, h) async => null),
      ]);

      expect(called, 1);
      expect(results[0], 'https://cdn.example.com/dedupe.jpg');
      expect(results[1], 'https://cdn.example.com/dedupe.jpg');
    });
  });
}
