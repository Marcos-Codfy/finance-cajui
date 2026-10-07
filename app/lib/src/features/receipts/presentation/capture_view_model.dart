import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/capture_outcome.dart';
import 'package:cajui/src/features/receipts/application/pending_capture.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O ViewModel da captura: recebe o que chega, confere um por vez, na ordem
/// recebida (RN-705), e só avança quando a pessoa decide o que fazer.
class CaptureViewModel extends Notifier<CaptureState> {
  final List<SharedItem> _queue = [];
  SharedItem? _current;

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

  void _onPage(int page, int of) {
    if (state is! CaptureReading) return;
    state = CaptureReading(page: page, of: of, waiting: _queue.length);
  }

  /// Reabre uma captura guardada em "Para conferir".
  Future<void> reopen(PendingCapture pending) async {
    state = const CaptureReading();
    final capture = await ref.read(captureServiceProvider).reopen(pending);
    state = CaptureReady(capture, waiting: _queue.length);
  }

  /// Tenta ler de novo o item em que a leitura falhou (`E-CAPT-07`).
  Future<void> retry() async {
    final item = _current;
    if (item != null) _queue.insert(0, item);
    await _next();
  }

  /// O lançamento foi gravado: fecha a captura, aprende e segue para a
  /// próxima da fila.
  Future<void> confirmed(Capture capture, Entry entry) async {
    await ref.read(captureServiceProvider).confirmed(capture, entry);
    await _next();
  }

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
  Future<void> closed(Capture capture) async {
    await ref.read(captureServiceProvider).close(capture);
    await _next();
  }

  /// "Conferir depois".
  Future<void> defer(Capture capture) async {
    await ref.read(captureServiceProvider).defer(capture);
    await _next();
  }

  /// "Descartar".
  Future<void> discard(Capture capture) async {
    await ref.read(captureServiceProvider).discard(capture);
    await _next();
  }

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
