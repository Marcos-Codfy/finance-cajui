import 'package:domain/src/receipts/merchant_reader.dart';
import 'package:domain/src/receipts/receipt_field_reader.dart';
import 'package:domain/src/statements/transfer_words.dart';

/// O que vem depois do marcador numa linha: o nome, como está escrito, e se
/// a linha acabou sem nome nenhum — só valor, ou nada.
typedef _AfterMarker = ({String name, bool bare});

/// O nome de quem recebeu ou mandou um Pix ou uma transferência, numa linha
/// de extrato (RN-1106).
///
/// O extrato escreve "PIX ENVIADO JOAO P SILVA 150,00" sem rótulo e sem
/// CPF, e a máscara da RN-732 não pegava esse nome. É daqui que ela o tira
/// antes da IA, e é daqui que o celular o recupera para a pergunta e para a
/// memória (RN-1116): "Pix para João P Silva" é uma pessoa só, mês após
/// mês. Cada banco escreve de um jeito — "Pix enviado: "Cp :60746948-NOME"",
/// "TED 237 0001 NOME", o nome na linha de baixo —, e por isso o que fica
/// entre o marcador e o nome é pulado, em vez de encerrar a busca. As
/// palavras são literais (RN-733), e a varredura é uma passada só.
abstract final class TransferLine {
  /// O que abre uma linha de transferência, sem acento e em maiúsculas. A
  /// mais longa vem antes: "PIX ENVIADO" ganha de "PIX".
  static const markers = [
    'TRANSFERENCIA ENVIADA',
    'TRANSFERENCIA RECEBIDA',
    'TRANSF ENVIADA',
    'TRANSF RECEBIDA',
    'PIX ENVIADO',
    'PIX RECEBIDO',
    'PIX TRANSF',
    'TRANSFERENCIA',
    'TRANSF',
    'PIX',
    'TED',
    'DOC',
  ];

  /// O nome depois do marcador, exatamente como está em [line], ou `null`
  /// quando a linha não é transferência, não traz nome, ou o nome é de
  /// empresa ("PIX ENVIADO MERCADO BOA VISTA LTDA" é uma compra). O nome
  /// que mora na linha de baixo só [peopleIn] acha.
  static String? personIn(String line) {
    final name = _afterMarker(line)?.name;
    return name != null && _isPerson(name) ? name : null;
  }

  /// Os nomes de pessoa de uma página, linha por linha: o índice da linha
  /// em [lines] → o nome como está escrito nela. Além do nome na própria
  /// linha, acha o que o banco põe na linha de baixo ("Transferência
  /// enviada pelo Pix" e, embaixo, "FULANO DE TAL - •••.123.456-••"): a
  /// linha de baixo sem valor, com cara de nome até o primeiro hífen ou
  /// número. O índice é o da linha onde o nome está — é ela que a máscara
  /// troca, sem mudar o número de linhas.
  static Map<int, String> peopleIn(List<String> lines) {
    final people = <int, String>{};
    for (final (index, line) in lines.indexed) {
      final found = _afterMarker(line);
      if (found == null) continue;
      if (_isPerson(found.name)) {
        people[index] = found.name;
      } else if (found.bare && isTransfer(line)) {
        final below = index + 1 < lines.length ? lines[index + 1] : '';
        if (_nameAlone(below) case final name?) people[index + 1] = name;
      }
    }
    return people;
  }

  /// Se [line] é um Pix, TED, DOC ou transferência para alguém ou de
  /// alguém — inclusive para uma empresa: quem diz se foi compra é a
  /// pessoa. Não é quando a linha diz que foi compra, conta ou coisa do
  /// banco: "PIX QR CODE", "PAGAMENTO PIX", "PIX SAQUE", "TED DEVOLVIDA".
  static bool isTransfer(String line) {
    final plain = _plain(line);
    if (_markerEnd(plain) < 0) return false;
    return !plain.split(_notWord).any(TransferWords.purchase.contains);
  }

  static final _notWord = RegExp('[^A-Z0-9]+');

  /// Se [name] tem cara de nome de gente, pela mesma conferência de
  /// [personIn]. Serve a quem só guardou o nome, sem a linha em volta: a
  /// regra antiga do comprovante (RN-763) não dizia se era Pix para alguém,
  /// e mesmo assim não pode virar exemplo para a IA (RN-1107).
  static bool isPersonName(String name) => _isPerson(name);

  static _AfterMarker? _afterMarker(String line) {
    final plain = _plain(line);
    final marker = _markerEnd(plain);
    if (marker < 0) return null;
    final start = _nameStart(plain, marker);
    final name = line.substring(start, _nameEnd(plain, start)).trim();
    return (name: name, bare: _isBare(plain, start));
  }

  /// O nome sozinho na linha [line], que não tem valor: o que vem antes do
  /// primeiro hífen, número ou documento, se tem cara de gente.
  static String? _nameAlone(String line) {
    if (ReceiptFieldReader.amountsIn(line).isNotEmpty) return null;
    final plain = _plain(line);
    final start = _nameStart(plain, 0);
    final name = line.substring(start, _nameEnd(plain, start)).trim();
    return _isPerson(name) ? name : null;
  }

  /// Onde acaba o marcador que aparece primeiro em [plain], ou -1. Vale a
  /// posição, e não a ordem da lista: em "PIX JOAO SILVA TRANSFERENCIA", o
  /// nome vem depois do "PIX". No empate, a lista põe o mais longo antes.
  static int _markerEnd(String plain) {
    var (first, end) = (-1, -1);
    for (final marker in markers) {
      final at = _wordAt(plain, marker);
      if (at < 0 || (first >= 0 && at >= first)) continue;
      (first, end) = (at, at + marker.length);
    }
    return end;
  }

  /// Onde [word] aparece como palavra inteira em [text], ou -1. Pontuação
  /// em volta não atrapalha ("Pix enviado:"); letra, sim ("PIXAR").
  static int _wordAt(String text, String word) {
    var at = text.indexOf(word);
    while (at >= 0) {
      final end = at + word.length;
      final before = at == 0 || !_isLetter(text[at - 1]);
      final after = end == text.length || !_isLetter(text[end]);
      if (before && after) return at;
      at = text.indexOf(word, at + 1);
    }
    return -1;
  }

  /// Onde o nome começa: depois da pontuação, das palavras do banco e dos
  /// números que não são valor — data, hora, código da instituição ou
  /// agência. Para no valor e no marcador já posto (`[NOME]`), onde não há
  /// nome nenhum.
  static int _nameStart(String plain, int from) {
    var at = from;
    while (at < plain.length && plain[at] != '[') {
      final char = plain[at];
      if (_isDigit(char)) {
        final end = _numberEnd(plain, at);
        if (end < 0) return at;
        at = end;
      } else if (_isLetter(char)) {
        final end = _letterRunEnd(plain, at);
        if (!TransferWords.skipped.contains(plain.substring(at, end))) {
          return at;
        }
        at = end;
      } else {
        at++;
      }
    }
    return at;
  }

  /// Onde acaba o número que começa em [from]: "05/10", "14:32",
  /// "60746948-", "237". -1 quando ele é um valor ("1.200,00").
  static int _numberEnd(String plain, int from) {
    var at = from;
    while (at < plain.length && _inNumber(plain[at])) {
      at++;
    }
    final cents = at + 1 < plain.length && _isDigit(plain[at + 1]);
    return at < plain.length && plain[at] == ',' && cents ? -1 : at;
  }

  static bool _inNumber(String char) => _isDigit(char) || '-./:'.contains(char);

  /// Se a busca parou sem nome: no fim da linha, no valor ou no "R$".
  static bool _isBare(String plain, int start) =>
      start >= plain.length ||
      _isDigit(plain[start]) ||
      plain.startsWith(r'R$', start);

  /// O nome vai até o primeiro número, "R$", colchete, aspas, pontuação
  /// solta, documento ou palavra do banco: o que vem depois é valor, data,
  /// agência ou CPF.
  static int _nameEnd(String plain, int from) {
    var end = from;
    var at = from;
    while (at < plain.length && !plain.startsWith(r'R$', at)) {
      final word = _nameWordEnd(plain, at);
      if (word == at || _closesName(plain.substring(at, word))) break;
      end = word;
      // Pontuação colada ("TAL\"", "SILVA,") fecha o nome.
      if (word < plain.length && plain[word] != ' ') break;
      at = word;
      while (at < plain.length && plain[at] == ' ') {
        at++;
      }
    }
    return end;
  }

  static bool _closesName(String word) {
    final bare = word.endsWith('.') ? word.substring(0, word.length - 1) : word;
    return TransferWords.documents.contains(bare) ||
        TransferWords.bank.contains(bare);
  }

  /// Onde acaba a palavra de nome em [from]: letras, o ponto da abreviação
  /// ("P.") e o hífen ou apóstrofo entre letras ("D'AVILA").
  static int _nameWordEnd(String text, int from) {
    var at = from;
    while (at < text.length && _inName(text, at)) {
      at++;
    }
    return at;
  }

  static bool _inName(String text, int at) {
    final char = text[at];
    if (_isLetter(char)) return true;
    if (at == 0 || !_isLetter(text[at - 1])) return false;
    if (char == '.') return true;
    final next = at + 1 < text.length && _isLetter(text[at + 1]);
    return next && (char == '-' || char == "'");
  }

  static int _letterRunEnd(String text, int from) {
    var at = from;
    while (at < text.length && _isLetter(text[at])) {
      at++;
    }
    return at;
  }

  /// Nome e sobrenome, e sem cara de empresa nem palavra do banco.
  static bool _isPerson(String name) {
    final words = _plain(name).split(' ').where((w) => w.isNotEmpty);
    if (words.length < 2) return false;
    if (words.any(TransferWords.company.contains)) return false;
    if (words.any(TransferWords.bank.contains)) return false;
    return MerchantReader.kindIn(name) == null;
  }

  /// Maiúsculas sem acento, com o mesmo comprimento de [text]: as posições
  /// achadas aqui valem no texto original. Uma letra por vez, porque a
  /// maiúscula de algumas tem duas ('ß' vira "SS" no navegador); essas
  /// ficam como estão — trocá-las deslocaria tudo depois delas.
  static String _plain(String text) => text.split('').map(_plainChar).join();

  static String _plainChar(String char) {
    final upper = char.toUpperCase();
    if (upper.length != 1) return char;
    return TransferWords.accents[upper] ?? upper;
  }

  /// Letra de qualquer alfabeto, com ou sem acento — 'ß' e 'Ñ' inclusive.
  /// Comparar maiúscula com minúscula não serve: no celular, a maiúscula
  /// de 'ß' é ela mesma; no navegador, é "SS".
  static bool _isLetter(String char) => _letter.hasMatch(char);

  static final _letter = RegExp(r'\p{L}', unicode: true);

  static bool _isDigit(String char) => '0123456789'.contains(char);
}
