import 'package:domain/src/receipts/merchant_reader.dart';

/// O nome de quem recebeu ou mandou um Pix ou uma transferência, numa linha
/// de extrato (RN-1106).
///
/// O extrato escreve "PIX ENVIADO JOAO P SILVA 150,00" sem rótulo e sem
/// CPF, e a máscara da RN-732 não pegava esse nome. É daqui que ela o tira
/// antes da IA, e é daqui que o celular o recupera para a pergunta e para a
/// memória (RN-1116): "Pix para João P Silva" é uma pessoa só, mês após
/// mês. As palavras são literais (RN-733).
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
  /// empresa ("PIX ENVIADO MERCADO BOA VISTA LTDA" é uma compra).
  static String? personIn(String line) {
    final plain = _plain(line);
    for (final marker in markers) {
      final at = _wordAt(plain, marker);
      if (at < 0) continue;
      final start = _skipConnectors(plain, at + marker.length);
      final end = _nameEnd(plain, start);
      final name = line.substring(start, end).trim();
      return _isPerson(name) ? name : null;
    }
    return null;
  }

  /// Se [name] tem cara de nome de gente, pela mesma conferência de
  /// [personIn]. Serve a quem só guardou o nome, sem a linha em volta: a
  /// regra antiga do comprovante (RN-763) não dizia se era Pix para alguém,
  /// e mesmo assim não pode virar exemplo para a IA (RN-1107).
  static bool isPersonName(String name) => _isPerson(name);

  /// Onde [word] aparece como palavra inteira em [text], ou -1.
  static int _wordAt(String text, String word) {
    var at = text.indexOf(word);
    while (at >= 0) {
      final before = at == 0 || text[at - 1] == ' ';
      final end = at + word.length;
      final after = end == text.length || text[end] == ' ';
      if (before && after) return at;
      at = text.indexOf(word, at + 1);
    }
    return -1;
  }

  /// Pula espaço, "PARA", "DE", "P/" e pontuação entre o marcador e o nome.
  static int _skipConnectors(String text, int from) {
    var at = from;
    while (true) {
      while (at < text.length && ' -:/'.contains(text[at])) {
        at++;
      }
      final next = _connectors.where((word) => text.startsWith('$word ', at));
      if (next.isEmpty) return at;
      at += next.first.length;
    }
  }

  static const _connectors = ['PARA', 'P/', 'DE', 'DA', 'DO'];

  /// O nome vai até o primeiro número, "R$", colchete ou documento: o que
  /// vem depois é valor, data, agência ou CPF.
  static int _nameEnd(String text, int from) {
    final words = text.substring(from).split(' ');
    var end = from;
    for (final word in words) {
      if (word.isNotEmpty && _endsName(word)) break;
      end += word.length + 1;
    }
    return end.clamp(from, text.length);
  }

  static bool _endsName(String word) =>
      RegExp('[0-9]').hasMatch(word) ||
      word.startsWith(r'R$') ||
      word.startsWith('[') ||
      _documents.contains(word);

  static const _documents = {'CPF', 'CNPJ', 'AG', 'AGENCIA', 'CONTA', 'CC'};

  /// Nome e sobrenome, só letras, e sem cara de empresa.
  static bool _isPerson(String name) {
    final words = _plain(name).split(' ').where((w) => w.isNotEmpty);
    if (words.length < 2) return false;
    if (words.any(_companyWords.contains)) return false;
    return MerchantReader.kindIn(name) == null;
  }

  static const _companyWords = {
    'LTDA',
    'ME',
    'EPP',
    'EIRELI',
    'SA',
    'S/A',
    'MEI',
    'COMERCIO',
    'SERVICOS',
    'INDUSTRIA',
    'LOJA',
    'LOJAS',
  };

  /// Maiúsculas sem acento, com o mesmo comprimento de [text]: as posições
  /// achadas aqui valem no texto original.
  static String _plain(String text) =>
      text.toUpperCase().split('').map((char) => _accents[char] ?? char).join();

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
