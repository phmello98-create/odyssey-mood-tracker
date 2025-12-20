import 'post.dart';

/// DTO para criação de posts
class CreatePostDto {
  final String content;
  final PostType type;
  final Map<String, dynamic>? metadata;
  final List<String> categories;
  final List<String> localImagePaths; // Caminhos para imagens locais

  const CreatePostDto({
    required this.content,
    this.type = PostType.text,
    this.metadata,
    this.categories = const [],
    this.localImagePaths = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'type': type.name,
      'metadata': metadata,
      'categories': categories,
      'localImagePaths': localImagePaths,
    };
  }
}

/// DTO para atualização de posts
class UpdatePostDto {
  final String? content;
  final List<String>? categories;

  const UpdatePostDto({this.content, this.categories});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (content != null) json['content'] = content;
    if (categories != null) json['categories'] = categories;
    return json;
  }
}
