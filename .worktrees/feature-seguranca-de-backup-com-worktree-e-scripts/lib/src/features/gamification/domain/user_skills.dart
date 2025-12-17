// User Skills model - RPG style personal development
// Based on Maslow's Humanistic Psychology
// 
// IMPORTANTE: A "Pirâmide de Maslow" NÃO foi criada por Maslow!
// Ele descreveu uma HIERARQUIA DINÂMICA, não uma pirâmide rígida.
// As necessidades COEXISTEM e se interpenetram simultaneamente.
// Uma pessoa pode estar 85% satisfeita em fisiologia, 50% em amor
// e 10% em autoatualização - TUDO AO MESMO TEMPO.

import 'package:flutter/material.dart';

/// Dimensões da vida humana (baseado em Maslow, mas não como pirâmide)
/// Todas as dimensões são importantes e se desenvolvem SIMULTANEAMENTE
enum LifeDimension {
  physical,      // Corpo e vitalidade
  safety,        // Estabilidade e organização
  connection,    // Relacionamentos e pertencimento
  esteem,        // Autoconfiança e reconhecimento
  growth,        // Autoatualização e transcendência
}

/// Categorias de Skills pessoais
class SkillCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final LifeDimension dimension;
  final List<Skill> skills;
  final String maslowInsight; // Insight baseado nos livros

  const SkillCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.dimension,
    required this.skills,
    this.maslowInsight = '',
  });
}

/// Skill individual
class Skill {
  final String id;
  final String name;
  final String description;
  final int maxLevel;
  int currentLevel;
  int currentXP;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    this.maxLevel = 10,
    this.currentLevel = 1,
    this.currentXP = 0,
  });

  int get xpForNextLevel => currentLevel * 100;
  double get progress => currentXP / xpForNextLevel;
  bool get isMaxLevel => currentLevel >= maxLevel;

  void addXP(int xp) {
    if (isMaxLevel) return;
    currentXP += xp;
    while (currentXP >= xpForNextLevel && !isMaxLevel) {
      currentXP -= xpForNextLevel;
      currentLevel++;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'maxLevel': maxLevel,
    'currentLevel': currentLevel,
    'currentXP': currentXP,
  };

  factory Skill.fromMap(Map<String, dynamic> map) => Skill(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    maxLevel: map['maxLevel'] ?? 10,
    currentLevel: map['currentLevel'] ?? 1,
    currentXP: map['currentXP'] ?? 0,
  );
}

/// Lista de categorias de skills padrão baseada em Maslow
/// NOTA: As dimensões NÃO são hierárquicas! Desenvolvem-se simultaneamente.
List<SkillCategory> getDefaultSkillCategories() {
  return [
    // Dimensão 1: Físico - Cuidar do corpo como templo
    SkillCategory(
      id: 'physical',
      name: 'Físico',
      description: 'Saúde, sono, nutrição e energia',
      icon: Icons.fitness_center,
      color: const Color(0xFF4CAF50), // Verde
      dimension: LifeDimension.physical,
      maslowInsight: 'O corpo é o instrumento através do qual experimentamos a vida. Cuidar dele é pré-requisito para todo crescimento.',
      skills: [
        Skill(id: 'sleep', name: 'Sono', description: 'Qualidade e regularidade do sono'),
        Skill(id: 'nutrition', name: 'Nutrição', description: 'Alimentação saudável e equilibrada'),
        Skill(id: 'exercise', name: 'Exercício', description: 'Atividade física regular'),
        Skill(id: 'hydration', name: 'Hidratação', description: 'Consumo adequado de água'),
      ],
    ),

    // Dimensão 2: Organização - Segurança e estabilidade
    SkillCategory(
      id: 'organization',
      name: 'Organização',
      description: 'Planejamento, finanças e rotina',
      icon: Icons.calendar_month,
      color: const Color(0xFF2196F3), // Azul
      dimension: LifeDimension.safety,
      maslowInsight: 'A segurança financeira e emocional é a base que permite à pessoa buscar necessidades mais elevadas.',
      skills: [
        Skill(id: 'planning', name: 'Planejamento', description: 'Planejar tarefas e metas'),
        Skill(id: 'finance', name: 'Finanças', description: 'Gestão financeira pessoal'),
        Skill(id: 'routine', name: 'Rotina', description: 'Manter rotinas saudáveis'),
        Skill(id: 'focus', name: 'Foco', description: 'Concentração e produtividade'),
      ],
    ),

    // Dimensão 3: Social - Conexões e pertencimento
    SkillCategory(
      id: 'social',
      name: 'Social',
      description: 'Relacionamentos e conexões',
      icon: Icons.people,
      color: const Color(0xFFE91E63), // Rosa
      dimension: LifeDimension.connection,
      maslowInsight: 'A pessoa sadia, saciada em amor, precisa menos de receber amor, mas é mais suscetível de DAR amor.',
      skills: [
        Skill(id: 'communication', name: 'Comunicação', description: 'Expressar-se com clareza'),
        Skill(id: 'empathy', name: 'Empatia', description: 'Compreender os outros'),
        Skill(id: 'networking', name: 'Networking', description: 'Construir conexões'),
        Skill(id: 'collaboration', name: 'Colaboração', description: 'Trabalhar em equipe'),
      ],
    ),

    // Dimensão 4: Mental - Autoconfiança e estima
    SkillCategory(
      id: 'mental',
      name: 'Mental',
      description: 'Inteligência emocional e autoestima',
      icon: Icons.psychology,
      color: const Color(0xFF9C27B0), // Roxo
      dimension: LifeDimension.esteem,
      maslowInsight: 'A satisfação da necessidade de autoestima leva a sentimentos de autoconfiança, valor, força e adequação.',
      skills: [
        Skill(id: 'emotional_iq', name: 'Inteligência Emocional', description: 'Reconhecer e gerenciar emoções'),
        Skill(id: 'resilience', name: 'Resiliência', description: 'Superar adversidades'),
        Skill(id: 'confidence', name: 'Autoconfiança', description: 'Acreditar em si mesmo'),
        Skill(id: 'discipline', name: 'Disciplina', description: 'Manter compromissos consigo'),
      ],
    ),

    // Dimensão 5: Crescimento - Autoatualização e propósito
    SkillCategory(
      id: 'growth',
      name: 'Crescimento',
      description: 'Aprendizado e propósito de vida',
      icon: Icons.auto_awesome,
      color: const Color(0xFFFF9800), // Laranja
      dimension: LifeDimension.growth,
      maslowInsight: 'A autoatualização é o processo de realização de potenciais: tendência incessante para a unidade e integração.',
      skills: [
        Skill(id: 'learning', name: 'Aprendizado', description: 'Buscar conhecimento continuamente'),
        Skill(id: 'creativity', name: 'Criatividade', description: 'Pensar fora da caixa'),
        Skill(id: 'purpose', name: 'Propósito', description: 'Agir com significado'),
        Skill(id: 'mindfulness', name: 'Presença', description: 'Viver o momento presente'),
      ],
    ),
  ];
}

/// Frases e insights de Abraham Maslow
/// Fonte: "Motivação e Personalidade" e "Introdução à Psicologia do Ser"
class MaslowQuotes {
  static const Map<LifeDimension, List<String>> quotes = {
    LifeDimension.physical: [
      "O corpo é o instrumento através do qual experimentamos toda a vida.",
      "Sem saúde física, as necessidades mais elevadas perdem força.",
      "Descanso não é preguiça, é preparação para a excelência.",
      "A energia do corpo é o combustível dos sonhos.",
    ],
    LifeDimension.safety: [
      "A segurança financeira e emocional é a base que permite buscar necessidades mais elevadas.",
      "Ordem não é prisão, é liberdade organizada.",
      "Rotinas são os trilhos por onde grandes vidas correm.",
      "A pessoa saudável não é perfeita. Ela é boa o suficiente.",
    ],
    LifeDimension.connection: [
      "A pessoa sadia, saciada em amor, precisa menos de receber amor, mas é mais suscetível de DAR amor.",
      "O verdadeiro conhecimento de outro ser humano só é possível quando nada se precisa dele.",
      "Somos tão fortes quanto nossas conexões.",
      "Pessoas autorrealizadas são extremamente individuais E extremamente compassivas ao mesmo tempo.",
    ],
    LifeDimension.esteem: [
      "A forma mais estável de autoestima é baseada no respeito merecido, não na fama externa.",
      "A satisfação da autoestima leva a sentimentos de autoconfiança, valor e adequação.",
      "Acredite em si mesmo quando ninguém mais acreditar.",
      "Respeite-se primeiro, o mundo seguirá seu exemplo.",
    ],
    LifeDimension.growth: [
      "O que um homem pode ser, ele deve ser. Isso chamamos de autoatualização.",
      "A autoatualização é um processo contínuo de Vir a Ser, não apenas de Ser.",
      "Um músico deve fazer música, um artista deve pintar, se quiser estar em paz consigo.",
      "O crescimento é, em si mesmo, um processo compensador e excitante.",
      "Em qualquer momento, temos duas opções: avançar para o crescimento ou recuar para a segurança.",
      "A satisfação gera uma CRESCENTE, não decrescente, motivação.",
    ],
  };

  static String getRandomQuote(LifeDimension dimension) {
    final dimensionQuotes = quotes[dimension] ?? quotes[LifeDimension.growth]!;
    return dimensionQuotes[DateTime.now().millisecondsSinceEpoch % dimensionQuotes.length];
  }

  static String getQuoteByCategory(String categoryId) {
    switch (categoryId) {
      case 'physical':
        return getRandomQuote(LifeDimension.physical);
      case 'organization':
        return getRandomQuote(LifeDimension.safety);
      case 'social':
        return getRandomQuote(LifeDimension.connection);
      case 'mental':
        return getRandomQuote(LifeDimension.esteem);
      case 'growth':
        return getRandomQuote(LifeDimension.growth);
      default:
        return getRandomQuote(LifeDimension.growth);
    }
  }
}

/// Perfil do Praticante
class PractitionerProfile {
  String name;
  String title; // Ex: "Explorador", "Mestre"
  String avatarPath;
  int totalXP;
  int level;
  DateTime joinedDate;
  List<String> currentGoals;
  Map<String, int> skillLevels; // id -> level

  PractitionerProfile({
    this.name = 'Praticante',
    this.title = 'Iniciante',
    this.avatarPath = '',
    this.totalXP = 0,
    this.level = 1,
    DateTime? joinedDate,
    this.currentGoals = const [],
    this.skillLevels = const {},
  }) : joinedDate = joinedDate ?? DateTime.now();

  String get titleWithLevel => '$title Nv.$level';

  Map<String, dynamic> toMap() => {
    'name': name,
    'title': title,
    'avatarPath': avatarPath,
    'totalXP': totalXP,
    'level': level,
    'joinedDate': joinedDate.toIso8601String(),
    'currentGoals': currentGoals,
    'skillLevels': skillLevels,
  };

  factory PractitionerProfile.fromMap(Map<String, dynamic> map) => PractitionerProfile(
    name: map['name'] ?? 'Praticante',
    title: map['title'] ?? 'Iniciante',
    avatarPath: map['avatarPath'] ?? '',
    totalXP: map['totalXP'] ?? 0,
    level: map['level'] ?? 1,
    joinedDate: map['joinedDate'] != null 
        ? DateTime.parse(map['joinedDate']) 
        : DateTime.now(),
    currentGoals: List<String>.from(map['currentGoals'] ?? []),
    skillLevels: Map<String, int>.from(map['skillLevels'] ?? {}),
  );
}

/// Títulos baseados no nível
String getTitleForLevel(int level) {
  if (level <= 2) return 'Iniciante';
  if (level <= 5) return 'Aprendiz';
  if (level <= 10) return 'Praticante';
  if (level <= 15) return 'Explorador';
  if (level <= 20) return 'Mestre';
  if (level <= 30) return 'Sábio';
  if (level <= 50) return 'Iluminado';
  return 'Transcendente';
}
