import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/report.dart';

/// Repository para gerenciar denúncias
class ReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReportRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  /// Referência para reports
  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection('reports');

  /// Cria uma nova denúncia
  Future<Report> createReport(CreateReportDto dto) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Verifica se já denunciou este conteúdo
      final existingReport = await _reportsRef
          .where('reporterId', isEqualTo: user.uid)
          .where('reportedContentId', isEqualTo: dto.reportedContentId)
          .get();

      if (existingReport.docs.isNotEmpty) {
        throw Exception('Você já denunciou este conteúdo');
      }

      final now = DateTime.now();
      final reportData = {
        'reporterId': user.uid,
        'reportedContentId': dto.reportedContentId,
        'contentType': dto.contentType.name,
        'reportedUserId': dto.reportedUserId,
        'type': dto.type.name,
        'description': dto.description,
        'status': ReportStatus.pending.name,
        'createdAt': Timestamp.fromDate(now),
      };

      final docRef = await _reportsRef.add(reportData);

      return Report(
        id: docRef.id,
        reporterId: user.uid,
        reportedContentId: dto.reportedContentId,
        contentType: dto.contentType,
        reportedUserId: dto.reportedUserId,
        type: dto.type,
        description: dto.description,
        status: ReportStatus.pending,
        createdAt: now,
      );
    } catch (e) {
      if (e.toString().contains('já denunciou')) {
        rethrow;
      }
      throw Exception('Erro ao criar denúncia: $e');
    }
  }

  /// Busca denúncias do usuário atual
  Future<List<Report>> getMyReports() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final snapshot = await _reportsRef
          .where('reporterId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Report(
          id: doc.id,
          reporterId: data['reporterId'] as String,
          reportedContentId: data['reportedContentId'] as String,
          contentType: ReportedContentType.values.firstWhere(
            (e) => e.name == data['contentType'],
            orElse: () => ReportedContentType.post,
          ),
          reportedUserId: data['reportedUserId'] as String?,
          type: ReportType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => ReportType.other,
          ),
          description: data['description'] as String?,
          status: ReportStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => ReportStatus.pending,
          ),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          reviewedAt: data['reviewedAt'] != null
              ? (data['reviewedAt'] as Timestamp).toDate()
              : null,
          reviewedBy: data['reviewedBy'] as String?,
          resolution: data['resolution'] as String?,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar denúncias: $e');
    }
  }

  /// Cancela uma denúncia pendente
  Future<void> cancelReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      final doc = await _reportsRef.doc(reportId).get();
      if (!doc.exists) {
        throw Exception('Denúncia não encontrada');
      }

      final data = doc.data()!;
      if (data['reporterId'] != user.uid) {
        throw Exception('Sem permissão para cancelar esta denúncia');
      }

      if (data['status'] != ReportStatus.pending.name) {
        throw Exception('Só é possível cancelar denúncias pendentes');
      }

      await _reportsRef.doc(reportId).delete();
    } catch (e) {
      throw Exception('Erro ao cancelar denúncia: $e');
    }
  }
}
