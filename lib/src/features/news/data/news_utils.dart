import 'dart:convert';

class FetchResult {
  final String html;
  final String url;
  
  const FetchResult(this.html, this.url);
}

String decodeUrl(String url) {
  try {
    return Uri.decodeFull(url.replaceAll('&amp;', '&'));
  } catch (_) {
    return url.replaceAll('&amp;', '&');
  }
}

String normalizeImageUrl(String url, [String? baseUrl]) {
  if (url.isEmpty) return '';
  var u = url.trim();
  u = u.replaceAll('&amp;', '&');
  if (u.startsWith('//')) return 'https:$u';
  if (u.startsWith('data:')) return '';
  if (u.startsWith('/')) {
    if (baseUrl != null) {
      try {
        final b = Uri.parse(baseUrl);
        return '${b.scheme}://${b.host}$u';
      } catch (_) {}
    }
  }
  if (!u.startsWith('http')) {
    if (baseUrl != null) {
      try {
        final b = Uri.parse(baseUrl);
        final scheme = b.scheme.isNotEmpty ? b.scheme : 'https';
        final host = b.host;
        final path = u.startsWith('/') ? u.substring(1) : u;
        return '$scheme://$host/$path';
      } catch (_) {}
    }
    return 'https://$u';
  }
  return u;
}

bool _isInternalHost(String? host) {
  if (host == null) return true;
  final h = host.toLowerCase();
  return h.contains('google') || h.contains('gstatic') || h.contains('googleusercontent') || h.contains('accounts.google');
}

bool isGoogleHost(String? host) {
  if (host == null) return true;
  final h = host.toLowerCase();
  return h.contains('google') || h.contains('gstatic') || h.contains('googleusercontent');
}

bool isNewsHost(String host) {
  final newsHosts = [
    'g1.', 'globo.', 'uol.', 'folha.', 'estadao.', 'terra.', 'r7.',
    'canaltech.', 'tecmundo.', 'olhardigital.', 'tecnoblog.', 'segs.',
    'bbc.', 'cnn.', 'reuters.', 'nytimes.', 'theguardian.',
    'wired.', 'techcrunch.', 'forbes.', 'nature.', 'science.',
    'ifpe.edu.', 'usp.br', 'unicamp.br', 'ufrj.br',
    '.com.br', '.org.br', '.edu.br', '.gov.br',
  ];
  for (final h in newsHosts) {
    if (host.contains(h)) return true;
  }
  return false;
}

bool isValidImageUrl(String url) {
  if (url.isEmpty) return false;
  final lowerUrl = url.toLowerCase();
  final invalidPatterns = [
    '1x1',
    'pixel',
    'spacer',
    'blank',
    'transparent',
    'data:image',
    'base64',
    'loading=',
    'placeholder',
    'loader',
    'tracker',
  ];
  for (final pattern in invalidPatterns) {
    if (lowerUrl.contains(pattern)) return false;
  }
  return true;
}

String? extractFirstImgTag(String html, [String? baseUrl]) {
  if (html.isEmpty) return null;
  final match = RegExp(r'''<img[^>]+src=["']([^"']+)["']''', caseSensitive: false).firstMatch(html);
  if (match != null) {
    final raw = match.group(1) ?? '';
    if (raw.isEmpty) return null;
    final url = normalizeImageUrl(raw, baseUrl);
    return url;
  }
  return null;
}

String? extractFromJsonLd(dynamic data) {
  if (data is Map<String, dynamic>) {
    final imageFields = ['image', 'thumbnailUrl', 'contentUrl', 'primaryImageOfPage'];
    for (final field in imageFields) {
      if (data.containsKey(field)) {
        final value = data[field];
        if (value is String && value.isNotEmpty) {
          return value;
        } else if (value is Map<String, dynamic>) {
          if (value.containsKey('url')) return value['url'] as String?;
          if (value.containsKey('@id')) return value['@id'] as String?;
          if (value.containsKey('contentUrl')) return value['contentUrl'] as String?;
        } else if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String) return first;
          if (first is Map<String, dynamic>) {
            if (first.containsKey('url')) return first['url'] as String?;
            if (first.containsKey('@id')) return first['@id'] as String?;
            if (first.containsKey('contentUrl')) return first['contentUrl'] as String?;
          }
        }
      }
    }
    if (data.containsKey('@graph') && data['@graph'] is List) {
      for (final item in data['@graph']) {
        final result = extractFromJsonLd(item);
        if (result != null) return result;
      }
    }
  } else if (data is List) {
    for (final item in data) {
      final result = extractFromJsonLd(item);
      if (result != null) return result;
    }
  }
  return null;
}

String extractImageFromHtml(String html, [String? baseUrl]) {
  if (html.isEmpty) return '';
  final metaPatterns = [
    r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']''',
    r'''<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']''',
    r'''<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']''',
    r'''<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image["']''',
    r'''<meta[^>]+property=["']twitter:image:src["'][^>]+content=["']([^"']+)["']''',
    r'''<meta[^>]+name=["']thumbnail["'][^>]+content=["']([^"']+)["']''',
    r'''<meta[^>]+property=["']image["'][^>]+content=["']([^"']+)["']''',
  ];
  for (final pattern in metaPatterns) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(html);
    if (match != null) {
      final url = match.group(1) ?? '';
      if (url.isNotEmpty && isValidImageUrl(url)) {
        return normalizeImageUrl(url, baseUrl);
      }
    }
  }
  final linkPatterns = [
    r'''<link[^>]+rel=["']image_src["'][^>]+href=["']([^"']+)["']''',
    r'''<link[^>]+href=["']([^"']+)["'][^>]+rel=["']image_src["']''',
    r'''<link[^>]+rel=["']preload["'][^>]+as=["']image["'][^>]+href=["']([^"']+)["']''',
  ];
  for (final pattern in linkPatterns) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(html);
    if (match != null) {
      final url = match.group(1) ?? '';
      if (url.isNotEmpty && isValidImageUrl(url)) {
        return normalizeImageUrl(url, baseUrl);
      }
    }
  }
  final jsonLdMatch = RegExp(r'''<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>''', caseSensitive: false, dotAll: true).firstMatch(html);
  if (jsonLdMatch != null) {
    final jsonStr = jsonLdMatch.group(1) ?? '';
    try {
      final jsonData = jsonDecode(jsonStr);
      final imageUrl = extractFromJsonLd(jsonData);
      if (imageUrl != null && imageUrl.isNotEmpty && isValidImageUrl(imageUrl)) {
        return normalizeImageUrl(imageUrl, baseUrl);
      }
    } catch (_) {}
  }
  final srcsetMatch = RegExp(r'''srcset=["']([^"']+)["']''', caseSensitive: false).firstMatch(html);
  if (srcsetMatch != null) {
    final parts = srcsetMatch.group(1)!.split(',').map((s) => s.trim()).toList();
    if (parts.isNotEmpty) {
      final last = parts.last.split(RegExp(r'\s+'))[0];
      if (isValidImageUrl(last)) {
        return normalizeImageUrl(last, baseUrl);
      }
    }
  }
  final dataPatterns = [
    r'''data-src=["']([^"']+)["']''',
    r'''data-original=["']([^"']+)["']''',
    r'''data-lazy-src=["']([^"']+)["']''',
    r'''data-lazy=["']([^"']+)["']''',
    r'''data-image=["']([^"']+)["']''',
    r'''data-featured-image=["']([^"']+)["']''',
    r'''data-bg=["']([^"']+)["']''',
  ];
  for (final pattern in dataPatterns) {
    final matches = RegExp(pattern, caseSensitive: false).allMatches(html);
    for (final match in matches) {
      final url = match.group(1) ?? '';
      if (url.isNotEmpty && isValidImageUrl(url)) {
        return normalizeImageUrl(url, baseUrl);
      }
    }
  }
  final bgMatch = RegExp(r'''background-image:\s*url\(['"]?([^'"\)]+)['"]?\)''', caseSensitive: false).firstMatch(html);
  if (bgMatch != null) {
    var url = bgMatch.group(1) ?? '';
    url = url.replaceAll(RegExp(r'''['"]'''), '');
    if (url.isNotEmpty && isValidImageUrl(url)) {
      return normalizeImageUrl(url, baseUrl);
    }
  }
  final imgMatches = RegExp(r'''<img[^>]+src=["']([^"']+)["']''', caseSensitive: false).allMatches(html);
  String? firstFallback;
  for (final match in imgMatches) {
    final url = match.group(1) ?? '';
    if (url.isEmpty) continue;
    final normalized = normalizeImageUrl(url, baseUrl);
    if (normalized.isEmpty) continue;
    if (isValidImageUrl(normalized)) return normalized;
    firstFallback ??= normalized;
  }
  if (firstFallback != null) return firstFallback;
  try {
    final canonicalMatch = RegExp(r'''<link[^>]+rel=["']canonical["'][^>]+href=["']([^"']+)["']''', caseSensitive: false).firstMatch(html);
    if (canonicalMatch != null) {
      final canonical = canonicalMatch.group(1) ?? '';
      final uri = Uri.tryParse(canonical);
      if (uri != null && !_isInternalHost(uri.host)) {
        return normalizeImageUrl(canonical, canonical);
      }
    }
  } catch (_) {}
  return '';
}

String? findExternalLink(String html) {
  if (html.isEmpty) return null;
  final ampMatch = RegExp(r'''<link[^>]+rel=["']amphtml["'][^>]+href=["']([^"']+)["']''', caseSensitive: false).firstMatch(html);
  if (ampMatch != null) {
    final amp = decodeUrl(ampMatch.group(1) ?? '');
    final uri = Uri.tryParse(amp);
    if (uri != null && !isGoogleHost(uri.host)) return amp;
  }
  final canonicalMatch = RegExp(r'''<link[^>]+rel=["']canonical["'][^>]+href=["']([^"']+)["']''', caseSensitive: false).firstMatch(html);
  if (canonicalMatch != null) {
    final canonical = decodeUrl(canonicalMatch.group(1) ?? '');
    final uri = Uri.tryParse(canonical);
    if (uri != null && !isGoogleHost(uri.host)) return canonical;
  }
  final ogUrlMatch = RegExp(r'''<meta[^>]+property=["']og:url["'][^>]+content=["']([^"']+)["']''', caseSensitive: false).firstMatch(html);
  if (ogUrlMatch != null) {
    final ogUrl = decodeUrl(ogUrlMatch.group(1) ?? '');
    final uri = Uri.tryParse(ogUrl);
    if (uri != null && !isGoogleHost(uri.host)) return ogUrl;
  }
  final articleUrlMatch = RegExp(r'''<meta[^>]+property=["']article:url["'][^>]+content=["']([^"']+)["']''', caseSensitive: false).firstMatch(html);
  if (articleUrlMatch != null) {
    final articleUrl = decodeUrl(articleUrlMatch.group(1) ?? '');
    final uri = Uri.tryParse(articleUrl);
    if (uri != null && !isGoogleHost(uri.host)) return articleUrl;
  }
  final anchorMatches = RegExp(r'''<a[^>]+href=["']([^"']+)["']''', caseSensitive: false).allMatches(html);
  for (final match in anchorMatches) {
    final raw = match.group(1) ?? '';
    final href = decodeUrl(raw);
    if (href.isEmpty) continue;
    try {
      final uri = Uri.tryParse(href);
      if (uri != null) {
        final target = uri.queryParameters['url'] ?? uri.queryParameters['u'];
        if (target != null && target.isNotEmpty) {
          final decoded = decodeUrl(target);
          final dUri = Uri.tryParse(decoded);
          if (dUri != null && !isGoogleHost(dUri.host)) return decoded;
        }
        if (!isGoogleHost(uri.host)) {
          if (isNewsHost(uri.host) || true) return href;
        }
      } else {
        final withScheme = href.startsWith('//') ? 'https:$href' : 'https://$href';
        final wUri = Uri.tryParse(withScheme);
        if (wUri != null && !isGoogleHost(wUri.host)) return withScheme;
      }
    } catch (_) {}
  }
  return null;
}

bool shouldUseWebViewForUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  try {
    final uri = Uri.tryParse(url);
    return uri != null && shouldUseWebViewForHost(uri.host);
  } catch (_) {
    return false;
  }
}

bool shouldUseWebViewForHost(String? host) {
  if (host == null || host.isEmpty) return false;
  final h = host.toLowerCase();
  final webviewHosts = [
    'g1.', 'globo.', 'uol.', 'folha.', 'estadao.', 'terra.', 'r7.',
    'canaltech.', 'tecmundo.', 'olhardigital.', 'tecnoblog.',
    'bbc.', 'cnn.', 'reuters.', 'nytimes.', 'theguardian.',
    'wired.', 'techcrunch.', 'forbes.', 'nature.', 'science.',
    'medium.', 'flipboard.', 'reddit.', 'news.google.com', 'pt.wikipedia.org',
  ];
  for (final w in webviewHosts) {
    if (h.contains(w)) return true;
  }
  return false;
}
