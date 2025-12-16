import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/news_utils.dart';

Future<FetchResult?> fetchHtmlViaHttp(String url, Map<String, String>? headers) async {
  try {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final res = await http.get(uri, headers: headers ?? {}).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      try {
        if (kDebugMode) await _saveHtmlDebug(url, res.body, label: 'http');
      } catch (_) {}
      return FetchResult(res.body, res.request?.url.toString() ?? url);
    }
  } catch (_) {}
  return null;
}

Future<String?> _saveHtmlDebug(String url, String html, {String? label}) async {
  if (!kDebugMode) return null;
  if (kIsWeb) return null;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/news_debug');
    if (!await folder.exists()) await folder.create(recursive: true);
    final safeTs = DateTime.now().toIso8601String().replaceAll(':', '-');
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? 'unknown';
    final name = '${safeTs}_${host}_${label ?? 'page'}.html';
    final file = File('${folder.path}/$name');
    await file.writeAsString(html);
    debugPrint('[NewsWebView] saved debug html: ${file.path}');
    return file.path;
  } catch (e) {
    debugPrint('[NewsWebView] debug save failed: $e');
    return null;
  }
}

Future<FetchResult?> fetchHtmlWithWebView(String url, Map<String, String>? headers, {Duration timeout = const Duration(seconds: 12)}) async {
  // For unit tests and non-mobile platforms, fallback to HTTP fetch
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      // Use HeadlessInAppWebView to render page and return HTML
      final completer = Completer<FetchResult?>();
      
      HeadlessInAppWebView? headless;

      headless = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url), headers: headers),
        onLoadStop: (controller, loadedUrl) async {
          try {
            final html = await controller.evaluateJavascript(source: 'document.documentElement.outerHTML');
            if (!completer.isCompleted) {
               completer.complete(FetchResult(html?.toString() ?? '', loadedUrl?.toString() ?? url));
            }
            await headless?.dispose();
          } catch (e) {
            if (!completer.isCompleted) completer.complete(null);
            await headless?.dispose();
          }
        },
        onLoadError: (controller, url, code, message) async {
          if (!completer.isCompleted) completer.complete(null);
          await headless?.dispose();
        },
        onConsoleMessage: (controller, msg) {
          debugPrint('[NewsWebView] Console: ${msg.message}');
        },
        onLoadHttpError: (controller, url, statusCode, description) async {
          if (!completer.isCompleted) completer.complete(null);
          await headless?.dispose();
        },
      );

      await headless.run();

      return await completer.future.timeout(timeout, onTimeout: () async {
        try {
          await headless?.dispose();
        } catch (_) {}
        return null;
      }).then((result) async {
        if (result != null && result.html.isNotEmpty) {
          try {
            if (kDebugMode) await _saveHtmlDebug(url, result.html, label: 'webview');
          } catch (_) {}
        }
        return result;
      });
    } catch (e) {
      debugPrint('[NewsWebView] Error: $e');
      // fallback to HTTP fetch
      return await fetchHtmlViaHttp(url, headers);
    }
  }

  // Not supported platform or web - fallback to HTTP fetch
  return await fetchHtmlViaHttp(url, headers);
}

