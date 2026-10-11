import 'package:domain/src/household/person_name.dart';
import 'package:domain/src/notifications/bank_reading.dart';
import 'package:domain/src/notifications/movement_kind.dart';
import 'package:domain/src/shared/edit_stamp.dart';
import 'package:meta/meta.dart';

/// Os nomes de quem divide o orçamento, como aparecem no banco (RN-1070).
///
/// Servem para uma coisa só: reconhecer o dinheiro que muda de conta
/// **dentro da casa**. Pix do Marcos para a conta da esposa não é gasto, e
/// o Pix que ela recebe dele não é renda nova — o dinheiro já tinha sido
/// contado quando o salário entrou (RN-1072, RN-1073).
@immutable
final class HouseholdNames {
  /// Cria a lista. [definedAt] é quando ela foi decidida: entre dois
  /// celulares, vale a mais nova (ADR-024).
  const new({this.names = const [], this.definedAt});

  /// Ninguém cadastrado: nenhuma movimentação é tratada como da casa.
  static const empty = HouseholdNames();

  /// Quantos nomes cabem. A casa é de duas pessoas; a folga é para quem
  /// tem a renda dividida em mais de um nome.
  static const maxNames = 6;

  /// O maior nome aceito, o mesmo teto de texto dos fatos que sincronizam.
  static const maxLength = 80;

  /// Os nomes, como a pessoa os escreveu.
  final List<String> names;

  /// Quando a lista foi decidida; nula na lista vazia de fábrica.
  final DateTime? definedAt;

  /// Se [name] serve como nome da casa: nome e sobrenome, dentro do teto.
  /// Só o primeiro nome casaria com qualquer pessoa de mesmo nome.
  static bool accepts(String name) =>
      name.trim().length <= maxLength && PersonName.of(name).isFull;

  /// Se [name] pode entrar: é aceito, não está na lista e ainda cabe.
  bool canAdd(String name) =>
      accepts(name) && names.length < maxNames && whoIs(name) == null;

  /// A lista com [name] a mais, decidida em [at]. Nome que não pode entrar
  /// deixa a lista como está.
  HouseholdNames adding(String name, DateTime at) => canAdd(name)
      ? HouseholdNames(names: [...names, name.trim()], definedAt: at)
      : this;

  /// A lista sem [name], decidida em [at].
  HouseholdNames removing(String name, DateTime at) => HouseholdNames(
    names: [...names.where((known) => known != name)],
    definedAt: at,
  );

  /// Se esta lista foi decidida depois de [other].
  bool isNewerThan(HouseholdNames other) =>
      EditStamp.isNewer(definedAt, other.definedAt);

  /// O nome cadastrado que [written] é, pela regra da RN-1071; `null`
  /// quando não é ninguém da casa ou quando o banco não disse o nome.
  String? whoIs(String? written) {
    if (written == null) return null;
    final read = PersonName.of(written);
    return names
        .where((name) => PersonName.of(name).isWrittenAs(read))
        .firstOrNull;
  }

  /// Se [reading] é dinheiro mudando de conta dentro da casa: Pix ou
  /// transferência, enviado ou recebido, com alguém da casa do outro lado
  /// (RN-1072, RN-1073). Boleto e compra nunca são.
  bool movesWithin(BankReading reading) =>
      _betweenAccounts.contains(reading.kind) &&
      whoIs(reading.counterpart) != null;

  static const Set<MovementKind> _betweenAccounts = {
    MovementKind.pixSent,
    MovementKind.pixReceived,
    MovementKind.transferSent,
    MovementKind.transferReceived,
  };

  /// Os primeiros nomes que os salários do plano sugerem, para a pessoa
  /// completar com o sobrenome: "Salário da Beatriz" sugere "Beatriz", e
  /// "Meu salário" não sugere nada (RN-1070).
  List<String> suggestedBy(Iterable<String> salaryNames) => [
    ...salaryNames.map(_personIn).nonNulls.where(_isNew).toSet(),
  ];

  /// Quem já está na lista, pelo primeiro nome, não é sugerido de novo.
  bool _isNew(String name) =>
      !names.any((known) => _firstName(known) == _firstName(name));

  /// O que sobra do nome do salário sem as palavras que não são nome. Nome
  /// começa com maiúscula: "Salário esposa" não sugere ninguém.
  static String? _personIn(String salary) {
    final rest = salary
        .trim()
        .split(RegExp(r'\s+'))
        .skipWhile((word) => _notAName.contains(word.toLowerCase()))
        .join(' ');
    if (rest.isEmpty) return null;
    final first = rest[0];
    return first != first.toLowerCase() ? rest : null;
  }

  static String _firstName(String name) =>
      PersonName.of(name).words.firstOrNull ?? '';

  static const _notAName = {
    'salário',
    'salario',
    'renda',
    'meu',
    'minha',
    'de',
    'da',
    'do',
  };
}
