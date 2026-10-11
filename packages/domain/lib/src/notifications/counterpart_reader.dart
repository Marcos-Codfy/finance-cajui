import 'package:domain/src/notifications/bank_app.dart';
import 'package:domain/src/notifications/bank_notification.dart';
import 'package:domain/src/notifications/movement_kind.dart';
import 'package:domain/src/notifications/notice_text.dart';

/// Com quem foi a movimentação: o estabelecimento da compra, quem recebeu o
/// Pix, quem o mandou.
///
/// Cada banco põe o nome num lugar — "em MERCADO X", "para Fulano",
/// "Local: MERCADO X", antes do valor ou depois da hora. As regras vão do
/// rótulo explícito ao palpite pela posição, e o nome termina onde começa o
/// resto da frase: "para o cartão", "no valor de", a data, a pontuação.
abstract final class CounterpartReader {
  /// O nome: começa por algo que não é espaço nem pontuação, e é curto.
  static const _name = r'([^\s,;.:].{0,58}?)';

  /// As palavras que, depois de um espaço, encerram o nome.
  static const _stopWords = [
    r'para o\b',
    r'para seu\b',
    'no cart',
    'com o cart',
    'com cart',
    'com (?:visa|master|elo|amex|hiper)',
    'no valor',
    r'valor\b',
    'no d[ée]bito',
    'no cr[ée]dito',
    r'em \d',
    r'[àa]s \d',
    r'final\b',
    r'foi\b',
    'aprovad',
    'conclu[íi]d',
    'realizad',
    'efetuad',
    r'via\b',
    'com sucesso',
    r'dia \d',
    r'R\$',
  ];

  /// Onde o nome termina: uma das palavras acima, pontuação, ponto final
  /// ou o fim do texto.
  static final String _stop =
      '(?=\\s+(?:${_stopWords.join('|')})|\\s*[,;!(]|\\.(?:\\s|\$)|\\s*\$)';

  static RegExp _rule(String before, [String? after]) =>
      RegExp(before + _name + (after ?? _stop), caseSensitive: false);

  /// "Local: MERCADO X", "Favorecido: Fulano", "Remetente: Fulano".
  static final RegExp _label = _rule(
    r'\b(?:local|estabelecimento|favorecido|destinat[áa]rio|'
    r'benefici[áa]rio|remetente|pagador)\s*:\s*',
  );

  /// "aprovada em MERCADO X" — mas não "em 10/10", "em seu cartão".
  static final RegExp _at = _rule(r'\bem\s+(?!\d|r\$|sua\b|seu\b|conta\b)');

  /// "Você pagou R$ 45,90 a LOJA X".
  static final RegExp _afterAmount = _rule(
    r'R\$\s?[\d.,]+\s+(?:a|para|na|no|em)\s+(?!o cart|seu\b|sua\b|\d)',
  );

  /// "Compra aprovada MERCADO X R$ 45,90".
  static final RegExp _beforeAmount = _rule(
    r'aprovad[ao]:?\s+(?!no\b|na\b|de\b|em\b|r\$|para\b|\d)',
    r'(?=\s+R\$)',
  );

  /// "... em 10/10 às 12:30 MERCADO X".
  static final RegExp _afterTime = _rule(
    r'\d{1,2}[:h]\d{2}\s+(?:em\s+|-\s+)?(?!r\$|\d)',
  );

  /// "para Fulano" — mas não "para o cartão", "para sua conta".
  static final RegExp _to = _rule(
    r'\bpara\s+(?!o\b|a\b|seu\b|sua\b|voce\b|conta\b|r\$|\d)',
  );

  /// "de Fulano" — mas não "de R$ 150,00", "de uma transferência".
  static final RegExp _from = _rule(
    r'\bde\s+(?!r\$|\d|um\b|uma\b|pix\b|transfer|conta\b)',
  );

  /// O nome em [notice], para uma movimentação [kind]; `null` quando o
  /// banco não diz.
  static String? nameIn(BankNotification notice, MovementKind kind) {
    // A carteira do Google põe o estabelecimento no título, e só ele.
    if (BankApp.ofPackage(notice.packageName) == BankApp.googleWallet) {
      return _clean(notice.title);
    }
    final rules = _rulesFor(kind);
    for (final text in [notice.text, notice.title]) {
      final flat = NoticeText.plain(text);
      for (final rule in rules) {
        final found = _clean(rule.firstMatch(flat)?.group(1));
        if (found != null) return found;
      }
    }
    return null;
  }

  static List<RegExp> _rulesFor(MovementKind kind) => switch (kind) {
    MovementKind.creditPurchase || MovementKind.debitPurchase => [
      _label,
      _at,
      _afterAmount,
      _beforeAmount,
      _afterTime,
    ],
    MovementKind.pixSent || MovementKind.transferSent => [_label, _to],
    MovementKind.pixReceived ||
    MovementKind.transferReceived => [_label, _from],
    MovementKind.boletoPaid => [_label],
  };

  /// O nome sem pontuação sobrando; `null` quando não sobra nome — só
  /// dígitos, um valor, uma letra.
  static String? _clean(String? raw) {
    final name = raw?.trim().replaceAll(RegExp(r'[\s.,;:!-]+$'), '') ?? '';
    if (name.length < 2 || name.contains(r'R$')) return null;
    if (!RegExp('[A-Za-zÀ-ú]').hasMatch(name)) return null;
    return name;
  }
}
