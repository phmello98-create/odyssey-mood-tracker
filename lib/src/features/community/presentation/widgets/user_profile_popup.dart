import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Popup card mostrando perfil resumido de um usuário
/// Aparece ao clicar no avatar de um post
class UserProfilePopup extends StatelessWidget {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int userLevel;
  final int? karma;
  final String? flair;
  final VoidCallback? onFollow;
  final VoidCallback? onViewProfile;

  const UserProfilePopup({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.userLevel,
    this.karma,
    this.flair,
    this.onFollow,
    this.onViewProfile,
  });

  static void show(
    BuildContext context, {
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required int userLevel,
    int? karma,
    String? flair,
    VoidCallback? onFollow,
    VoidCallback? onViewProfile,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(32),
        child: UserProfilePopup(
          userId: userId,
          userName: userName,
          userPhotoUrl: userPhotoUrl,
          userLevel: userLevel,
          karma: karma,
          flair: flair,
          onFollow: onFollow,
          onViewProfile: onViewProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withOpacity(0.8),
                  colors.tertiary.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),

          // Avatar (overlapping)
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: userPhotoUrl != null
                        ? NetworkImage(userPhotoUrl!)
                        : null,
                    backgroundColor: colors.primaryContainer,
                    child: userPhotoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: colors.onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),

                // Name
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),

                // Flair
                if (flair != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      flair!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Stats
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(context, 'Nível', '$userLevel', colors),
                  Container(
                    width: 1,
                    height: 30,
                    color: colors.outline.withOpacity(0.2),
                  ),
                  _buildStat(
                    context,
                    'Karma',
                    karma != null ? _formatNumber(karma!) : '-',
                    colors,
                  ),
                ],
              ),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onFollow?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Seguir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onViewProfile?.call();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ver Perfil'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    ColorScheme colors,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
