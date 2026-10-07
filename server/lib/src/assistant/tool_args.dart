import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/assistant/tool_refusal.dart';

/// Lê os argumentos que o modelo escreveu num pedido de ferramenta.
///
/// É entrada não confiável, e lida como tal: tipo errado é recusa, texto
/// longo é cortado, data e mês passam pelos mesmos leitores do contrato.
/// O que recusa volta ao modelo como motivo, e não como exceção do
/// servidor — o modelo erra o formato de vez em quando, e aí ele corrige.
abstract final class ToolArgs {
  /// O texto em [name], cortado em [maxLength]; `null` quando não veio.
  static String? text(
    Map<String, Object?> args,
    String name, {
    int maxLength = 80,
  }) {
    final raw = args[name];
    if (raw is! String) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;
    return value.length > maxLength ? value.substring(0, maxLength) : value;
  }

  /// O texto obrigatório em [name].
  static String required(Map<String, Object?> args, String name) =>
      text(args, name) ?? (throw ToolRefusal('falta o argumento "$name"'));

  /// O inteiro em [name]; `null` quando não veio. Número escrito como texto
  /// ou com casa decimal ainda vale: o modelo às vezes escreve assim.
  static int? integer(Map<String, Object?> args, String name) {
    final raw = args[name];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse('$raw');
  }

  /// Um valor em centavos, obrigatório e maior que zero.
  static int positiveCents(Map<String, Object?> args, String name) {
    final cents = integer(args, name);
    if (cents == null || cents <= 0) {
      throw ToolRefusal(
        '"$name" precisa ser um inteiro positivo, em centavos: R\$ 12,50 é '
        '1250',
      );
    }
    return cents;
  }

  /// A data `AAAA-MM-DD` em [name]; `null` quando não veio.
  static LocalDate? date(Map<String, Object?> args, String name) {
    final raw = text(args, name);
    if (raw == null) return null;
    try {
      return EntryCodec.parseDate(raw);
    } on FormatException {
      throw ToolRefusal('"$name" precisa ser uma data AAAA-MM-DD');
    }
  }

  /// O mês `AAAA-MM` em [name]; `null` quando não veio.
  static BudgetMonth? month(Map<String, Object?> args, String name) {
    final raw = text(args, name);
    if (raw == null) return null;
    try {
      return EntryCodec.parseMonth(raw);
    } on FormatException {
      throw ToolRefusal('"$name" precisa ser um mês AAAA-MM');
    }
  }
}
