/// Mascara os dados pessoais de um comprovante antes que o texto saia do
/// aparelho — e de novo no servidor, antes de montar o pedido à IA (RN-730).
///
/// Cada dado vira um **marcador fixo**, que preserva o tipo e nada do
/// conteúdo: `CPF 123.456.789-09` vira `CPF [CPF]` (RN-731). Ficam, de
/// propósito, o estabelecimento, o valor, a data e a forma de pagamento — o
/// mínimo para classificar (RN-734).
///
/// As expressões são literais fixas, nunca montadas com texto de entrada, e
/// sem quantificador aninhado: a entrada é limitada em tamanho, e o custo
/// cresce em linha reta com ela (RN-733).
abstract final class PiiRedactor {
  static final List<(RegExp, String)> _patterns = [
    // Linha digitável e código de barras: antes de tudo, porque contêm
    // sequências que parecem CPF, telefone e conta.
    (
      RegExp(r'\b\d{5}\.?\d{5}\s\d{5}\.?\d{6}\s\d{5}\.?\d{6}\s\d\s\d{14}\b'),
      '[BOLETO]',
    ),
    (RegExp(r'\b\d{44,48}\b'), '[BOLETO]'),
    (
      RegExp(
        r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
        caseSensitive: false,
      ),
      '[CHAVE_PIX]',
    ),
    (RegExp(r'\bE\d{8}[0-9A-Za-z]{10,40}\b'), '[ID]'),
    (
      RegExp(
        r'(?:\d{4}|\*{4})[ -]?(?:\d{4}|\*{4})[ -]?(?:\d{4}|\*{4})[ -]?\d{4}\b',
      ),
      '[CARTAO]',
    ),
    (RegExp(r'\*{4}\s?\d{4}\b'), '[CARTAO]'),
    (RegExp(r'\bfinal\s+\d{4}\b', caseSensitive: false), '[CARTAO]'),
    (RegExp(r'\b\d{2}\.?\d{3}\.?\d{3}/\d{4}-?\d{2}\b'), '[CNPJ]'),
    (
      // O hífen é opcional: a camada de texto de alguns PDFs o perde, e o
      // CPF "meio mascarado" do banco (***.123.456-**) ainda traz seis dígitos
      // de verdade — continua sendo dado pessoal.
      RegExp(
        r'(?:\d{3}|\*{3})\.(?:\d{3}|\*{3})\.(?:\d{3}|\*{3})-?(?:\d{2}|\*{2})',
      ),
      '[CPF]',
    ),
    (RegExp(r'[\w.+-]{1,64}@[\w-]{1,63}(?:\.[\w-]{1,63}){1,4}'), '[EMAIL]'),
    (RegExp(r'\(\d{2}\)\s?9?\d{4}[-\s]?\d{4}\b'), '[TELEFONE]'),
    (RegExp(r'\b\d{5}-\d{3}\b'), '[ENDERECO]'),
    (RegExp(r'\b\d{11}\b'), '[CPF]'),
  ];

  static final List<(RegExp, String)> _labelled = [
    (
      RegExp(r'\b(chave(?:\s+pix)?\s*:?\s*)\S{3,80}', caseSensitive: false),
      '[CHAVE_PIX]',
    ),
    (
      RegExp(
        r'\b((?:ag[eê]ncia|ag\.?|conta|c/c|cc)\s*:?\s*)\d[\d.\-]{2,14}',
        caseSensitive: false,
      ),
      '[CONTA]',
    ),
    (
      RegExp(
        r'\b((?:autentica[cç][aã]o|nsu|protocolo|id da transa[cç][aã]o|identificador|controle)\s*:?\s*)[0-9A-Za-z.\-]{6,60}',
        caseSensitive: false,
      ),
      '[ID]',
    ),
    (
      RegExp(
        r'\b(saldo[^\n\d]{0,40})R?\$?\s?[\d.]{1,12},\d{2}',
        caseSensitive: false,
      ),
      '[SALDO]',
    ),
    (
      RegExp(
        r'^((?:rua|av\.?|avenida|travessa|alameda|quadra|rodovia)\s)[^\n]{3,120}',
        caseSensitive: false,
        multiLine: true,
      ),
      '[ENDERECO]',
    ),
    (
      RegExp(
        r'\b((?:pagador|titular|cliente)\s*:\s*)[^\n]{2,80}',
        caseSensitive: false,
      ),
      '[NOME]',
    ),
  ];

  static final _counterparty = RegExp(
    r'^(\s*(?:destinat[aá]rio|favorecido|recebedor|benefici[aá]rio|nome)\s*:\s*)[^\n]{2,80}$',
    caseSensitive: false,
  );

  /// O texto com os dados pessoais trocados por marcadores. [householdNames]
  /// são os nomes cadastrados do domicílio, mascarados onde aparecerem.
  static String redact(String text, {List<String> householdNames = const []}) {
    var result = text;
    for (final (pattern, marker) in _patterns) {
      result = result.replaceAll(pattern, marker);
    }
    for (final (pattern, marker) in _labelled) {
      result = result.replaceAllMapped(pattern, (m) => '${m.group(1)}$marker');
    }
    final lines = _maskBlockPeople(_maskPeople(result.split('\n')));
    return householdNames.fold(lines.join('\n'), _maskName);
  }

  static final _blockLabel = RegExp(
    r'^\s*(?:de|para|pagador|recebedor|favorecido|origem|destino|'
    r'quem pagou|quem recebeu)\s*$',
    caseSensitive: false,
  );

  /// Até onde o nome pode ir depois do rótulo: três linhas de nome e a do
  /// documento.
  static const _blockReach = 4;

  /// O nome em bloco dos bancos digitais: o rótulo sozinho numa linha ("De"),
  /// o nome quebrado nas de baixo e, depois, o documento. Se o documento é
  /// CPF, as linhas do nome viram um `[NOME]` só; se é CNPJ, é o
  /// estabelecimento, e fica (RN-732).
  static List<String> _maskBlockPeople(List<String> lines) {
    final result = <String>[];
    var index = 0;
    while (index < lines.length) {
      final nameLines = _personBlockAfter(lines, index);
      result.add(lines[index]);
      if (nameLines > 0) result.add('[NOME]');
      index += 1 + nameLines;
    }
    return result;
  }

  /// Quantas linhas de nome de pessoa há logo depois do rótulo em [at]; zero
  /// se ali não há rótulo, ou se o documento que fecha o bloco não é CPF.
  static int _personBlockAfter(List<String> lines, int at) {
    if (!_blockLabel.hasMatch(lines[at])) return 0;
    final after = lines.skip(at + 1).take(_blockReach).toList();
    final document = after.indexWhere(
      (line) => line.contains('[CPF]') || line.contains('[CNPJ]'),
    );
    if (document <= 0 || !after[document].contains('[CPF]')) return 0;
    return document;
  }

  /// Nome ligado a CPF é pessoa, e é mascarado; nome ligado a CNPJ é o
  /// estabelecimento, e fica (RN-732). O vínculo se decide pelas duas linhas
  /// seguintes, onde os comprovantes costumam trazer o documento.
  static List<String> _maskPeople(List<String> lines) => [
    for (final (index, line) in lines.indexed)
      if (_counterparty.firstMatch(line) case final match?
          when _isPerson(lines.skip(index).take(3)))
        '${match.group(1)}[NOME]'
      else
        line,
  ];

  static bool _isPerson(Iterable<String> nearby) {
    final context = nearby.join('\n');
    return context.contains('[CPF]') && !context.contains('[CNPJ]');
  }

  /// Busca simples, sem expressão regular: o nome vem do cadastro, e nenhuma
  /// expressão é montada com texto que não seja literal do código.
  static String _maskName(String text, String name) {
    final needle = name.trim().toLowerCase();
    if (needle.length < 3) return text;
    final buffer = StringBuffer();
    var from = 0;
    final haystack = text.toLowerCase();
    while (true) {
      final at = haystack.indexOf(needle, from);
      if (at < 0) break;
      buffer
        ..write(text.substring(from, at))
        ..write('[NOME]');
      from = at + needle.length;
    }
    return (buffer..write(text.substring(from))).toString();
  }
}
