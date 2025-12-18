import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/report.dart';
import '../providers/community_providers.dart';

/// Modal sheet para reportar conteúdo
class ReportSheet extends ConsumerStatefulWidget {
  final String contentId;
  final ReportedContentType contentType;
  final String? reportedUserId;

  const ReportSheet({
    super.key,
    required this.contentId,
    required this.contentType,
    this.reportedUserId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String contentId,
    required ReportedContentType contentType,
    String? reportedUserId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(
        contentId: contentId,
        contentType: contentType,
        reportedUserId: reportedUserId,
      ),
    );
  }

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  ReportType? _selectedType;
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == null || _isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final repo = ref.read(reportRepositoryProvider);
      await repo.createReport(
        CreateReportDto(
          reportedContentId: widget.contentId,
          contentType: widget.contentType,
          reportedUserId: widget.reportedUserId,
          type: _selectedType!,
          description: _descController.text.isNotEmpty
              ? _descController.text
              : null,
        ),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Denúncia enviada!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.flag_rounded, color: colors.error, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Denunciar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...ReportType.values.map(
            (t) => RadioListTile<ReportType>(
              value: t,
              groupValue: _selectedType,
              onChanged: (v) => setState(() => _selectedType = v),
              activeColor: colors.error,
              title: Text(_label(t)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _descController,
              maxLines: 2,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Descrição (opcional)',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedType != null && !_isLoading
                    ? _submit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enviar Denúncia',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _label(ReportType t) {
    switch (t) {
      case ReportType.spam:
        return 'Spam';
      case ReportType.harassment:
        return 'Assédio';
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
}
