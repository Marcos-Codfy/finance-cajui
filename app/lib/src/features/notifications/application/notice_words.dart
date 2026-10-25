import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:domain/domain.dart';

/// As frases das notificações do Cajui sobre o que o banco avisou.
///
/// Seguem o guia de voz: dizem o que aconteceu e o que dá para fazer, sem
/// exclamação e sem julgamento. O valor vai à vista porque é gasto que a
/// pessoa acabou de fazer — nunca falta, dívida nem limite passado (RN-843).
abstract final class NoticeWords {
  static String _brl(Money amount) => MoneyFormat.brl(amount);

  /// "Lancei R$ 45,90 em Mercado Bom Preço" (RN-786), com a categoria e a
  /// forma embaixo, para conferir sem abrir o app.
  static RecordedAnnouncement recorded(
    Entry entry, {
    required MovementKind kind,
    required String category,
    required String method,
  }) => RecordedAnnouncement(
    entryId: entry.id,
    title: _recordedTitle(entry, kind),
    text: '$category · $method. Se não foi assim, é só desfazer.',
  );

  /// Compra é "em" um lugar; Pix e transferência são "para" alguém; boleto
  /// raramente diz de quem é.
  static String _recordedTitle(Entry entry, MovementKind kind) {
    final amount = _brl(entry.amount);
    return switch (kind) {
      MovementKind.pixSent ||
      MovementKind.transferSent => 'Lancei $amount para ${entry.description}',
      MovementKind.boletoPaid => 'Lancei o boleto de $amount',
      MovementKind.creditPurchase ||
      MovementKind.debitPurchase ||
      MovementKind.pixReceived ||
      MovementKind.transferReceived => 'Lancei $amount em ${entry.description}',
    };
  }

  /// "Entrou R$ 150,00 de Fulano. Toque para registrar" (RN-788).
  static AskAnnouncement income(String noticeId, BankReading reading) {
    final from = _name(reading);
    return AskAnnouncement(
      noticeId: noticeId,
      title: from == null
          ? 'Entrou ${_brl(reading.amount)}'
          : 'Entrou ${_brl(reading.amount)} de $from',
      text: 'Toque para registrar na renda do mês.',
      shareText: _shareText(reading, header: 'Pix recebido', nameLabel: 'De'),
    );
  }

  /// "Pix de R$ 500,00 para Marcos V M Arruda" (RN-1072): dinheiro que
  /// mudou de conta dentro da casa, sem lançamento. O toque abre a
  /// conferência, que repete o aviso e deixa lançar se foi gasto.
  static AskAnnouncement ownTransfer(String noticeId, BankReading reading) {
    final what = reading.kind == MovementKind.pixSent ? 'Pix' : 'Transferência';
    final to = _name(reading) ?? 'alguém da casa';
    return AskAnnouncement(
      noticeId: noticeId,
      title: '$what de ${_brl(reading.amount)} para $to',
      text:
          'Entre contas da casa: não entrou como gasto. Se foi gasto, toque '
          'para lançar.',
      shareText: receiptText(reading),
    );
  }

  /// A compra que pede um toque: o cartão não deu para saber, ou foi
  /// parcelada e as parcelas saem de quem confirma (RN-788).
  static AskAnnouncement purchase(String noticeId, BankReading reading) {
    final at = _name(reading);
    final what = reading.isInstallment ? 'Compra parcelada' : 'Compra';
    return AskAnnouncement(
      noticeId: noticeId,
      title: at == null
          ? '$what de ${_brl(reading.amount)}'
          : '$what de ${_brl(reading.amount)} em $at',
      text: reading.isInstallment
          ? 'Toque para registrar com as parcelas.'
          : 'Não reconheci o cartão. Toque para registrar.',
      shareText: _shareText(
        reading,
        header: 'Compra no cartão de crédito',
        nameLabel: 'Estabelecimento',
      ),
    );
  }

  /// O boleto pago sem dizer a quem: pede um toque (BL-087, 24/10/2026). Se
  /// for a fatura do cartão, lançar sozinho contaria o mês em dobro (RN-1001).
  static AskAnnouncement boleto(String noticeId, BankReading reading) =>
      AskAnnouncement(
        noticeId: noticeId,
        title: 'Boleto de ${_brl(reading.amount)}',
        text:
            'Não sei para quem foi. Toque para registrar; se for a fatura do '
            'cartão, ela não é gasto.',
        shareText: receiptText(reading),
      );

  /// O texto que o classificador lê para achar a categoria (RN-789): o
  /// mesmo formato de comprovante, com o nome no rótulo que as regras do
  /// comprovante já procuram.
  static String receiptText(BankReading reading) => _shareText(
    reading,
    header: reading.kind.label,
    nameLabel: switch (reading.kind) {
      MovementKind.pixSent || MovementKind.transferSent => 'Favorecido',
      MovementKind.boletoPaid => 'Beneficiário',
      MovementKind.pixReceived || MovementKind.transferReceived => 'De',
      MovementKind.creditPurchase ||
      MovementKind.debitPurchase => 'Estabelecimento',
    },
  );

  /// O nome com cara de nome: o banco escreve em maiúsculas.
  static String? _name(BankReading reading) =>
      MerchantName.pretty(reading.counterpart);

  /// O texto que entra na captura, no formato que as regras do comprovante
  /// já leem: um rótulo por linha, valor e data por extenso.
  static String _shareText(
    BankReading reading, {
    required String header,
    required String nameLabel,
  }) {
    final on = reading.occurredOn;
    final day = '${on.day}'.padLeft(2, '0');
    final month = '${on.month}'.padLeft(2, '0');
    final amount = _brl(reading.amount).replaceAll(MoneyFormat.nbsp, ' ');
    final installments = reading.installments;
    return [
      header,
      if (reading.counterpart case final name?) '$nameLabel: $name',
      'Valor: $amount',
      'Data: $day/$month/${on.year}',
      if (reading.isInstallment) 'Parcelado em ${installments}x',
    ].join('\n');
  }
}
