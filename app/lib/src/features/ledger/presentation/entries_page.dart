import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/device/storage_settings.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/error_text.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/presentation/entries_day_list.dart';
import 'package:cajui/src/features/ledger/presentation/entries_empty.dart';
import 'package:cajui/src/features/ledger/presentation/entries_filters_bar.dart';
import 'package:cajui/src/features/ledger/presentation/entries_state.dart';
import 'package:cajui/src/features/ledger/presentation/entries_view_model.dart';
import 'package:cajui/src/features/ledger/presentation/ledger_coordinator.dart';
import 'package:cajui/src/features/ledger/presentation/month_spending_card.dart';
import 'package:cajui/src/features/ledger/presentation/month_stepper.dart';
import 'package:cajui/src/features/receipts/application/capture_service.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/presentation/pending_captures_card.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os lançamentos do mês, com busca e filtros, e as portas para acrescentar
/// um: fotografar o comprovante, receber um compartilhado ou lançar à mão.
class EntriesPage extends ConsumerWidget {
  /// Cria a tela de lançamentos.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entriesStateProvider);
    return CajuiScreen(
      title: 'Lançamentos',
      onBack: context.back,
      // A rolagem em profundidade e a entrada de câmera (ADR-028).
      depth: true,
      cinematic: true,
      footer: _footer(context, ref, state),
      children: switch (state) {
        EntriesLoading() => _loading,
        EntriesFailed(:final code) => [_failure(ref, code)],
        EntriesReady() => _ready(state, ref),
      },
    );
  }

  /// As portas de entrada de uma despesa, numa linha só: "Gastei" à mão e,
  /// ao lado, fotografar o comprovante ou escolher do aparelho um print,
  /// uma foto ou o PDF de um extrato (ADR-017). Eram três botões grandes
  /// empilhados, e a lista — o assunto da tela — começava no rodapé
  /// (27/11/2026).
  ///
  /// Na web não há rodapé nenhum: lá o livro **desce** do servidor e não há
  /// onde gravar — tocar em "Lançar" levava ao formulário e só estourava na
  /// hora de salvar. Esconder o botão não é o que garante isso: quem garante
  /// é o `append` da consulta, que recusa por construção (T-12). Aqui é só
  /// para a tela parar de convidar para uma porta fechada.
  Widget _footer(BuildContext context, WidgetRef ref, EntriesState state) {
    if (!ref.watch(ledgerUplinkProvider).isPaired) {
      return const SizedBox.shrink();
    }
    final ready = state is EntriesReady;
    final capture = ref.watch(captureServiceProvider);
    return Row(
      children: [
        Expanded(
          child: CajuiButton(
            label: 'Gastei',
            icon: CajuiIconData.plus,
            expand: true,
            onPressed: ready
                ? () => context
                      .coordinator(ledgerCoordinatorProvider)
                      .openEntryForm()
                : null,
          ),
        ),
        ..._capture(context, capture, ready: ready),
      ],
    );
  }

  /// Fotografar e escolher do aparelho, como ícones com nome ao lado do
  /// "Gastei".
  List<Widget> _capture(
    BuildContext context,
    CaptureService capture, {
    required bool ready,
  }) => [
    if (capture.canPhotograph)
      _captureButton(
        context,
        caption: 'Foto',
        label: 'Fotografar comprovante',
        icon: CajuiIconData.camera,
        open: ready ? capture.photograph : null,
      ),
    if (capture.canPickFiles)
      _captureButton(
        context,
        caption: 'Galeria',
        label: 'Escolher da galeria ou dos arquivos',
        icon: CajuiIconData.image,
        open: ready ? capture.pickFromDevice : null,
      ),
  ];

  /// Um dos botões de captura.
  static Widget _captureButton(
    BuildContext context, {
    required String caption,
    required String label,
    required CajuiIconData icon,
    required Future<bool> Function()? open,
  }) => Padding(
    padding: const EdgeInsets.only(left: CajuiSpacing.sm),
    child: CajuiIconButton(
      icon: icon,
      caption: caption,
      semanticLabel: label,
      variant: CajuiButtonVariant.secondary,
      onPressed: open == null ? null : () => _open(context, open),
    ),
  );

  /// A foto e o arquivo escolhido não voltam por aqui: entram na fila da
  /// captura, e a conferência abre por cima do app, igual à do
  /// compartilhamento.
  static Future<void> _open(
    BuildContext context,
    Future<bool> Function() open,
  ) async {
    final feedback = CajuiFeedbackScope.of(context);
    if (!await open()) feedback.notice();
  }

  /// Carregando tem a forma do que vem: três linhas de lançamento.
  static const _loading = <Widget>[
    CajuiSkeleton(height: 96),
    SizedBox(height: CajuiSpacing.xl),
    CajuiSkeleton(height: 56),
    SizedBox(height: CajuiSpacing.sm),
    CajuiSkeleton(height: 56),
    SizedBox(height: CajuiSpacing.sm),
    CajuiSkeleton(height: 56),
  ];

  /// Por que o livro não abriu, com o texto do código certo: cadeia
  /// quebrada e falta de espaço pedem saídas diferentes de "reabrir".
  ///
  /// O `E-APP-01` reabre e copia o código; o `E-STORAGE-01` abre o
  /// armazenamento do aparelho e, depois de liberar espaço, tenta de novo
  /// (27/11/2026). A do `E-DATA-01` ("Ver o roteiro de restauração") sai do
  /// app e ainda não existe: aparece sem botão, porque um botão que faz
  /// outra coisa é pior do que nenhum (BL-033).
  Widget _failure(WidgetRef ref, ErrorCode code) {
    final text = ErrorTexts.of(code)
        .fill(const {'fila': '', 'item': 'os lançamentos novos'});
    final withExits = code == ErrorCode.app01 || code == ErrorCode.storage01;
    return ErrorNotice(
      error: (code: code, text: withExits ? text : ErrorText(text.message)),
      onAction: (index) => switch ((code, index)) {
        (ErrorCode.storage01, 0) => ref.read(storageSettingsProvider).open(),
        (ErrorCode.app01, 1) => Clipboard.setData(
          ClipboardData(text: code.code),
        ),
        _ => ref.invalidate(ledgerProvider),
      },
    );
  }

  /// O mês com as setas logo abaixo do título: o gasto do cartão de cima e
  /// a lista de baixo são os do mês que elas mostram. A busca e os chips
  /// têm chave própria — a lista embaixo deles muda a cada letra, e sem
  /// chave o campo perdia o foco no meio da digitação.
  List<Widget> _ready(EntriesReady state, WidgetRef ref) {
    final filters = ref.read(entriesViewModelProvider.notifier);
    return [
      const PendingCapturesCard(),
      MonthStepper(
        key: const ValueKey('entries-month'),
        label: DateLabels.month(state.month),
        onPrevious: filters.previousMonth,
        onNext: state.isCurrentMonth ? null : filters.nextMonth,
      ),
      const SizedBox(height: CajuiSpacing.sm),
      MonthSpendingCard(spent: state.spent),
      const SizedBox(height: CajuiSpacing.lg),
      _filters(state),
      const SizedBox(height: CajuiSpacing.lg),
      if (state.entries.isEmpty)
        EntriesEmpty(state: state)
      else
        EntriesDayList(state: state),
    ];
  }

  /// A busca e os chips, num bloco só, com chave: a lista embaixo muda a
  /// cada letra, e sem chave o campo perdia o foco no meio da digitação.
  static Widget _filters(EntriesReady state) =>
      EntriesFiltersBar(key: const ValueKey('entries-filters'), state: state);
}
