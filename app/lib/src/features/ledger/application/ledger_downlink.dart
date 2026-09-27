import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que o servidor tem, pronto para descer: os fatos já na forma em que o
/// aparelho os grava, e os lançamentos que **algum aparelho cancelou**.
///
/// A segunda parte é o que faz dois celulares concordarem sobre o que não
/// existe mais: sem ela, o cancelamento feito num aparelho seria desfeito
/// pelo outro na próxima subida.
typedef LedgerSnapshot = ({List<LedgerEvent> events, Set<String> cancelled});

/// O caminho de descida do livro: o que o servidor tem chegando ao aparelho
/// (BL-062).
///
/// É a outra metade da subida. Com só a subida, cada celular era uma ilha
/// que mandava para o servidor e nunca ouvia de volta — lançar num aparelho
/// não aparecia no outro, e se os dois lançassem, cada um ficava com a sua
/// metade enquanto o servidor tinha a soma.
abstract interface class LedgerDownlink {
  /// O que o servidor tem agora; `null` quando não deu para ler — sem
  /// sessão, sem rede, servidor fora do ar. Nulo é diferente de vazio: um
  /// servidor que não respondeu não é um servidor sem lançamentos, e tratar
  /// um como o outro cancelaria tudo por aqui.
  Future<LedgerSnapshot?> snapshot();
}

/// Por onde o livro desce. A raiz do app decide qual.
final ledgerDownlinkProvider = Provider<LedgerDownlink>(
  (ref) => throw StateError('ledgerDownlinkProvider sem override na raiz.'),
);
