import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/capture_outcome.dart';
import 'package:cajui/src/features/receipts/application/capture_route.dart';
import 'package:cajui/src/features/receipts/application/capture_service.dart';
import 'package:cajui/src/features/receipts/application/pending_capture.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_view_model.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O ViewModel da captura: recebe o que chega, confere um por vez, na ordem
/// recebida (RN-705), e só avança quando a pessoa decide o que fazer.
class CaptureViewModel extends Notifier<CaptureState> {
  final List<SharedItem> _queue = [];
  SharedItem? _current;

  /// As capturas que já estão sendo fechadas. Um segundo toque em
  /// "Descartar" antes do primeiro terminar chamava `_next()` duas vezes, e o
  /// comprovante seguinte da fila sumia sem ter aparecido.
  final Set<String> _finishing = {};

  Future<void> _finish(
    Capture capture,
    Future<void> Function(CaptureService service) action,
  ) async {
    final id = capture.source.id;
    if (!_finishing.add(id)) return;
    try {
      await action(ref.read(captureServiceProvider));
      await _next();
    } finally {
      _finishing.remove(id);
    }
  }

  @override
  CaptureState build() {
    final arrivals = ref
        .watch(receiptInboxProvider)
        .arrivals
        .listen((_) => unawaited(_pull()));
    ref.onDispose(arrivals.cancel);
    // O app pode ter sido aberto por um compartilhamento: o item já está lá.
    unawaited(Future.microtask(_pull));
    return const CaptureIdle();
  }

  Future<void> _pull() async {
    _queue.addAll(await ref.read(receiptInboxProvider).takePending());
    if (state is CaptureIdle) await _next();
  }

  Future<void> _next() async {
    if (_queue.isEmpty) {
      _current = null;
      state = const CaptureIdle();
      return;
    }
    final item = _current = _queue.removeAt(0);
    state = CaptureReading(waiting: _queue.length);
    final outcome = await ref
        .read(captureServiceProvider)
        .open(item, onPage: _onPage);
    if (outcome case CaptureProposed(:final capture) when _talks(capture)) {
      await _handOver(capture);
      return;
    }
    state = switch (outcome) {
      CaptureProposed(:final capture) => CaptureReady(
        capture,
        waiting: _queue.length,
      ),
      CaptureRefused(:final code, :final detail) => CaptureFailed(
        _present(code, detail),
        waiting: _queue.length,
      ),
    };
  }

  /// O extrato vai para a conversa da Juju (RN-1100), e não para a tela de
  /// lista. Com outra conversa aberta, ele espera a vez na fila da Juju.
  static bool _talks(Capture capture) =>
      capture.proposal.documentKind.value == DocumentKind.statement ||
      CaptureRoute.of(capture.proposal) == CaptureRoute.statement;

  /// Guarda a captura em "Para conferir" — se o app fechar no meio da
  /// conversa, nada se perde — e entrega o extrato à Juju. A captura só
  /// fecha quando a conversa lança (RN-1115).
  Future<void> _handOver(Capture capture) async {
    await ref.read(captureServiceProvider).defer(capture);
    unawaited(ref.read(statementTalkProvider.notifier).start(capture));
    await _next();
  }

  void _onPage(int page, int of) {
    if (state is! CaptureReading) return;
    state = CaptureReading(page: page, of: of, waiting: _queue.length);
  }

  /// Reabre uma captura guardada em "Para conferir".
  Future<void> reopen(PendingCapture pending) async {
    state = const CaptureReading();
    final capture = await ref.read(captureServiceProvider).reopen(pending);
    if (_talks(capture)) {
      await _handOver(capture);
      return;
    }
    state = CaptureReady(capture, waiting: _queue.length);
  }

  /// Abre a conferência para uma frase ditada (RN-1091, BL-050): sem a IA,
  /// a fala é lida como um comprovante, pelo leitor do aparelho, e entra na
  /// mesma fila do que foi compartilhado.
  Future<void> startText(String text) async {
    _queue.add(SharedText(id: ref.read(newIdProvider)(), text: text));
    if (state is CaptureIdle) await _next();
  }

  /// Tenta ler de novo o item em que a leitura falhou (`E-CAPT-07`).
  Future<void> retry() async {
    final item = _current;
    if (item != null) _queue.insert(0, item);
    await _next();
  }

  /// O lançamento foi gravado: fecha a captura, aprende e segue para a
  /// próxima da fila.
  Future<void> confirmed(Capture capture, Entry entry) =>
      _finish(capture, (service) => service.confirmed(capture, entry));

  /// "É uma despesa": a mesma captura, na conferência de lançamento.
  void treatAsExpense() {
    final current = state;
    if (current is! CaptureReady) return;
    state = CaptureReady(
      current.capture,
      waiting: current.waiting,
      asExpense: true,
    );
  }

  /// A captura virou outra coisa que não um lançamento só — entrada,
  /// pagamento de fatura, as linhas de um extrato —, ou não virou nada:
  /// fecha, sem aprender, e segue para a próxima da fila.
  Future<void> closed(Capture capture) =>
      _finish(capture, (service) => service.close(capture));

  /// "Conferir depois".
  Future<void> defer(Capture capture) =>
      _finish(capture, (service) => service.defer(capture));

  /// "Descartar".
  Future<void> discard(Capture capture) =>
      _finish(capture, (service) => service.discard(capture));

  /// Dispensa o aviso de uma captura que falhou e segue.
  Future<void> dismiss() => _next();

  static PresentedError _present(ErrorCode code, Map<String, Object?> detail) {
    String megabytes(Object? bytes) {
      final value = bytes is int ? bytes : 0;
      return '${(value / (1024 * 1024)).ceil()} MB';
    }

    return (
      code: code,
      text: ErrorTexts.of(code).fill({
        'tamanho': megabytes(detail['sizeBytes']),
        'falta': megabytes(detail['missingBytes']),
      }),
    );
  }
}

/// O estado da captura em curso.
final captureProvider = NotifierProvider<CaptureViewModel, CaptureState>(
  CaptureViewModel.new,
);
