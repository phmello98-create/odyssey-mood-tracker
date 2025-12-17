import 'package:flutter/material.dart';

/// Avatar do usuário com indicador de nível
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final int level;
  final double size;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.level,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colors.primary.withOpacity(0.3), colors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(colors),
                  ),
                )
              : _buildDefaultAvatar(colors),
        ),

        // Badge de nível
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.surface, width: 1.5),
            ),
            child: Text(
              '$level',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(ColorScheme colors) {
    return Center(
      child: Icon(Icons.person_rounded, size: size * 0.6, color: Colors.white),
    );
  }
}
