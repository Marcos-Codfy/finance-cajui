/// As palavras com que a leitura de transferência separa o nome de quem
/// recebeu ou mandou o dinheiro do resto da linha do extrato (RN-1106).
///
/// Todas sem acento e em maiúsculas, como a linha fica depois de
/// simplificada, e literais (RN-733): nenhuma vem do texto lido. Os formatos
/// de banco por trás delas foram reconstruídos de exemplo, sem extrato real
/// conferido — palavra nova que aparecer entra aqui, e só aqui.
abstract final class TransferWords {
  /// Palavras do próprio banco: nunca são nome de ninguém. Antes do nome,
  /// são puladas ("PIX ENVIADO PELO PIX", "CP :"); depois dele, fecham o
  /// nome ("JOAO SILVA AGENDADO"). Sem elas, a máscara escondia o que a IA
  /// precisa para entender a linha, e a memória guardava "pessoa:pelo pix".
  static final Set<String> bank = _set(
    'PIX TED DOC TRANSF TRANSFERENCIA ENVIADO ENVIADA RECEBIDO RECEBIDA '
    'ENVIO RECEBIMENTO PELO PELA CP QR QRCODE CODE CODIGO ESTATICO DINAMICO '
    'AGENDADO AGENDADA AGENDAMENTO DEVOLVIDO DEVOLVIDA DEVOLUCAO ESTORNO '
    'ESTORNADO CHAVE COBRANCA SAQUE TROCO PAGAMENTO PAGTO PGTO TARIFA '
    'CANCELADO CANCELADA ENTRE CONTAS MESMA TITULARIDADE PROPRIA POUPANCA '
    'APLICACAO RESGATE INTERNA EXTERNA CREDITO DEBITO',
  );

  /// O que se pula entre o marcador e o nome: as palavras do banco e as
  /// que ligam ("PARA", "DE", "P/"). "DE", "DA" e "DO" ficam fora de
  /// [bank] porque também moram dentro de nomes: "MARIA DE SOUZA".
  static final Set<String> skipped = {
    ...bank,
    ..._set('PARA P DE DA DO DOS DAS AO REM DES DEST'),
  };

  /// O documento ou a conta que vem depois do nome: fecha o nome.
  static final Set<String> documents = _set(
    'CPF CNPJ AG AGENCIA CONTA CC BANCO BCO ISPB INST INSTITUICAO',
  );

  /// Nome com uma destas é de empresa: o Pix para ela é uma compra.
  static final Set<String> company = _set(
    'LTDA ME EPP EIRELI SA S/A MEI COMERCIO SERVICOS INDUSTRIA LOJA LOJAS',
  );

  /// Palavras que dizem que o Pix é uma compra, uma conta ou coisa do banco,
  /// e não dinheiro para alguém: "PIX QR CODE", "PAGAMENTO PIX", "PIX
  /// SAQUE", "TED DEVOLVIDA".
  static final Set<String> purchase = _set(
    'QR QRCODE CODE ESTATICO DINAMICO COMPRA COBRANCA BOLETO SAQUE TROCO '
    'TARIFA ESTORNO ESTORNADO DEVOLVIDO DEVOLVIDA DEVOLUCAO CANCELADO '
    'CANCELADA PAGAMENTO PAGTO PGTO FATURA',
  );

  /// A letra com acento → a mesma sem acento, em maiúsculas: uma letra por
  /// uma letra, para as posições achadas na linha simplificada valerem na
  /// original. Cada par é a letra com acento seguida da sem.
  static final Map<String, String> accents = _pairs(
    'ÁA ÀA ÂA ÃA ÄA ÉE ÈE ÊE ËE ÍI ÌI ÎI ÏI ÓO ÒO ÔO ÕO ÖO ÚU ÙU ÛU ÜU ÇC ÑN',
  );

  static Set<String> _set(String words) => words.split(' ').toSet();

  static Map<String, String> _pairs(String pairs) => {
    for (final pair in pairs.split(' ')) pair[0]: pair[1],
  };
}
