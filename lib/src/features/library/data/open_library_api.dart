import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OpenLibraryApi {
  static const String _baseUrl = 'https://openlibrary.org';
  static const String _coversUrl = 'https://covers.openlibrary.org/b/id';

  /// Search books by query (title, author, etc)
  Future<List<OpenLibraryBook>> searchBooks(String query) async {
    if (query.isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('$_baseUrl/search.json?q=$encodedQuery&limit=20');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final docs = data['docs'] as List;
        
        return docs.map((doc) => OpenLibraryBook.fromJson(doc)).toList();
      } else {
        debugPrint('OpenLibrary API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('OpenLibrary API Exception: $e');
      return [];
    }
  }

  /// Get book details by ISBN
  Future<OpenLibraryBook?> getBookByIsbn(String isbn) async {
    try {
      final url = Uri.parse('$_baseUrl/isbn/$isbn.json');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OpenLibraryBook.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('OpenLibrary API Exception: $e');
      return null;
    }
  }

  /// Get cover URL
  static String getCoverUrl(int coverId, {String size = 'L'}) {
    return '$_coversUrl/$coverId-$size.jpg';
  }
}

class OpenLibraryBook {
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? coverUrl;
  final int? coverId;
  final int? numberOfPages;
  final String? firstPublishYear;
  final List<String> isbn;
  final String? key;

  OpenLibraryBook({
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.coverUrl,
    this.coverId,
    this.numberOfPages,
    this.firstPublishYear,
    this.isbn = const [],
    this.key,
  });

  factory OpenLibraryBook.fromJson(Map<String, dynamic> json) {
    // Handle authors which can be a list of strings or objects
    List<String> authorsList = [];
    if (json['author_name'] != null) {
      authorsList = List<String>.from(json['author_name']);
    } else if (json['authors'] != null) {
      // Sometimes authors is a list of objects with 'key'
      // We would need to fetch author details, but for search results usually author_name is present
    }

    // Handle cover
    int? coverId = json['cover_i'];
    String? coverUrl;
    if (coverId != null) {
      coverUrl = OpenLibraryApi.getCoverUrl(coverId, size: 'M');
    }

    return OpenLibraryBook(
      title: json['title'] ?? 'Sem título',
      subtitle: json['subtitle'],
      authors: authorsList,
      coverId: coverId,
      coverUrl: coverUrl,
      numberOfPages: json['number_of_pages_median'] ?? json['number_of_pages'],
      firstPublishYear: json['first_publish_year']?.toString(),
      isbn: json['isbn'] != null ? List<String>.from(json['isbn']) : [],
      key: json['key'],
    );
  }
}
