/// Tipos de denúncia
enum ReportType {
  spam,
  harassment,
  inappropriateContent,
  misinformation,
  impersonation,
  other,
}

/// Status da denúncia
enum ReportStatus { pending, reviewed, resolved, dismissed }

/// Tipo do conteúdo denunciado
enum ReportedContentType { post, comment, user }

/// Model de denúncia
class Report {
  final String id;
  final String reporterId;
  final String reportedContentId;
  final ReportedContentType contentType;
  final String? reportedUserId;
  final ReportType type;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? resolution;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedContentId,
    required this.contentType,
    this.reportedUserId,
    required this.type,
    this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.resolution,
  });

  Report copyWith({
    String? id,
    String? reporterId,
    String? reportedContentId,
    ReportedContentType? contentType,
    String? reportedUserId,
    ReportType? type,
    String? description,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? resolution,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedContentId: reportedContentId ?? this.reportedContentId,
      contentType: contentType ?? this.contentType,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      resolution: resolution ?? this.resolution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedContentId': reportedContentId,
      'contentType': contentType.name,
      'reportedUserId': reportedUserId,
      'type': type.name,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'resolution': resolution,
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reportedContentId: json['reportedContentId'] as String,
      contentType: ReportedContentType.values.firstWhere(
        (e) => e.name == json['contentType'],
        orElse: () => ReportedContentType.post,
      ),
      reportedUserId: json['reportedUserId'] as String?,
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.other,
      ),
      description: json['description'] as String?,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewedBy: json['reviewedBy'] as String?,
      resolution: json['resolution'] as String?,
    );
  }

  /// Retorna descrição do tipo de denúncia em português
  String get typeLabel {
    switch (type) {
      case ReportType.spam:
        return 'Spam';
      case ReportType.harassment:
        return 'Assédio ou bullying';
      case ReportType.inappropriateContent:
        return 'Conteúdo impróprio';
      case ReportType.misinformation:
        return 'Informação falsa';
      case ReportType.impersonation:
        return 'Falsidade ideológica';
      case ReportType.other:
        return 'Outro';
    }
  }

  /// Retorna descrição do status em português
  String get statusLabel {
    switch (status) {
      case ReportStatus.pending:
        return 'Pendente';
      case ReportStatus.reviewed:
        return 'Em análise';
      case ReportStatus.resolved:
        return 'Resolvido';
      case ReportStatus.dismissed:
        return 'Rejeitado';
    }
  }
}

/// DTO para criação de denúncia
class CreateReportDto {
  final String reportedContentId;
  final ReportedContentType contentType;
  final String? reportedUserId;
  final ReportType type;
  final String? description;

  const CreateReportDto({
    required this.reportedContentId,
    required this.contentType,
    this.reportedUserId,
    required this.type,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportedContentId': reportedContentId,
      'contentType': contentType.name,
      'reportedUserId': reportedUserId,
      'type': type.name,
      'description': description,
    };
  }
}
