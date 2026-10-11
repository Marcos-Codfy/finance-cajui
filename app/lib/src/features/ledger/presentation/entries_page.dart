import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/error_text.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/presentation/entries_state.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_row.dart';
import 'package:cajui/src/features/ledger/presentation/month_spending_card.dart';
import 'package:cajui/src/features/receipts/application/capture_service.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/presentation/pending_captures_card.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os lançamentos do mês, e as portas para acrescentar um: fotografar o
/// comprovante, receber um compartilhado ou lançar à mão.
class EntriesPage extends ConsumerWidget {
  /// Cria a tela de lançamentos.
  const new({super.key});

  /// Abre a tela, a partir do Início.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push<void>(CajuiPageRoute(builder: (_) => const EntriesPage()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entriesStateProvider);
    return CajuiScreen(
      title: 'Lançamentos',
      overline: state is EntriesReady ? DateLabels.month(state.month) : null,
      onBack: Navigator.of(context).maybePop,
      // A rolagem em profundidade e a entrada de câmera (ADR-028).
      depth: true,
      cinematic: true,
      footer: _footer(context, ref, state),
      children: switch (state) {
        EntriesLoading() => _loading,
        EntriesFailed(:final code) => [_failure(ref, code)],
        EntriesReady() => _ready(state),
      },
    );
  }

  /// As portas de entrada de uma despesa: fotografar o comprovante de papel,
  /// escolher do aparelho um print, uma foto ou o PDF de um extrato, e
  /// lançar à mão. As duas primeiras vêm lado a lado, em cima: são os
  /// caminhos de quem tem o comprovante na mão (ADR-017).
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (capture.canPhotograph || capture.canPickFiles) ...[
          _captureRow(context, capture, ready: ready),
          const SizedBox(height: CajuiSpacing.sm),
        ],
        CajuiButton(
          label: 'Lançar',
          icon: CajuiIconData.plus,
          expand: true,
          onPressed: ready ? () => EntryFormPage.open(context) : null,
        ),
      ],
    );
  }

  /// Fotografar e escolher do aparelho, lado a lado.
  Widget _captureRow(
    BuildContext context,
    CaptureService capture, {
    required bool ready,
  }) {
    final camera = capture.canPhotograph
        ? _captureButton(
            context,
            label: 'Fotografar',
            icon: CajuiIconData.camera,
            open: ready ? capture.photograph : null,
          )
        : null;
    final gallery = capture.canPickFiles
        ? _captureButton(
            context,
            label: 'Da galeria',
            icon: CajuiIconData.image,
            open: ready ? capture.pickFromDevice : null,
          )
        : null;
    return Row(
      children: [
        ?camera,
        if (camera != null && gallery != null)
          const SizedBox(width: CajuiSpacing.sm),
        ?gallery,
      ],
    );
  }

  /// Um dos dois botões de captura, com metade da largura.
  static Widget _captureButton(
    BuildContext context, {
    required String label,
    required CajuiIconData icon,
    required Future<bool> Function()? open,
  }) => Expanded(
    child: CajuiButton(
      label: label,
      variant: CajuiButtonVariant.secondary,
      icon: icon,
      expand: true,
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
  /// Só o `E-APP-01` tem as duas saídas de pé — reabrir e copiar o código.
  /// As do `E-DATA-01` ("Ver o roteiro de restauração") e do `E-STORAGE-01`
  /// ("Abrir armazenamento") saem do app e ainda não existem: aparecem sem
  /// botão, porque um botão que faz outra coisa é pior do que nenhum
  /// (BL-033).
  Widget _failure(WidgetRef ref, ErrorCode code) {
    final text = ErrorTexts.of(code).fill(const {'fila': ''});
    final generic = code == ErrorCode.app01;
    return ErrorNotice(
      error: (code: code, text: generic ? text : ErrorText(text.message)),
      onAction: (index) => index == 0
          ? ref.invalidate(ledgerProvider)
          : Clipboard.setData(ClipboardData(text: code.code)),
    );
  }

  List<Widget> _ready(EntriesReady state) {
    return [
      const PendingCapturesCard(),
      MonthSpendingCard(spent: state.spent, voucher: state.voucher),
      const SizedBox(height: CajuiSpacing.xl),
      if (state.entries.isEmpty)
        const CajuiEmptyState(
          title: 'Nada lançado ainda',
          message:
              'Fotografe o comprovante, escolha um print ou o PDF de um '
              'extrato da galeria, ou lance o primeiro à mão.',
        ),
      for (final (index, entry) in state.entries.indexed)
        CajuiEntrance(
          index: index,
          child: EntryRow(entry: entry, book: state.book, today: state.today),
        ),
    ];
  }
}
