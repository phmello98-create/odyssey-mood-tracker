import 'package:hive/hive.dart';

part 'suggestion_enums.g.dart';

@HiveType(typeId: 18)
enum SuggestionType {
  @HiveField(0)
  habit,
  @HiveField(1)
  task,
}

@HiveType(typeId: 19)
enum SuggestionCategory {
  @HiveField(0)
  selfKnowledge, // Autoconhecimento (Psicanálise/Jung)
  
  @HiveField(1)
  presence, // Presença & Corpo
  
  @HiveField(2)
  relations, // Relações & Alteridade
  
  @HiveField(3)
  creation, // Criação & Sublimação
  
  @HiveField(4)
  reflection, // Reflexão & Prática
  
  @HiveField(5)
  selfActualization, // Autorrealização (Maslow)
  
  @HiveField(6)
  consciousness, // Consciência Plena (William James)
  
  @HiveField(7)
  emptiness, // Vacuidade & Nada Absoluto (Nishitani Keiji)
}

@HiveType(typeId: 20)
enum SuggestionDifficulty {
  @HiveField(0)
  easy, // 1
  
  @HiveField(1)
  medium, // 2-3
  
  @HiveField(2)
  hard, // 4-5
}
