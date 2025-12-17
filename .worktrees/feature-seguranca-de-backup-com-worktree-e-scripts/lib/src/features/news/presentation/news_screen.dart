import 'dart:async';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import 'package:odyssey/src/features/news/data/news_utils.dart' as u;
import 'news_screen_webview_helpers.dart';
import 'package:odyssey/src/features/news/data/news_image_fetcher.dart';
import 'package:odyssey/src/utils/settings_provider.dart';
import 'package:odyssey/src/features/onboarding/services/showcase_service.dart' as showcase;

class NewsArticle {
  final String title;
  final String source;
  final String url;
  final String image;
  final String description;
  final DateTime? publishedAt;
  final List<String> tags;
  final String? feedSource;

  const NewsArticle({
    required this.title,
    required this.source,
    required this.url,
    this.image = '',
    this.description = '',
    this.publishedAt,
    this.tags = const [],
    this.feedSource,
  });

  String get formattedDate {
    if (publishedAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(publishedAt!);
    
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd MMM', 'pt_BR').format(publishedAt!);
  }

  String get formattedTime {
    if (publishedAt == null) return '';
    return DateFormat('HH:mm').format(publishedAt!);
  }

  String get fullFormattedDate {
    if (publishedAt == null) return '';
    return DateFormat("dd 'de' MMMM, HH:mm", 'pt_BR').format(publishedAt!);
  }

  int get readingTime {
    final words = description.split(' ').length + title.split(' ').length;
    return (words / 200).ceil().clamp(1, 15);
  }
}

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> with TickerProviderStateMixin {
  bool _loading = true;
  List<NewsArticle> _articles = [];
  List<NewsArticle> _filteredArticles = [];
  final Map<int, String> _images = {};
  final Set<int> _loadingImages = {};
  String _selectedCategory = 'Todas';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _shimmerController;
  String _loadingStatus = 'Iniciando...';
  int _sourcesLoaded = 0;
  
  // Showcase keys
  final GlobalKey _showcaseCategories = GlobalKey();
  final GlobalKey _showcaseSearch = GlobalKey();
  final GlobalKey _showcaseArticle = GlobalKey();
  
  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Todas', 'icon': Icons.apps_rounded, 'color': Color(0xFF6366F1)},
    {'name': 'Tecnologia', 'icon': Icons.memory_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Ciência', 'icon': Icons.science_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'Saúde', 'icon': Icons.favorite_rounded, 'color': Color(0xFFEF4444)},
    {'name': 'Mente', 'icon': Icons.psychology_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'Biologia', 'icon': Icons.biotech_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Filosofia', 'icon': Icons.auto_stories_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'IA', 'icon': Icons.smart_toy_rounded, 'color': Color(0xFF14B8A6)},
  ];

  static const List<Map<String, String>> _rssFeeds = [
    // Google News - Tópicos específicos
    {'name': 'Google Tech', 'url': 'https://news.google.com/rss/topics/CAAqJggKIiBDQkFTRWdvSUwyMHZNRGRqTVhZU0FuQjBHZ0pDVWlnQVAB?hl=pt-BR&gl=BR&ceid=BR:pt-419', 'category': 'Tecnologia'},
    {'name': 'Google Ciência', 'url': 'https://news.google.com/rss/topics/CAAqJggKIiBDQkFTRWdvSUwyMHZNRFp0Y1RjU0FuQjBHZ0pDVWlnQVAB?hl=pt-BR&gl=BR&ceid=BR:pt-419', 'category': 'Ciência'},
    {'name': 'Google Saúde', 'url': 'https://news.google.com/rss/topics/CAAqIQgKIhtDQkFTRGdvSUwyMHZNR3QwTlRFU0FuQjBLQUFQAQ?hl=pt-BR&gl=BR&ceid=BR:pt-419', 'category': 'Saúde'},
    
    // Tech News Internacional
    {'name': 'Ars Technica', 'url': 'https://feeds.arstechnica.com/arstechnica/science', 'category': 'Ciência'},
    {'name': 'Hacker News', 'url': 'https://hnrss.org/frontpage', 'category': 'Tecnologia'},
    {'name': 'MIT Tech Review', 'url': 'https://www.technologyreview.com/feed/', 'category': 'Tecnologia'},
    {'name': 'Wired Science', 'url': 'https://www.wired.com/feed/category/science/latest/rss', 'category': 'Ciência'},
    
    // Ciência
    {'name': 'Science Daily', 'url': 'https://www.sciencedaily.com/rss/mind_brain.xml', 'category': 'Mente'},
    {'name': 'Science Daily Bio', 'url': 'https://www.sciencedaily.com/rss/plants_animals.xml', 'category': 'Biologia'},
    {'name': 'Nature News', 'url': 'https://www.nature.com/nature.rss', 'category': 'Ciência'},
    {'name': 'Phys.org', 'url': 'https://phys.org/rss-feed/science-news/', 'category': 'Ciência'},
    
    // Mente & Cognição
    {'name': 'Psychology Today', 'url': 'https://www.psychologytoday.com/intl/blog/feed', 'category': 'Mente'},
    {'name': 'Brain Pickings', 'url': 'https://www.themarginalian.org/feed/', 'category': 'Filosofia'},
    {'name': 'Neuroscience News', 'url': 'https://neurosciencenews.com/feed/', 'category': 'Mente'},
    
    // IA & Machine Learning
    {'name': 'AI News', 'url': 'https://www.artificialintelligence-news.com/feed/', 'category': 'IA'},
    {'name': 'OpenAI Blog', 'url': 'https://openai.com/blog/rss/', 'category': 'IA'},
    {'name': 'DeepMind', 'url': 'https://deepmind.com/blog/feed/basic/', 'category': 'IA'},
    
    // Tech Brasil
    {'name': 'Tecnoblog', 'url': 'https://tecnoblog.net/feed/', 'category': 'Tecnologia'},
    {'name': 'Olhar Digital', 'url': 'https://olhardigital.com.br/feed/', 'category': 'Tecnologia'},
    {'name': 'Canaltech', 'url': 'https://canaltech.com.br/rss/', 'category': 'Tecnologia'},
  ];

  @override
  void initState() {
    super.initState();
    _initShowcase();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _loadNews();
    _searchController.addListener(_filterArticles);
  }

  void _initShowcase() {
    final keys = [_showcaseCategories, _showcaseSearch, _showcaseArticle];
    showcase.ShowcaseService.registerForScreen(
      tour: showcase.ShowcaseTour.news,
      firstAndLastKeys: [keys.first, keys.last],
    );
    showcase.ShowcaseService.startIfNeeded(showcase.ShowcaseTour.news, keys);
  }

  void _startTour() {
    final keys = [_showcaseCategories, _showcaseSearch, _showcaseArticle];
    showcase.ShowcaseService.start(showcase.ShowcaseTour.news, keys);
  }

  @override
  void dispose() {
    showcase.ShowcaseService.unregisterScreen(showcase.ShowcaseTour.news);
    _shimmerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isPoliticalContent(NewsArticle article) {
    final blockedTerms = [
      'bolsonaro', 'lula', 'trump', 'biden', 'política', 'politica',
      'eleição', 'eleicao', 'eleições', 'eleicoes', 'governo', 
      'presidente', 'ministro', 'senador', 'deputado', 'congresso',
      'partido', 'petista', 'bolsonarista', 'esquerda', 'direita',
      'político', 'politico', 'política', 'políticos', 'politicos',
      'votação', 'votacao', 'plenário', 'plenario', 'senado',
      'câmara', 'camara', 'planalto', 'pt ', ' pt', 'psl', 'psdb',
      'mdb', 'pdob', 'psol', 'pcb', 'pcdob', 'supremo', 'stf',
      'mandato', 'impeachment', 'golpe', 'ditadura', 'democracia',
      'candidato', 'prefeitura', 'prefeito', 'governador', 'vereador'
    ];
    
    final content = '${article.title} ${article.description} ${article.source}'.toLowerCase();
    
    return blockedTerms.any((term) => content.contains(term));
  }

  void _filterArticles() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty && _selectedCategory == 'Todas') {
        _filteredArticles = _articles.where((article) => !_isPoliticalContent(article)).toList();
      } else {
        _filteredArticles = _articles.where((article) {
          if (_isPoliticalContent(article)) return false;
          
          final matchesSearch = query.isEmpty ||
              article.title.toLowerCase().contains(query) ||
              article.source.toLowerCase().contains(query) ||
              article.description.toLowerCase().contains(query) ||
              article.tags.any((tag) => tag.toLowerCase().contains(query));
          
          final matchesCategory = _selectedCategory == 'Todas' ||
              article.tags.any((tag) => tag.toLowerCase() == _selectedCategory.toLowerCase()) ||
              (article.feedSource?.toLowerCase().contains(_selectedCategory.toLowerCase()) ?? false);
          
          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
  }

  Future<void> _loadNews() async {
    setState(() {
      _loading = true;
      _loadingStatus = 'Iniciando...';
      _sourcesLoaded = 0;
    });
    
    final allArticles = <NewsArticle>[];
    
    try {
      // Carregar todas as fontes em paralelo
      final futures = <Future<List<NewsArticle>>>[];
      
      for (final feed in _rssFeeds) {
        futures.add(_fetchFromRSS(feed['url']!, feed['name']!, feed['category']!));
      }
      
      // Adicionar Hacker News API
      futures.add(_fetchHackerNews());
      
      // Adicionar Wikipedia
      futures.add(_fetchWikipedia());
      
      final results = await Future.wait(futures, eagerError: false);
      
      for (final result in results) {
        allArticles.addAll(result);
      }
      
      // Ordenar por data (mais recentes primeiro)
      allArticles.sort((a, b) {
        if (a.publishedAt == null && b.publishedAt == null) return 0;
        if (a.publishedAt == null) return 1;
        if (b.publishedAt == null) return -1;
        return b.publishedAt!.compareTo(a.publishedAt!);
      });
      
      // Remover duplicatas baseado no título
      final seen = <String>{};
      final uniqueArticles = <NewsArticle>[];
      for (final article in allArticles) {
        final key = article.title.toLowerCase().trim();
        if (!seen.contains(key) && key.length > 10) {
          seen.add(key);
          uniqueArticles.add(article);
        }
      }
      
      if (mounted) {
        setState(() {
          _articles = uniqueArticles;
          _filteredArticles = uniqueArticles;
        });
      }
      
      _loadAllImagesConcurrently();
      
    } catch (e) {
      debugPrint('[News] load error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingStatus = '';
        });
      }
    }
  }

  Future<List<NewsArticle>> _fetchFromRSS(String feedUrl, String feedName, String category) async {
    final articles = <NewsArticle>[];
    
    try {
      final apiUrl = Uri.parse('https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(feedUrl)}');
      final res = await http.get(apiUrl).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'ok' && data['items'] != null) {
          for (final item in (data['items'] as List).take(15)) {
            final title = _stripHtml(item['title'] ?? '');
            if (title.isEmpty || title.length < 10) continue;
            
            final source = (item['author'] ?? feedName).toString();
            final url = (item['link'] ?? '').toString();
            final description = _stripHtml(item['description'] ?? '');
            
            String image = '';
            if (item['thumbnail'] != null && item['thumbnail'].toString().isNotEmpty) {
              image = item['thumbnail'].toString();
            }
            if (image.isEmpty && item['enclosure'] != null) {
              final enclosure = item['enclosure'];
              if (enclosure is Map && enclosure['link'] != null) {
                image = enclosure['link'].toString();
              }
            }
            
            DateTime? publishedAt;
            if (item['pubDate'] != null) {
              try {
                publishedAt = DateTime.parse(item['pubDate'].toString());
              } catch (_) {
                publishedAt = DateTime.now();
              }
            }
            
            final tags = _extractTags(title, source, category);
            
            articles.add(NewsArticle(
              title: title,
              source: source.isNotEmpty ? source : feedName,
              url: url,
              image: image,
              description: description,
              publishedAt: publishedAt,
              tags: tags,
              feedSource: category,
            ));
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _sourcesLoaded++;
          _loadingStatus = 'Carregando: $feedName';
        });
      }
    } catch (e) {
      debugPrint('[News] RSS error for $feedName: $e');
    }
    
    return articles;
  }

  Future<List<NewsArticle>> _fetchHackerNews() async {
    final articles = <NewsArticle>[];
    
    try {
      final topStoriesRes = await http.get(
        Uri.parse('https://hacker-news.firebaseio.com/v0/topstories.json'),
      ).timeout(const Duration(seconds: 8));
      
      if (topStoriesRes.statusCode == 200) {
        final storyIds = (jsonDecode(topStoriesRes.body) as List).take(20);
        
        for (final id in storyIds) {
          try {
            final storyRes = await http.get(
              Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json'),
            ).timeout(const Duration(seconds: 5));
            
            if (storyRes.statusCode == 200) {
              final story = jsonDecode(storyRes.body);
              if (story != null && story['title'] != null && story['url'] != null) {
                articles.add(NewsArticle(
                  title: story['title'] ?? '',
                  source: 'Hacker News',
                  url: story['url'] ?? 'https://news.ycombinator.com/item?id=$id',
                  description: '${story['score'] ?? 0} pontos • ${story['descendants'] ?? 0} comentários',
                  publishedAt: DateTime.fromMillisecondsSinceEpoch((story['time'] ?? 0) * 1000),
                  tags: ['Tecnologia', 'HN'],
                  feedSource: 'Tecnologia',
                ));
              }
            }
          } catch (_) {}
        }
      }
      
      if (mounted) {
        setState(() {
          _sourcesLoaded++;
          _loadingStatus = 'Carregando: Hacker News';
        });
      }
    } catch (e) {
      debugPrint('[News] HN error: $e');
    }
    
    return articles;
  }

  Future<List<NewsArticle>> _fetchWikipedia() async {
    final articles = <NewsArticle>[];
    
    try {
      final now = DateTime.now();
      final url = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/feed/featured/${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}'
      );
      
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        
        // Artigo do dia
        if (data['tfa'] != null) {
          final tfa = data['tfa'];
          articles.add(NewsArticle(
            title: tfa['titles']?['normalized'] ?? tfa['title'] ?? '',
            source: 'Wikipedia',
            url: tfa['content_urls']?['desktop']?['page'] ?? '',
            description: tfa['extract'] ?? '',
            publishedAt: DateTime.now(),
            tags: const ['Wikipedia', 'Conhecimento'],
            image: tfa['thumbnail']?['source'] ?? '',
            feedSource: 'Ciência',
          ));
        }
        
        // Artigos mais lidos
        if (data['mostread']?['articles'] != null) {
          for (final article in (data['mostread']['articles'] as List).take(10)) {
            if (article['titles'] != null) {
              articles.add(NewsArticle(
                title: article['titles']?['normalized'] ?? article['title'] ?? '',
                source: 'Wikipedia',
                url: article['content_urls']?['desktop']?['page'] ?? 'https://en.wikipedia.org/wiki/${article['title']}',
                description: article['extract'] ?? '',
                publishedAt: DateTime.now(),
                tags: const ['Wikipedia', 'Tendências'],
                image: article['thumbnail']?['source'] ?? '',
                feedSource: 'Ciência',
              ));
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _sourcesLoaded++;
          _loadingStatus = 'Carregando: Wikipedia';
        });
      }
    } catch (e) {
      debugPrint('[News] Wikipedia error: $e');
    }
    
    return articles;
  }

  List<String> _extractTags(String title, String source, String feedCategory) {
    final tags = <String>[feedCategory];
    final lowerTitle = title.toLowerCase();
    
    const categoryKeywords = {
      'Tecnologia': ['tech', 'tecnologia', 'software', 'hardware', 'programação', 'developer', 'code', 'app', 'startup', 'digital'],
      'IA': ['ia', 'inteligência artificial', 'ai', 'machine learning', 'deep learning', 'neural', 'gpt', 'chatgpt', 'openai', 'llm', 'modelo de linguagem'],
      'Ciência': ['ciência', 'science', 'research', 'estudo', 'descoberta', 'cientistas', 'pesquisa', 'experimento'],
      'Saúde': ['saúde', 'health', 'médico', 'medicina', 'doença', 'tratamento', 'hospital', 'terapia', 'bem-estar'],
      'Mente': ['mente', 'cérebro', 'brain', 'cognição', 'psicologia', 'mental', 'neurociência', 'neuroscience', 'consciência', 'memória', 'aprendizado'],
      'Biologia': ['biologia', 'biology', 'genética', 'dna', 'células', 'evolução', 'organismo', 'vida', 'espécies', 'ecossistema'],
      'Filosofia': ['filosofia', 'philosophy', 'ética', 'existência', 'consciência', 'pensamento', 'razão', 'metafísica'],
    };
    
    for (final entry in categoryKeywords.entries) {
      if (entry.key == feedCategory) continue;
      for (final keyword in entry.value) {
        if (lowerTitle.contains(keyword)) {
          if (!tags.contains(entry.key)) {
            tags.add(entry.key);
          }
          break;
        }
      }
    }
    
    // Adicionar fonte se relevante
    if (source.isNotEmpty && source != 'Google News' && !tags.contains(source)) {
      if (tags.length < 3) tags.add(source);
    }
    
    return tags.take(3).toList();
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
        .replaceAll('&hellip;', '...')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _loadAllImagesConcurrently() async {
    const int concurrency = 3;
    for (int i = 0; i < _articles.length; i += concurrency) {
      final batch = <Future>[];
      for (int j = i; j < i + concurrency && j < _articles.length; j++) {
        batch.add(_loadImageForIndex(j));
      }
      await Future.wait(batch);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _loadImageForIndex(int index) async {
    if (_images.containsKey(index)) return;
    if (_loadingImages.contains(index)) return;
    _loadingImages.add(index);
    
    try {
      final article = _articles[index];
      String image = article.image;
      final url = article.url;

      if (image.isNotEmpty && u.isValidImageUrl(image)) {
        final normalized = u.normalizeImageUrl(image, url);
        if (normalized.isNotEmpty) {
          _images[index] = normalized;
          if (mounted) setState(() {});
          return;
        }
      }

      if (url.isEmpty) return;

      final settings = ref.read(settingsProvider);
      final fastImage = await fetchImageForUrl(url);
      if (fastImage != null && fastImage.isNotEmpty) {
        _images[index] = fastImage;
        if (mounted) setState(() {});
        return;
      }

      if (!settings.newsUseWebViewFallback) return;

      String? html;
      String baseUrl = url;
      u.FetchResult? result;

      if (u.shouldUseWebViewForUrl(url)) {
        result = await fetchHtmlWithWebView(url, null);
      } else {
        result = await fetchHtmlViaHttp(url, null);
      }

      if ((result == null || result.html.isEmpty) && u.shouldUseWebViewForUrl(url)) {
        result = await fetchHtmlViaHttp(url, null);
      } else if (result == null || result.html.isEmpty) {
        result = await fetchHtmlWithWebView(url, null);
      }

      if (result != null) {
        html = result.html;
        if (result.url.isNotEmpty) baseUrl = result.url;
      }

      if (html != null && html.isNotEmpty) {
        final external = u.findExternalLink(html);
        if (external != null && external.isNotEmpty) {
          final extResult = await (u.shouldUseWebViewForUrl(external) 
            ? fetchHtmlWithWebView(external, null) 
            : fetchHtmlViaHttp(external, null));
          if (extResult != null && extResult.html.isNotEmpty) {
            html = extResult.html;
            baseUrl = extResult.url.isNotEmpty ? extResult.url : external;
          }
        }

        final extracted = u.extractImageFromHtml(html, baseUrl);
        if (extracted.isNotEmpty && u.isValidImageUrl(extracted)) {
          final normalized = u.normalizeImageUrl(extracted, baseUrl);
          if (normalized.isNotEmpty) {
            _images[index] = normalized;
            if (mounted) setState(() {});
            return;
          }
        }

        final firstImg = u.extractFirstImgTag(html, baseUrl);
        if (firstImg != null && firstImg.isNotEmpty) {
          final normalized = u.normalizeImageUrl(firstImg, baseUrl);
          if (normalized.isNotEmpty && u.isValidImageUrl(normalized)) {
            _images[index] = normalized;
            if (mounted) setState(() {});
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[News] image fetch failed for index $index: $e');
    } finally {
      _loadingImages.remove(index);
      if (mounted) setState(() {});
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    var cleaned = url.trim();
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }
    final uri = Uri.parse(Uri.encodeFull(cleaned));
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[News] open url error: $e');
    }
  }

  Color _getCategoryColor(String categoryName) {
    final category = _categories.firstWhere(
      (c) => c['name'].toString().toLowerCase() == categoryName.toLowerCase(),
      orElse: () => {'color': const Color(0xFF6366F1)},
    );
    return category['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            _buildSearchBar(colors),
            _buildCategoryChips(colors),
            Expanded(
              child: _loading
                  ? _buildLoadingView(colors)
                  : RefreshIndicator(
                      onRefresh: _loadNews,
                      color: colors.primary,
                      backgroundColor: colors.surface,
                      child: _buildNewsList(colors),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.explore_rounded,
              size: 22,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descobrir',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _loading 
                      ? '$_sourcesLoaded/${_rssFeeds.length + 2} fontes'
                      : '${_filteredArticles.length} artigos • ${_rssFeeds.length + 2} fontes',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(
            icon: Icons.refresh_rounded,
            onTap: _loadNews,
            colors: colors,
            isLoading: _loading,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colors,
    bool isLoading = false,
  }) {
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              : Icon(icon, size: 22, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colors) {
    final hasText = _searchController.text.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasText 
              ? colors.primary.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: hasText ? [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasText ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.search_rounded,
              color: hasText ? colors.onPrimary : colors.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar em ${_articles.length} artigos...',
                hintStyle: TextStyle(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (hasText)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    _filterArticles();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.error,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ColorScheme colors) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category['name'] == _selectedCategory;
          final categoryColor = category['color'] as Color;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _selectedCategory = category['name'] as String);
                  _filterArticles();
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? LinearGradient(
                            colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingView(ColorScheme colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                _loadingStatus,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _sourcesLoaded / (_rssFeeds.length + 2),
                  backgroundColor: colors.surfaceContainerHighest,
                  color: colors.primary,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            itemBuilder: (context, index) => AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) => _buildShimmerCard(colors),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard(ColorScheme colors) {
    final shimmerGradient = LinearGradient(
      begin: Alignment(-1.0 + _shimmerController.value * 3, 0),
      end: Alignment(_shimmerController.value * 3, 0),
      colors: [
        colors.surfaceContainerHighest,
        colors.surfaceContainerHighest.withValues(alpha: 0.5),
        colors.surfaceContainerHighest,
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: shimmerGradient,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 24,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: shimmerGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 24,
                      width: 50,
                      decoration: BoxDecoration(
                        gradient: shimmerGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 18,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: shimmerGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 18,
                  width: 200,
                  decoration: BoxDecoration(
                    gradient: shimmerGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList(ColorScheme colors) {
    if (_filteredArticles.isEmpty) {
      return _buildEmptyState(colors);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _filteredArticles.length,
      itemBuilder: (context, index) {
        final articleIndex = _articles.indexOf(_filteredArticles[index]);
        return _buildNewsCard(index, articleIndex, colors);
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    final isSearching = _searchController.text.isNotEmpty || _selectedCategory != 'Todas';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.explore_off_rounded,
                size: 56,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? 'Nenhum resultado' : 'Sem artigos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Tente outros termos ou categorias'
                  : 'Puxe para atualizar',
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedCategory = 'Todas');
                  _filterArticles();
                },
                child: Text(AppLocalizations.of(context)!.limparFiltros),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(int displayIndex, int articleIndex, ColorScheme colors) {
    final article = _filteredArticles[displayIndex];
    final image = _images[articleIndex];
    final isLoadingImage = _loadingImages.contains(articleIndex);
    final hasImage = image != null && image.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openNewsDetail(article, articleIndex, colors),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage || isLoadingImage)
                  _buildCardImage(image, isLoadingImage, colors)
                else
                  _buildCardImagePlaceholder(colors, article),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardMeta(article, colors),
                      const SizedBox(height: 10),
                      Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                          height: 1.35,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (article.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          article.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                            height: 1.45,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildCardFooter(article, colors),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(String? imageUrl, bool isLoading, ColorScheme colors) {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildCardImagePlaceholder(colors, null),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildImageLoader(colors, loadingProgress);
                  },
                )
              : _buildImageLoader(colors, null),
        ),
        if (isLoading && (imageUrl == null || imageUrl.isEmpty))
          Positioned.fill(child: _buildImageLoader(colors, null)),
      ],
    );
  }

  Widget _buildImageLoader(ColorScheme colors, ImageChunkEvent? progress) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withValues(alpha: 0.3),
            colors.secondaryContainer.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colors.primary,
            value: progress?.expectedTotalBytes != null
                ? progress!.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCardImagePlaceholder(ColorScheme colors, NewsArticle? article) {
    final categoryColor = article != null && article.tags.isNotEmpty 
        ? _getCategoryColor(article.tags.first) 
        : colors.primary;
    
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withValues(alpha: 0.2),
            categoryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(article?.tags.first ?? ''),
          size: 36,
          color: categoryColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = _categories.firstWhere(
      (c) => c['name'].toString().toLowerCase() == category.toLowerCase(),
      orElse: () => {'icon': Icons.article_outlined},
    );
    return cat['icon'] as IconData;
  }

  Widget _buildCardMeta(NewsArticle article, ColorScheme colors) {
    final categoryColor = article.tags.isNotEmpty 
        ? _getCategoryColor(article.tags.first)
        : colors.primary;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.source_rounded,
                size: 12,
                color: categoryColor,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  article.source,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (article.publishedAt != null) ...[
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            article.formattedDate,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 12,
                color: colors.primary,
              ),
              const SizedBox(width: 3),
              Text(
                '${article.readingTime}min',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter(NewsArticle article, ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: article.tags.take(2).map((tag) {
              final tagColor = _getCategoryColor(tag);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tagColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: colors.onSurfaceVariant,
        ),
      ],
    );
  }

  void _openNewsDetail(NewsArticle article, int index, ColorScheme colors) {
    final image = _images[index];
    final categoryColor = article.tags.isNotEmpty 
        ? _getCategoryColor(article.tags.first)
        : colors.primary;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (image != null && image.isNotEmpty)
                        Container(
                          height: 220,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDetailPlaceholder(colors, categoryColor),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildDetailPlaceholder(colors, categoryColor),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.source_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        article.source,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                if (article.publishedAt != null)
                                  Text(
                                    article.fullFormattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              article.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                                height: 1.3,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (article.tags.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: article.tags.map((tag) {
                                  final tagColor = _getCategoryColor(tag);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: tagColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: tagColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            if (article.description.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Text(
                                article.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colors.onSurfaceVariant,
                                  height: 1.6,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 18, color: categoryColor),
                                const SizedBox(width: 6),
                                Text(
                                  '~${article.readingTime} min de leitura',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: categoryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed: () => _openUrl(article.url),
                                style: FilledButton.styleFrom(
                                  backgroundColor: categoryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.open_in_browser_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Ler artigo completo',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: categoryColor,
                                  side: BorderSide(color: categoryColor.withValues(alpha: 0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(AppLocalizations.of(context)!.back,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPlaceholder(ColorScheme colors, Color categoryColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withValues(alpha: 0.3),
            categoryColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.article_outlined,
          size: 56,
          color: categoryColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
