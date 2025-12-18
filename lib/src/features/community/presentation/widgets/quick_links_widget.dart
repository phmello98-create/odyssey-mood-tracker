import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';

/// Widget de Quick Links com painéis expansíveis
class QuickLinksWidget extends ConsumerStatefulWidget {
  const QuickLinksWidget({super.key});

  @override
  ConsumerState<QuickLinksWidget> createState() => _QuickLinksWidgetState();
}

class _QuickLinksWidgetState extends ConsumerState<QuickLinksWidget> {
  String? _expandedPanel; // 'regras', 'wiki', 'eventos', 'notificacoes', null

  void _togglePanel(String panelId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedPanel == panelId) {
        _expandedPanel = null;
      } else {
        _expandedPanel = panelId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final notifState = ref.watch(notificationsProvider);

    return Column(
      children: [
        // Quick Links Row
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildQuickLink(
                context,
                id: 'regras',
                label: 'Regras',
                icon: Icons.gavel_rounded,
                color: const Color(0xFFE57373),
                isExpanded: _expandedPanel == 'regras',
              ),
              _buildQuickLink(
                context,
                id: 'wiki',
                label: 'Wiki',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF64B5F6),
                isExpanded: _expandedPanel == 'wiki',
              ),
              _buildQuickLink(
                context,
                id: 'eventos',
                label: 'Eventos',
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFFFFD54F),
                isExpanded: _expandedPanel == 'eventos',
              ),
              _buildQuickLink(
                context,
                id: 'notificacoes',
                label: 'Avisos',
                icon: Icons.notifications_rounded,
                color: const Color(0xFF9C27B0),
                isExpanded: _expandedPanel == 'notificacoes',
                badge: notifState.unreadCount > 0
                    ? notifState.unreadCount
                    : null,
              ),
            ],
          ),
        ),

        // Expandable Panel
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _expandedPanel != null
              ? _buildExpandedContent(colors)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildQuickLink(
    BuildContext context, {
    required String id,
    required String label,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    int? badge,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _togglePanel(id),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(left: 8, right: 12),
          decoration: BoxDecoration(
            color: isExpanded
                ? color.withOpacity(0.25)
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExpanded ? color : color.withOpacity(0.2),
              width: isExpanded ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
                  color: colors.onSurface.withOpacity(0.9),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ColorScheme colors) {
    switch (_expandedPanel) {
      case 'regras':
        return _buildRulesPanel(colors);
      case 'wiki':
        return _buildWikiPanel(colors);
      case 'eventos':
        return _buildEventsPanel(colors);
      case 'notificacoes':
        return _buildNotificationsPanel(colors);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRulesPanel(ColorScheme colors) {
    final rules = [
      {
        'icon': '🤝',
        'title': 'Seja gentil',
        'desc': 'Trate todos com respeito',
      },
      {
        'icon': '🎯',
        'title': 'Foco em crescimento',
        'desc': 'Compartilhe experiências positivas',
      },
      {
        'icon': '🚫',
        'title': 'Sem spam',
        'desc': 'Evite autopromoção excessiva',
      },
      {
        'icon': '💬',
        'title': 'Diálogo construtivo',
        'desc': 'Críticas devem ser construtivas',
      },
      {
        'icon': '🔒',
        'title': 'Respeite a privacidade',
        'desc': 'Não compartilhe dados de outros',
      },
    ];

    return _buildPanel(
      colors: colors,
      color: const Color(0xFFE57373),
      title: 'Regras da Comunidade',
      child: Column(
        children: rules
            .map(
              (rule) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(rule['icon']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule['title']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            rule['desc']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildWikiPanel(ColorScheme colors) {
    final articles = [
      {'icon': '📖', 'title': 'Guia do Iniciante', 'views': '2.3k'},
      {'icon': '🍅', 'title': 'Técnica Pomodoro', 'views': '5.1k'},
      {'icon': '🧘', 'title': 'Meditação para Foco', 'views': '3.8k'},
      {'icon': '📝', 'title': 'Hábitos Atômicos', 'views': '4.2k'},
    ];

    return _buildPanel(
      colors: colors,
      color: const Color(0xFF64B5F6),
      title: 'Wiki Odyssey',
      child: Column(
        children: articles
            .map(
              (article) => InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Abrindo: ${article['title']}')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        article['icon']!,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          article['title']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${article['views']} views',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEventsPanel(ColorScheme colors) {
    final events = [
      {'date': '20 Dez', 'title': 'Desafio de Meditação', 'status': 'Em breve'},
      {'date': '25 Dez', 'title': 'Maratona de Foco', 'status': 'Inscreva-se'},
      {'date': '01 Jan', 'title': 'Reset de Ano Novo', 'status': 'Em breve'},
    ];

    return _buildPanel(
      colors: colors,
      color: const Color(0xFFFFD54F),
      title: 'Próximos Eventos',
      child: Column(
        children: events
            .map(
              (event) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event['date']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event['title']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event['status']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildNotificationsPanel(ColorScheme colors) {
    final notifState = ref.watch(notificationsProvider);
    final notifications = notifState.notifications.take(5).toList();

    return _buildPanel(
      colors: colors,
      color: const Color(0xFF9C27B0),
      title: 'Notificações Recentes',
      trailing: notifState.unreadCount > 0
          ? TextButton(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
                HapticFeedback.lightImpact();
              },
              child: const Text('Marcar lidas', style: TextStyle(fontSize: 11)),
            )
          : null,
      child: notifications.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nenhuma notificação',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            )
          : Column(
              children: notifications
                  .map(
                    (notif) => InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(notificationsProvider.notifier)
                            .markAsRead(notif.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: notif.isRead
                              ? null
                              : colors.primaryContainer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(
                                  notif.colorValue,
                                ).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getNotifIcon(notif.type.name),
                                size: 16,
                                color: Color(notif.colorValue),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: notif.isRead
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                      color: colors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    notif.message,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (!notif.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'newFollower':
        return Icons.person_add_rounded;
      case 'postUpvote':
        return Icons.arrow_upward_rounded;
      case 'postComment':
        return Icons.chat_bubble_rounded;
      case 'commentReply':
        return Icons.reply_rounded;
      case 'mention':
        return Icons.alternate_email_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'milestone':
        return Icons.celebration_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      case 'trending':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Widget _buildPanel({
    required ColorScheme colors,
    required Color color,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
                IconButton(
                  onPressed: () => _togglePanel(_expandedPanel!),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          // Content
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}
