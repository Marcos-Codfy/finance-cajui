import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/assistant/application/local_answer.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_state.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/insights/application/insights.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O ViewModel da conversa com o assistente (ADR-002).
///
/// A conversa da tela vive só aqui, na memória: fechar o app a esquece. É o
/// modo mais conservador da RN-957 — nada de conversa fica guardado no
/// aparelho.
///
/// **A pergunta passa primeiro pelo domínio** (RN-960). Limite da semana,
/// sobra do mês, gasto por categoria, saldo do vale, reserva da fatura e
/// parcela de dívida são contas que o Cajui já faz, exatas e sem internet.
/// Só o que não cabe nelas custa token.
class AssistantViewModel extends Notifier<AssistantState> {
  /// A conversa começa aberta, cadastrado ou não: as contas do próprio
  /// aparelho já respondem boa parte, sem internet. O cadastro só é pedido
  /// quando a pergunta precisa mesmo sair daqui.
  @override
  AssistantState build() => const AssistantTalking();

  /// Pergunta [message]. Enquanto a resposta não chega, a tela espera: uma
  /// segunda pergunta só depois da primeira resposta.
  Future<void> ask(String message) async {
    final current = state;
    final question = message.trim();
    if (current is! AssistantTalking || current.isWaiting) return;
    if (question.isEmpty) return;
    final local = _localAnswerTo(question);
    if (local != null) {
      state = current.answered(question, local);
      return;
    }
    final gateway = ref.read(assistantGatewayProvider);
    // Aparelho não cadastrado: pedir a digital para depois dizer "não te
    // conheço" seria fazer a pessoa trabalhar à toa.
    if (!gateway.isPaired) {
      state = const AssistantUnpaired();
      return;
    }
    state = current.asking(question);
    // O contexto é montado no servidor (RN-915), então o servidor precisa
    // ter o livro. Sobe aqui, na mesma sessão da pergunta: uma digital só,
    // e num momento em que já se está esperando.
    await _pushLedger();
    final reply = await gateway.ask(question);
    state = reply is AssistantNotPaired
        ? const AssistantUnpaired()
        : current.answered(question, reply);
  }

  /// Sobe o livro antes de perguntar. Falha aqui não interrompe a pergunta:
  /// o assistente responde com o que o servidor já tinha, e diz sozinho
  /// quando não tem número — é o comportamento dele de sempre.
  Future<void> _pushLedger() async {
    final book = ref.read(ledgerProvider).value;
    if (book == null) return;
    await LedgerSync(ref.read(ledgerUplinkProvider)).run(book);
  }

  /// A resposta que o aparelho dá sozinho, quando dá. Sem livro aberto ainda,
  /// ninguém responde nada aqui — e a pergunta segue o caminho de sempre.
  AssistantReply? _localAnswerTo(String question) {
    // Na web não existe livro: o que há é um livro **vazio**, e responder
    // por ele diria "R$ 0,00" com cara de verdade. Lá tudo passa pelo
    // servidor, que é quem tem os números (ADR-013).
    if (!ref.read(ledgerUplinkProvider).isPaired) return null;
    final intent = QuestionRouter.of(question);
    if (intent == QuestionIntent.unknown) return null;
    final overview = ref.read(monthOverviewProvider);
    final insights = ref.read(insightsProvider);
    final book = ref.read(ledgerProvider).value;
    if (overview == null || insights == null || book == null) return null;
    return LocalAnswer.of(
      intent,
      question: question,
      insights: insights,
      overview: overview,
      book: book,
    );
  }

  /// Pergunta de novo a última pergunta, depois de uma falha.
  Future<void> retry() async {
    final current = state;
    if (current is! AssistantTalking || current.exchanges.isEmpty) return;
    final (question, _) = current.exchanges.last;
    state = current.withoutLast();
    await ask(question);
  }
}

/// A conversa em curso.
final assistantProvider = NotifierProvider<AssistantViewModel, AssistantState>(
  AssistantViewModel.new,
);
