import 'package:cajui/src/features/receipts/application/pending_capture.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Um comprovante lido e classificado, à espera de um toque da pessoa.
///
/// Nada do que está aqui foi gravado como lançamento: a proposta só vira
/// fato depois da confirmação (RN-795).
@immutable
final class Capture {
  /// Junta a captura [source] à proposta [proposal].
  const new({required this.source, required this.proposal});

  /// O comprovante lido.
  final PendingCapture source;

  /// O que o classificador propõe, com a confiança de cada campo.
  final EntryProposal proposal;
}
