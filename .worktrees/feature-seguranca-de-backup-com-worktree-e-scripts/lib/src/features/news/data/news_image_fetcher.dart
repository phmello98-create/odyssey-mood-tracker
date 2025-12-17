import 'package:flutter/foundation.dart';

import 'news_utils.dart' as u;
import '../presentation/news_screen_webview_helpers.dart';

typedef Fetcher = Future<u.FetchResult?> Function(String url, Map<String, String>? headers);

// Simple in-memory cache to avoid duplicate fetches
final Map<String, String> _imageCache = {};
final Map<String, Future<String?>> _inFlight = {};

Future<String?> _doFetchImage(String url, {Map<String, String>? headers, Fetcher? httpFetcher, Fetcher? webviewFetcher}) async {
  final httpFetcher0 = httpFetcher ?? fetchHtmlViaHttp;
  final webviewFetcher0 = webviewFetcher ?? fetchHtmlWithWebView;
  if (url.isEmpty) return null;
  try {
    String baseUrl = url;
    String? html;
    u.FetchResult? result;

    // Decide which method to try first
    if (u.shouldUseWebViewForUrl(url)) {
      result = await webviewFetcher0(url, headers);
    } else {
      result = await httpFetcher0(url, headers);
    }

    // Fallback to alternate method if first failed
    if ((result == null || result.html.isEmpty) && u.shouldUseWebViewForUrl(url)) {
      result = await httpFetcher0(url, headers);
    } else if ((result == null || result.html.isEmpty)) {
      result = await webviewFetcher0(url, headers);
    }
    
    if (result != null) {
      html = result.html;
      if (result.url.isNotEmpty) {
        baseUrl = result.url;
      }
    }

    if (html != null && html.isNotEmpty) {
      final external = u.findExternalLink(html);
      if (external != null && external.isNotEmpty) {
        final extResult = await (u.shouldUseWebViewForUrl(external) ? webviewFetcher0(external, headers) : httpFetcher0(external, headers));
        if (extResult != null && extResult.html.isNotEmpty) {
          html = extResult.html;
          baseUrl = extResult.url.isNotEmpty ? extResult.url : external;
        }
      }

      final extracted = u.extractImageFromHtml(html, baseUrl);
      if (extracted.isNotEmpty && u.isValidImageUrl(extracted)) {
        final normalized = u.normalizeImageUrl(extracted, baseUrl);
        if (normalized.isNotEmpty) return normalized;
      }

      final firstImg = u.extractFirstImgTag(html, baseUrl);
      if (firstImg != null && firstImg.isNotEmpty) {
        final normalized = u.normalizeImageUrl(firstImg, baseUrl);
        if (normalized.isNotEmpty && u.isValidImageUrl(normalized)) return normalized;
      }
    }
  } catch (e) {
    if (kDebugMode) debugPrint('[News] fetchImageForUrl error for $url: $e');
  }
  return null;
}

/// Fetches the best image URL for a given article/page URL using the
/// configured strategy (webview for JS-heavy pages and HTTP otherwise).
Future<String?> fetchImageForUrl(String url, {Map<String, String>? headers, Fetcher? httpFetcher, Fetcher? webviewFetcher}) async {
  if (url.isEmpty) return null;

  // return cached
  if (_imageCache.containsKey(url)) return _imageCache[url];

  // dedupe in-flight requests
  if (_inFlight.containsKey(url)) return _inFlight[url];

  final future = _doFetchImage(url, headers: headers, httpFetcher: httpFetcher, webviewFetcher: webviewFetcher);
  _inFlight[url] = future;
  try {
    final res = await future;
    if (res != null && res.isNotEmpty) {
      _imageCache[url] = res;
    }
    return res;
  } finally {
    _inFlight.remove(url);
  }
}
