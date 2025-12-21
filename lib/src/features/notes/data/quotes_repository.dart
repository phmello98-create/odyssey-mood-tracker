// lib/src/features/notes/data/quotes_repository.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../domain/quote.dart';
import '../../../shared/data/isar_service.dart';

/// Repositório para gerenciar citações/frases no Isar
class QuotesRepository {
  Isar? _isar;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _isar = await IsarService.getInstance();
      _initialized = true;
      await addSampleQuotesIfEmpty();
    } catch (e) {
      debugPrint('Error initializing QuotesRepository with Isar: $e');
      rethrow;
    }
  }

  // CRUD Operations using Isar

  Future<void> addQuote(Quote quote) async {
    await _ensureInitialized();
    await _isar!.writeTxn(() async {
      await _isar!.quotes.put(quote);
    });
  }

  Future<void> updateQuote(Quote quote) async {
    await _ensureInitialized();
    await _isar!.writeTxn(() async {
      await _isar!.quotes.put(quote);
    });
  }

  Future<void> deleteQuote(int id) async {
    await _ensureInitialized();
    await _isar!.writeTxn(() async {
      await _isar!.quotes.delete(id);
    });
  }

  Future<Quote?> getQuote(int id) async {
    await _ensureInitialized();
    return await _isar!.quotes.get(id);
  }

  Future<List<Quote>> getAllQuotes() async {
    await _ensureInitialized();
    return await _isar!.quotes.where().sortByCreatedAtDesc().findAll();
  }

  Future<List<Quote>> getFavoriteQuotes() async {
    await _ensureInitialized();
    return await _isar!.quotes
        .filter()
        .isFavoriteEqualTo(true)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<void> toggleFavorite(int id) async {
    await _ensureInitialized();
    final quote = await getQuote(id);
    if (quote != null) {
      quote.isFavorite = !quote.isFavorite;
      await updateQuote(quote);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // High-performance search using Isar
  Future<List<Quote>> searchQuotes(String query) async {
    await _ensureInitialized();
    if (query.isEmpty) return getAllQuotes();

    return await _isar!.quotes
        .filter()
        .textContains(query, caseSensitive: false)
        .or()
        .authorContains(query, caseSensitive: false)
        .or()
        .categoryContains(query, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Stream<List<Quote>> watchQuotes() {
    _ensureInitialized();
    return _isar!.quotes.where().sortByCreatedAtDesc().watch(
      fireImmediately: true,
    );
  }

  // Add sample quotes if empty (Min 50 as requested)
  Future<void> addSampleQuotesIfEmpty() async {
    await _ensureInitialized();
    final count = await _isar!.quotes.count();
    if (count == 0) {
      final now = DateTime.now();
      final sampleQuotes = [
        // Spinoza
        Quote()
          ..text = "Não rir, não chorar, nem detestar, mas compreender."
          ..author = "Spinoza"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 1)),
        Quote()
          ..text =
              "A alegria é a passagem do homem de uma perfeição menor para uma maior."
          ..author = "Spinoza"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 2)),
        Quote()
          ..text =
              "A paz não é a ausência de guerra, é uma virtude que nasce da força da alma."
          ..author = "Spinoza"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 3)),
        Quote()
          ..text =
              "Compreender as causas do sofrimento é transformar paixão em ação."
          ..author = "Spinoza"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 4)),
        Quote()
          ..text = "Tudo o que é excelente é tão difícil quanto raro."
          ..author = "Spinoza"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 5)),
        Quote()
          ..text = "A felicidade é a própria virtude, não o seu prêmio."
          ..author = "Spinoza"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 6)),

        // Nietzsche
        Quote()
          ..text =
              "Amor Fati: não querer que nada seja diferente, nem no futuro, nem no passado."
          ..author = "Nietzsche"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 7)),
        Quote()
          ..text =
              "É preciso ter o caos dentro de si para dar à luz uma estrela dançante."
          ..author = "Nietzsche"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 8)),
        Quote()
          ..text = "Torna-te quem tu és."
          ..author = "Nietzsche"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 9)),
        Quote()
          ..text = "O que não me mata, fortalece-me."
          ..author = "Nietzsche"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 10)),
        Quote()
          ..text =
              "Quem tem um para quê pelo qual viver, pode suportar quase qualquer como."
          ..author = "Nietzsche"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 11)),
        Quote()
          ..text = "A vida, sem música, seria um erro."
          ..author = "Nietzsche"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 12)),
        Quote()
          ..text = "Onde vês o ideal, vejo o que é humano, demasiado humano."
          ..author = "Nietzsche"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 13)),

        // Maslow
        Quote()
          ..text = "O que um homem pode ser, ele deve ser."
          ..author = "Maslow"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 14)),
        Quote()
          ..text = "A capacidade de estar sozinho é um sinal de maturidade."
          ..author = "Maslow"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 15)),
        Quote()
          ..text = "A autorrealização exige a coragem de ser impopular."
          ..author = "Maslow"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 16)),
        Quote()
          ..text =
              "Se a única ferramenta que você tem é um martelo, você tende a ver todo problema como um prego."
          ..author = "Maslow"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 17)),

        // Viktor Frankl
        Quote()
          ..text =
              "Quando não somos mais capazes de mudar uma situação, somos desafiados a mudar a nós mesmos."
          ..author = "Viktor Frankl"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 18)),
        Quote()
          ..text =
              "Entre o estímulo e a resposta há um espaço. Nesse espaço está nossa liberdade e o poder de escolher nossa resposta."
          ..author = "Viktor Frankl"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 19)),
        Quote()
          ..text = "A busca de sentido é a motivação primária na vida."
          ..author = "Viktor Frankl"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 20)),

        // Marcus Aurelius / Seneca
        Quote()
          ..text =
              "A felicidade de sua vida depende da qualidade de seus pensamentos."
          ..author = "Marcus Aurelius"
          ..category = "Estoicismo"
          ..createdAt = now.subtract(const Duration(hours: 21)),
        Quote()
          ..text =
              "Você tem poder sobre sua mente, não sobre eventos externos. Perceba isso e você encontrará força."
          ..author = "Marcus Aurelius"
          ..category = "Estoicismo"
          ..createdAt = now.subtract(const Duration(hours: 22)),
        Quote()
          ..text =
              "A melhor vingança é ser diferente daquele que causou o dano."
          ..author = "Marcus Aurelius"
          ..category = "Estoicismo"
          ..createdAt = now.subtract(const Duration(hours: 23)),
        Quote()
          ..text =
              "Não é porque as coisas são difíceis que não ousamos; é porque não ousamos que elas são difíceis."
          ..author = "Seneca"
          ..category = "Estoicismo"
          ..createdAt = now.subtract(const Duration(hours: 24)),
        Quote()
          ..text = "Sofremos mais na imaginação do que na realidade."
          ..author = "Seneca"
          ..category = "Estoicismo"
          ..createdAt = now.subtract(const Duration(hours: 25)),
        Quote()
          ..text = "A pressa é a inimiga da perfeição."
          ..author = "Provébio"
          ..category = "Sabedoria"
          ..createdAt = now.subtract(const Duration(hours: 26)),

        // Carl Jung
        Quote()
          ..text =
              "Aquele que olha para fora, sonha; aquele que olha para dentro, acorda."
          ..author = "Carl Jung"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 27)),
        Quote()
          ..text =
              "Eu não sou o que aconteceu comigo, eu sou o que escolhi me tornar."
          ..author = "Carl Jung"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 28)),
        Quote()
          ..text =
              "Até que você torne o inconsciente consciente, ele irá dirigir sua vida e você o chamará de destino."
          ..author = "Carl Jung"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 29)),
        Quote()
          ..text = "Onde o amor impera, não há desejo de poder."
          ..author = "Carl Jung"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 30)),

        // Sartre / Camus
        Quote()
          ..text = "O homem está condenado a ser livre."
          ..author = "Sartre"
          ..category = "Existencialismo"
          ..createdAt = now.subtract(const Duration(hours: 31)),
        Quote()
          ..text = "A existência precede a essência."
          ..author = "Sartre"
          ..category = "Existencialismo"
          ..createdAt = now.subtract(const Duration(hours: 32)),
        Quote()
          ..text =
              "No meio do inverno, aprendi finalmente que havia em mim um verão invencível."
          ..author = "Camus"
          ..category = "Existencialismo"
          ..createdAt = now.subtract(const Duration(hours: 33)),
        Quote()
          ..text =
              "A liberdade não é nada mais do que a oportunidade de ser melhor."
          ..author = "Camus"
          ..category = "Existencialismo"
          ..createdAt = now.subtract(const Duration(hours: 34)),

        // Psicologia / Serenidade
        Quote()
          ..text =
              "Limites saudáveis são as bordas de onde você termina e o outro começa."
          ..author = "Psicologia"
          ..category = "Bem-estar"
          ..createdAt = now.subtract(const Duration(hours: 35)),
        Quote()
          ..text =
              "O seu cérebro não foi feito para ser feliz, mas para sobreviver."
          ..author = "Neurociência"
          ..category = "Ciência"
          ..createdAt = now.subtract(const Duration(hours: 36)),
        Quote()
          ..text =
              "Pessoas invasivas não respeitam limites porque não os enxergam."
          ..author = "Psicologia"
          ..category = "Bem-estar"
          ..createdAt = now.subtract(const Duration(hours: 37)),
        Quote()
          ..text = "O vácuo transborda energia."
          ..author = "Física Quântica"
          ..category = "Ciência"
          ..createdAt = now.subtract(const Duration(hours: 38)),
        Quote()
          ..text =
              "Ser você mesmo em um mundo que tenta te mudar é a maior conquista."
          ..author = "R.W. Emerson"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 39)),
        Quote()
          ..text =
              "Vulnerabilidade não é fraqueza; é a nossa medida mais precisa de coragem."
          ..author = "Brené Brown"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 40)),
        Quote()
          ..text =
              "O perdão é a libertação do prisioneiro – e descobrir que o prisioneiro era você."
          ..author = "Lewis Smedes"
          ..category = "Sabedoria"
          ..createdAt = now.subtract(const Duration(hours: 41)),
        Quote()
          ..text = "A comparação é a ladra da alegria."
          ..author = "Theodore Roosevelt"
          ..category = "Sabedoria"
          ..createdAt = now.subtract(const Duration(hours: 42)),
        Quote()
          ..text = "O que resiste, persiste."
          ..author = "Carl Jung"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 43)),
        Quote()
          ..text =
              "Sua visão se tornará clara somente quando você puder olhar para o seu coração."
          ..author = "Carl Jung"
          ..category = "Psicologia"
          ..createdAt = now.subtract(const Duration(hours: 44)),
        Quote()
          ..text = "A vida é 10% o que acontece e 90% como você reage."
          ..author = "Charles Swindoll"
          ..category = "Sabedoria"
          ..createdAt = now.subtract(const Duration(hours: 45)),
        Quote()
          ..text = "A sabedoria começa na admiração."
          ..author = "Sócrates"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 46)),
        Quote()
          ..text = "Conhece-te a ti mesmo."
          ..author = "Sócrates"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 47)),
        Quote()
          ..text = "Só sei que nada sei."
          ..author = "Sócrates"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 48)),
        Quote()
          ..text = "A vida não examinada não vale a pena ser vivida."
          ..author = "Sócrates"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 49)),
        Quote()
          ..text = "O começo da sabedoria é a definição dos termos."
          ..author = "Sócrates"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 50)),
        Quote()
          ..text = "O amigo de todos não é amigo de ninguém."
          ..author = "Aristóteles"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 51)),
        Quote()
          ..text = "A excelência é um hábito, não um ato."
          ..author = "Aristóteles"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 52)),
        Quote()
          ..text = "O homem é um animal político."
          ..author = "Aristóteles"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 53)),
        Quote()
          ..text = "A educação é o melhor provimento para a velhice."
          ..author = "Aristóteles"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 54)),
        Quote()
          ..text = "A esperança é o sonho do homem acordado."
          ..author = "Aristóteles"
          ..category = "Filosofia"
          ..createdAt = now.subtract(const Duration(hours: 55)),
      ];

      await _isar!.writeTxn(() async {
        await _isar!.quotes.putAll(sampleQuotes);
      });
    }
  }
}

/// Provider para o repositório de citações
final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  return QuotesRepository();
});
