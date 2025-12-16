import 'package:flutter_test/flutter_test.dart';
import 'package:odyssey/src/features/news/data/news_utils.dart' as u;

void main() {
  group('news_utils - url normalization', () {
    test('normalize relative path with base', () {
      final n = u.normalizeImageUrl('/images/foo.jpg', 'https://example.com/path/');
      expect(n, 'https://example.com/images/foo.jpg');
    });

    test('normalize protocol-relative', () {
      final n = u.normalizeImageUrl('//cdn.example.com/img.jpg');
      expect(n, 'https://cdn.example.com/img.jpg');
    });

    test('normalize without protocol', () {
      final n = u.normalizeImageUrl('cdn.example.com/img.jpg');
      expect(n, 'https://cdn.example.com/img.jpg');
    });

    test('ignore data URIs', () {
      final n = u.normalizeImageUrl('data:image/png;base64,abc');
      expect(n, '');
    });
  });

  group('news_utils - image extraction', () {
    test('extract from og:image meta', () {
      const html = '<meta property="og:image" content="https://example.com/img.jpg">';
      final s = u.extractImageFromHtml(html, 'https://example.com');
      expect(s, 'https://example.com/img.jpg');
    });

    test('extract first <img> fallback', () {
      const html = '<div><img src="/img/a.jpg"></div>';
      final s = u.extractImageFromHtml(html, 'https://example.com');
      expect(s, 'https://example.com/img/a.jpg');
    });

    test('extract from json-ld', () {
      const html = '<script type="application/ld+json">{"@type": "Article", "image": "https://example.com/hero.jpg"}</script>';
      final s = u.extractImageFromHtml(html, 'https://example.com');
      expect(s, 'https://example.com/hero.jpg');
    });

    test('srcset picks highest quality', () {
      const html = '<img srcset="https://example.com/a.jpg 500w, https://example.com/b.jpg 1000w">';
      final s = u.extractImageFromHtml(html, 'https://example.com');
      expect(s, 'https://example.com/b.jpg');
      });

    test('bg image extraction', () {
      const html = '<div style="background-image: url(/images/bg.png);"></div>';
      final s = u.extractImageFromHtml(html, 'https://example.com');
      expect(s, 'https://example.com/images/bg.png');
    });
  });

  group('news_utils - external link extraction', () {
    test('extract amphtml', () {
      const html = '<link rel="amphtml" href="https://external.com/article">';
      final s = u.findExternalLink(html);
      expect(s, 'https://external.com/article');
    });

    test('extract canonical from og:url', () {
      const html = '<meta property="og:url" content="https://external.com/article">';
      final s = u.findExternalLink(html);
      expect(s, 'https://external.com/article');
    });

    test('extract anchor with encoded url', () {
      const html = '<a href="/articles/abc?url=https%3A%2F%2Fexternal.com%2Farticle">link</a>';
      final s = u.findExternalLink(html);
      expect(s, 'https://external.com/article');
    });
  });
}
