import 'package:flutter/material.dart';

/// Mapa constante de ícones para sugestões
/// Isso permite tree-shaking de ícones no build de release
const Map<String, IconData> suggestionIcons = {
  // Autoconhecimento
  'psychology': Icons.psychology,
  'edit_note': Icons.edit_note,
  'help_outline': Icons.help_outline,
  'self_improvement': Icons.self_improvement,
  'search': Icons.search,
  'menu_book': Icons.menu_book,
  'dark_mode': Icons.dark_mode,
  'psychology_alt': Icons.psychology_alt,
  'shield': Icons.shield,
  'child_care': Icons.child_care,
  'loop': Icons.loop,
  'favorite_border': Icons.favorite_border,
  'visibility_off': Icons.visibility_off,
  'account_tree': Icons.account_tree,
  'medical_services': Icons.medical_services,
  'hourglass_empty': Icons.hourglass_empty,
  
  // Presença & Corpo
  'directions_walk': Icons.directions_walk,
  'healing': Icons.healing,
  'air': Icons.air,
  'phone_disabled': Icons.phone_disabled,
  
  // Relações
  'hearing': Icons.hearing,
  'volunteer_activism': Icons.volunteer_activism,
  'forum': Icons.forum,
  'groups': Icons.groups,
  'people': Icons.people,
  
  // Criação
  'create': Icons.create,
  'palette': Icons.palette,
  'book': Icons.book,
  'draw': Icons.draw,
  'web': Icons.web,
  'music_note': Icons.music_note,
  'brush': Icons.brush,
  
  // Reflexão
  'replay': Icons.replay,
  'mail': Icons.mail,
  'history_edu': Icons.history_edu,
  'masks': Icons.masks,
  'auto_stories': Icons.auto_stories,
  'school': Icons.school,
  'library_books': Icons.library_books,
  'description': Icons.description,
  'public': Icons.public,
  
  // Autorrealização
  'star_border': Icons.star_border,
  'person': Icons.person,
  'park': Icons.park,
  'check_circle_outline': Icons.check_circle_outline,
  'diamond': Icons.diamond,
  'stairs': Icons.stairs,
  'trending_up': Icons.trending_up,
  
  // Consciência
  'science': Icons.science,
  'water': Icons.water,
  'visibility': Icons.visibility,
  'question_answer': Icons.question_answer,
  'balance': Icons.balance,
  
  // Vacuidade
  'blur_on': Icons.blur_on,
  'crop_square': Icons.crop_square,
  'home': Icons.home,
  'hub': Icons.hub,
  
  // Aprendizado
  'timeline': Icons.timeline,
  'ondemand_video': Icons.ondemand_video,
  'book_outlined': Icons.book_outlined,
  
  // Fallback
  'lightbulb_outline': Icons.lightbulb_outline,
};

/// Retorna o IconData para uma chave, com fallback
IconData getSuggestionIcon(String key) {
  return suggestionIcons[key] ?? Icons.lightbulb_outline;
}
