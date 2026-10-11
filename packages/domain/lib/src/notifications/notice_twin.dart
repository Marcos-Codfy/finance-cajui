import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/household/person_name.dart';
import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/ledger/entry_origin.dart';
import 'package:domain/src/ledger/possible_duplicate.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/notifications/bank_reading.dart';
import 'package:domain/src/notifications/movement_kind.dart';

/// O mesmo Pix contado duas vezes: uma pela notificação do banco, outra
/// pelo comprovante compartilhado (RN-1075 a RN-1077).
///
/// A RN-221 compara o nome do lugar escrito do mesmo jeito, e é isso que
/// deixava passar: a notificação lança "Marcos V M Arruda" ou só "Pix
/// enviado", e o comprovante do mesmo Pix diz "MARCOS VINICIUS MUNIZ
/// ARRUDA". Aqui o nome só precisa ser **compatível**, e a data pode estar
/// a um dia — o banco às vezes avisa com a data do processamento.
abstract final class NoticeTwin {
  /// Até quantos dias de distância o mesmo Pix ainda é o mesmo.
  static const reach = 1;

  /// O lançamento que a notificação do banco já fez e que parece ser o
  /// comprovante de [amount], de [occurredOn], para [name] (RN-1076).
  ///
  /// Só conta o que nasceu de notificação: o repetido entre dois
  /// comprovantes continua com a RN-221. Sem nome de um dos lados, valor e
  /// data bastam para **perguntar**; quem decide é a pessoa.
  static Entry? ofReceipt(
    Iterable<Entry> entries, {
    required Money amount,
    required LocalDate occurredOn,
    String? name,
  }) => _nearest(
    entries.where(
      (entry) =>
          entry.origin == EntryOrigin.notification &&
          _close(entry, amount, occurredOn) &&
          _agree(entry.description, name),
    ),
    occurredOn,
  );

  /// O que já está no livro e é a movimentação de [reading], que por isso
  /// não lança de novo (RN-1077).
  ///
  /// No mesmo dia, o mesmo valor basta, venha de onde vier (RN-789). Um
  /// dia antes ou depois, só o **comprovante** com nome compatível: dois
  /// Pix de R$ 50,00 para o filho em dias seguidos, avisados pelo banco,
  /// são dois lançamentos.
  static Entry? ofNotice(Iterable<Entry> entries, BankReading reading) {
    final sameDay = PossibleDuplicate.near(
      entries,
      amount: reading.amount,
      occurredOn: reading.occurredOn,
      days: 0,
    );
    final name = reading.counterpart;
    if (sameDay != null || name == null) return sameDay;
    return _nearest(
      entries.where(
        (entry) =>
            entry.origin == EntryOrigin.share &&
            _close(entry, reading.amount, reading.occurredOn) &&
            namesAgree(entry.description, name),
      ),
      reading.occurredOn,
    );
  }

  /// Se [one] e [other] podem ser o mesmo destinatário (RN-1075): o mesmo
  /// nome depois de tirar caixa, acento e razão social; um deles cortado
  /// no fim, com ao menos duas palavras; ou a mesma pessoa pela regra dos
  /// nomes abreviados (RN-1071).
  static bool namesAgree(String one, String other) {
    final a = PossibleDuplicate.normalize(one);
    final b = PossibleDuplicate.normalize(other);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b || _cutOf(a, b) || _cutOf(b, a)) return true;
    return PersonName.of(one).sameAs(PersonName.of(other));
  }

  /// [short] é [long] cortado no fim: "padaria central do bai". Uma palavra
  /// só não basta — "padaria" é o começo de muitas padarias.
  static bool _cutOf(String short, String long) =>
      short.contains(' ') && long.startsWith(short);

  static bool _agree(String description, String? name) =>
      name == null || _unnamed(description) || namesAgree(description, name);

  /// A notificação que não disse com quem foi lança com o rótulo do tipo
  /// ("Pix enviado"): não há nome com que comparar.
  static bool _unnamed(String description) =>
      MovementKind.values.any((kind) => kind.label == description);

  static bool _close(Entry entry, Money amount, LocalDate on) =>
      entry.amount == amount && _apart(entry, on) <= reach;

  static int _apart(Entry entry, LocalDate on) =>
      on.daysUntil(entry.occurredOn).abs();

  /// O de data mais perto de [on]: com o Pix de ontem e o de hoje no
  /// livro, o comprovante de hoje é o de hoje.
  static Entry? _nearest(Iterable<Entry> candidates, LocalDate on) =>
      candidates.fold<Entry?>(
        null,
        (best, entry) =>
            best == null || _apart(entry, on) < _apart(best, on) ? entry : best,
      );
}
