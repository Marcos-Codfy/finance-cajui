import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:cajui/src/features/receipts/application/pending_capture.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Para conferir": os comprovantes já lidos que ainda esperam um toque.
///
/// Ficam à vista, com contagem, porque não contam em indicador nenhum
/// (RN-721): um comprovante esquecido aqui é uma compra que o mês não viu.
class PendingCapturesCard extends ConsumerWidget {
  /// Cria o cartão. Não ocupa espaço quando não há nada para conferir.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingCapturesProvider).value ?? const [];
    if (pending.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.xl),
      child: CajuiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              pending.length == 1
                  ? '1 comprovante para conferir'
                  : '${pending.length} comprovantes para conferir',
              style: CajuiTheme.of(context).typography.bodyStrong,
            ),
            const SizedBox(height: CajuiSpacing.sm),
            for (final capture in pending) _row(ref, capture),
          ],
        ),
      ),
    );
  }

  Widget _row(WidgetRef ref, PendingCapture capture) {
    final today = ref.watch(todayProvider);
    final name = _nameOf(capture);
    return CajuiListRow(
      title: name,
      subtitle: 'chegou ${DateLabels.day(capture.receivedOn, today: today)}',
      semanticLabel: 'Conferir $name',
      trailing: const CajuiIcon(CajuiIconData.chevronRight),
      onPressed: () => ref.read(captureProvider.notifier).reopen(capture),
    );
  }

  /// O estabelecimento, lido como na conferência.
  ///
  /// Antes era a primeira linha do texto, e numa **foto** de cupom essa linha
  /// é a do CNPJ: o cartão mostrava o documento no lugar do nome da loja.
  static String _nameOf(PendingCapture capture) =>
      MerchantName.pretty(MerchantReader.nameIn(capture.text)) ?? 'Comprovante';
}
