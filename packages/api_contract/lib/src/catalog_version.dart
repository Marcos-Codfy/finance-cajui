import 'package:api_contract/src/json_reader.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// A versão de um item do cadastro — cartão ou categoria — como o app e o
/// servidor a comparam para decidir quem fica (ADR-024).
///
/// Antes o cadastro só atravessava **uma vez**: o servidor gravava o cartão
/// com a chave `card-<id>`, e a chave repetida não grava de novo. Trocar o
/// limite, o dia de fechamento ou o nome num celular ficava só nele, sem
/// erro nenhum. Agora cada versão leva o que diz ([signature]) e quando foi
/// definida ([definedAt]), e vale a mais nova.
@immutable
final class CatalogVersion {
  /// Cria a versão com a assinatura [signature] e o carimbo [definedAt].
  const new({required this.signature, this.definedAt});

  /// A versão descrita pelo conteúdo gravado [payload].
  factory of(Map<String, Object?> payload) => CatalogVersion(
    signature: signatureOf(payload),
    definedAt: definedAtOf(payload),
  );

  /// O campo do carimbo no conteúdo. Fica fora da assinatura: diz
  /// **quando**, e não **o quê**.
  static const stampField = 'definedAt';

  /// Tudo o que no item é conteúdo, num texto comparável.
  final String signature;

  /// Quando esta versão foi definida, em UTC. Nulo nas versões gravadas
  /// antes do carimbo existir, que contam como as mais velhas.
  final DateTime? definedAt;

  /// [payload] com o carimbo [at]; sem carimbo, como está.
  static Map<String, Object?> stamped(
    Map<String, Object?> payload,
    DateTime? at,
  ) => at == null
      ? payload
      : {...payload, stampField: at.toUtc().toIso8601String()};

  /// O carimbo gravado em [payload]; nulo quando não há, ou não se lê —
  /// pela mesma leitura dos outros carimbos, que exige o fuso.
  static DateTime? definedAtOf(Map<String, Object?> payload) =>
      JsonReader.instantOf(payload[stampField]);

  /// O conteúdo de [payload] em ordem fixa de campo, sem o identificador e
  /// sem o carimbo: dois aparelhos chegam ao mesmo texto para o mesmo item.
  static String signatureOf(Map<String, Object?> payload) {
    final keys =
        payload.keys.where((key) => key != 'id' && key != stampField).toList()
          ..sort();
    return [for (final key in keys) '$key=${payload[key]}'].join('|');
  }

  /// Se esta versão toma o lugar de [current] **guardada**: diz outra coisa
  /// e não é mais velha. Entre duas sem carimbo, vale a que chega — era o
  /// que acontecia antes, quando cada edição era um fato novo no aparelho.
  bool replaces(CatalogVersion? current) {
    if (current == null) return true;
    if (current.signature == signature) return false;
    return !EditStamp.isNewer(current.definedAt, definedAt);
  }

  /// Se esta versão, **deste aparelho**, deve subir por cima de [remote]:
  /// diz outra coisa e é estritamente mais nova. Versão sem carimbo nunca
  /// sobe por cima: dois aparelhos com versões velhas diferentes ficariam
  /// trocando uma pela outra a cada sincronização.
  bool overrides(CatalogVersion? remote) {
    if (remote == null) return true;
    if (remote.signature == signature) return false;
    return EditStamp.isNewer(definedAt, remote.definedAt);
  }
}
