import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class EmptyStatePopup extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onExplore;
  final String preferenceKey;

  const EmptyStatePopup({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onExplore,
    required this.preferenceKey,
  }) : super(key: key);

  static Future<bool> shouldShow(String preferenceKey) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(preferenceKey) ?? false);
  }

  static Future<void> markAsShown(String preferenceKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(preferenceKey, true);
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onExplore,
    required String preferenceKey,
  }) async {
    final shouldShowPopup = await shouldShow(preferenceKey);
    
    if (!shouldShowPopup || !context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EmptyStatePopup(
        title: title,
        description: description,
        icon: icon,
        onExplore: onExplore,
        preferenceKey: preferenceKey,
      ),
    );
    
    await markAsShown(preferenceKey);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E1E1E),
                    const Color(0xFF2A2A2A),
                  ]
                : [
                    const Color(0xFFF9FAFB),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone animado
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF9B51E0),
                          Color(0xFF6366F1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9B51E0).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Título
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Descrição
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 28),
            
            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark 
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.maisTarde),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onExplore();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF9B51E0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Explorar Sugestões',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
