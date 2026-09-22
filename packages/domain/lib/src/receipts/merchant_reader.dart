import 'package:domain/src/receipts/merchant_kind.dart';

/// Quem é o estabelecimento do comprovante, e de que ramo ele é.
///
/// Saiu do leitor de campos quando o cupom fiscal entrou na conta: achar
/// o nome da loja no meio de cabeçalho, CNPJ, endereço e sessenta itens é um
/// problema por si, com regras que valor e data não precisam conhecer.
abstract final class MerchantReader {
  static final _merchantLabel = RegExp(
    r'^\s*(?:destinat[aá]rio|favorecido|recebedor|benefici[aá]rio|'
    r'estabelecimento|raz[aã]o social)\s*:\s*([^\n]{2,80})$',
    caseSensitive: false,
    multiLine: true,
  );

  /// O estabelecimento: o que vem depois de "Destinatário:" e afins; sem
  /// rótulo, o bloco do recebedor, o cabeçalho do cupom fiscal e, por último,
  /// a primeira linha com cara de nome.
  static String? nameIn(String text) {
    final labelled = _merchantLabel.firstMatch(text);
    if (labelled != null) return labelled.group(1)!.trim();
    final lines = [for (final line in text.split('\n')) line.trim()];
    return _merchantBlock(lines) ??
        _storeInHeader(lines) ??
        lines.where(_looksLikeName).firstOrNull;
  }

  /// O nome da loja no cabeçalho de um cupom fiscal.
  ///
  /// O cupom começa sempre com razão social, CNPJ e endereço, nessa ordem. É
  /// por isso que o nome sai da linha do CNPJ — quando vêm juntos — ou da
  /// linha de cima: pegar "a primeira linha com letras" trazia o endereço.
  static String? _storeInHeader(List<String> lines) {
    final header = lines.take(_headerLines).toList();
    final at = header.indexWhere(_documentLine.hasMatch);
    if (at < 0) return null;
    final beside = _nameBeside(header[at]);
    if (beside != null) return beside;
    for (var index = at - 1; index >= 0; index--) {
      if (_looksLikeName(header[index])) return header[index];
    }
    return null;
  }

  /// Quantas linhas do começo contam como cabeçalho.
  static const _headerLines = 6;

  /// O que sobra de uma linha depois de tirar o documento e o rótulo dele:
  /// "WNS SUPERMERCADOS LTDA CNPJ: 00.000.000/0001-00" devolve o nome.
  static String? _nameBeside(String line) {
    final rest = line
        .replaceAll(_documentLine, '')
        .replaceAll(RegExp(r'\b(?:cnpj|cpf)\b\s*:?', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-/., 0-9]+$'), '')
        .trim();
    return _looksLikeName(rest) ? rest : null;
  }

  /// Linha com cara de nome de estabelecimento: tem letras o bastante e não é
  /// cabeçalho, rótulo nem endereço.
  static bool _looksLikeName(String line) {
    final letters = line.replaceAll(RegExp('[^A-Za-zÀ-ú]'), '').length;
    return letters >= 4 && !_isNotAName(line) && !_address.hasMatch(line);
  }

  /// Endereço: começa com logradouro ou traz número de porta entre vírgulas.
  /// Num cupom, o endereço vem logo abaixo do nome e tem tantas letras quanto
  /// ele — só a forma separa os dois.
  static final _address = RegExp(
    '^(?:av|avenida|r|rua|rod|rodovia|tv|travessa|al|alameda|pra[cç]a|'
    r'qd|quadra|conj|conjunto|lote|setor|bairro|cep|acsu|sq[ns]|shc?[ns])\b|'
    r'\d{2,},\s*\w|\bcep\b',
    caseSensitive: false,
  );

  /// O ramo do estabelecimento [name], pelas palavras do nome. É o que
  /// permite propor a categoria de um cupom de mercado sem a IA e sem ninguém
  /// ter ensinado nada antes.
  static MerchantKind? kindIn(String? name) {
    if (name == null) return null;
    final lower = name.toLowerCase();
    for (final MapEntry(key: kind, value: words) in _kindByWord.entries) {
      if (words.any(lower.contains)) return kind;
    }
    return null;
  }

  static const Map<MerchantKind, List<String>> _kindByWord = {
    // Açougue antes de mercado: "mercado de carnes" é açougue.
    MerchantKind.butcher: ['acougue', 'açougue', 'carnes', 'frigorif'],
    MerchantKind.bakery: ['padaria', 'panific', 'confeitaria'],
    MerchantKind.pharmacy: ['farmacia', 'farmácia', 'drogaria', 'drogas'],
    MerchantKind.fuel: ['posto', 'combustiv', 'combustív', 'petroleo'],
    MerchantKind.dining: [
      'restaurante',
      'lanchonete',
      'pizzaria',
      'churrascaria',
      'hamburgu',
      'cafeteria',
      'sorveteria',
      'acai',
      'açaí',
      'bar e',
      'espetinho',
    ],
    MerchantKind.produce: ['hortifrut', 'sacolao', 'sacolão', 'quitanda'],
    MerchantKind.streetMarket: ['feira livre', 'feira do', 'feirinha'],
    MerchantKind.supermarket: [
      'supermercado',
      'hipermercado',
      'atacad',
      'mercearia',
      'mercado',
      'minimercado',
      'compre bem',
    ],
  };

  /// O recebedor em bloco, como os bancos digitais escrevem: "Para" sozinho
  /// numa linha, o nome quebrado nas linhas de baixo e, depois, o documento.
  static String? _merchantBlock(List<String> lines) {
    final at = lines.indexWhere(_blockLabel.hasMatch);
    if (at < 0) return null;
    final name = lines
        .skip(at + 1)
        .take(_maxNameLines)
        .takeWhile((line) => !_documentLine.hasMatch(line) && line.isNotEmpty)
        .join(' ');
    return name.length < 2 ? null : name;
  }

  static const _maxNameLines = 3;
  static final _blockLabel = RegExp(
    r'^(?:para|destino|recebedor|favorecido|destinat[aá]rio|quem recebeu)$',
    caseSensitive: false,
  );

  /// Linha que traz documento — CNPJ, CPF inteiro ou mascarado, ou o marcador
  /// que o mascaramento deixou no lugar. É onde o nome acaba.
  static final _documentLine = RegExp(
    r'\d{2}\.?\d{3}\.?\d{3}/\d{4}|\d{3}\.\d{3}\.\d{3}|\*{3}\.\d{3}|\[CNPJ\]|\[CPF\]',
  );

  /// Cabeçalho, rótulo solto ou linha com dois-pontos: tem letras, mas não é
  /// nome de estabelecimento. Dois-pontos sem nada depois é rótulo; com algo
  /// depois, já foi tratado por [_nameBeside].
  static bool _isNotAName(String line) =>
      line.contains(':') || _headerOrLabel.hasMatch(line);

  static final _headerOrLabel = RegExp(
    '^(?:comprovante|recibo|cupom|pix|nota)|'
    '^(?:valor(?: original| pago| total)?|de|para|data|origem|destino|'
    r'identificador|id da transa[cç][aã]o|detalhes da cobran[cç]a)$',
    caseSensitive: false,
  );
}
