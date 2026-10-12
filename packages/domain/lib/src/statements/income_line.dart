/// Se uma linha de entrada de extrato é mesmo dinheiro que entrou (RN-1110).
///
/// A IA chama de entrada tudo o que soma: o salário, mas também o estorno
/// de uma compra, o resgate da poupança e o "pagamento recebido" que a
/// fatura do cartão mostra quando a conta é paga. Só o primeiro é renda: o
/// estorno devolve um gasto, o resgate é dinheiro seu mudando de lugar, e o
/// pagamento da fatura nunca é renda nem gasto (RN-756). Por isso a entrada
/// só é certa quando a linha diz, com palavras do banco, que é dinheiro
/// chegando — e nenhuma palavra diz o contrário. As palavras são literais
/// (RN-733).
abstract final class IncomeLine {
  /// Se [line] diz que é dinheiro chegando, sem nada que diga o contrário.
  static bool isClear(String line) {
    final plain = _plain(line);
    if (_notIncome.any(plain.contains)) return false;
    return _income.any(plain.contains);
  }

  /// Palavras que dizem que o dinheiro chegou.
  static const _income = [
    'SALARIO',
    'PROVENTO',
    'TED RECEBIDA',
    'DOC RECEBIDO',
    'PIX RECEBIDO',
    'TRANSFERENCIA RECEBIDA',
    'TRANSF RECEBIDA',
    'DEPOSITO',
    'CREDITO EM CONTA',
  ];

  /// Palavras que dizem que não é renda, mesmo somando.
  static const _notIncome = [
    'ESTORNO',
    'RESGATE',
    'PAGAMENTO RECEBIDO',
    'PAGTO RECEBIDO',
    'PGTO RECEBIDO',
    'CREDITO DE FATURA',
    'DEVOLUCAO',
    'DEVOLVID',
    'CANCELAMENTO',
  ];

  static String _plain(String text) => text.toUpperCase().replaceAllMapped(
    RegExp('[ÁÀÂÃÉÊÍÓÔÕÚÇ]'),
    (match) => _accents[match[0]!]!,
  );

  static const _accents = {
    'Á': 'A',
    'À': 'A',
    'Â': 'A',
    'Ã': 'A',
    'É': 'E',
    'Ê': 'E',
    'Í': 'I',
    'Ó': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ú': 'U',
    'Ç': 'C',
  };
}
