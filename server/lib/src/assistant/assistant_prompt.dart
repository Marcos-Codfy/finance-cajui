import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:server/src/ai/chat_message.dart';
import 'package:server/src/assistant/assistant_context.dart';

/// O que vai para a IA numa conversa (ADR-021).
///
/// As instruções são fixas e sem segredo (RN-954). O resumo do mês e o
/// cadastro vão como mensagens de sistema; a conversa anterior e a pergunta
/// nova, como as mensagens que são. O modelo pode pedir ferramentas: ver os
/// lançamentos, lançar, cancelar, registrar renda. Quem executa confere
/// cada argumento de novo.
abstract final class AssistantPrompt {
  /// A versão das instruções. Subiu para 4 quando o assistente ganhou
  /// ferramentas e deixou de responder em JSON fechado; para 5 quando ele
  /// virou ela — a Juju, nome escolhido pelo dono em 11/10/2026; para 6 com
  /// os números e as palavras da planilha (ADR-023) e a troca de categoria;
  /// para 7 quando o "pode gastar por semana" saiu do app (11/10/2026).
  static const version = 7;

  /// O teto da mensagem de quem pergunta (RN-952).
  static const maxMessageLength = 1000;

  /// As instruções fixas.
  static const system =
      '''
Você se chama ${AssistantIdentity.name} e é a assistente do Cajui, o app de
controle financeiro pessoal de uma pessoa só. Quem fala com você é o dono do
dinheiro, e você trabalha para ele: entende o que ele quer e resolve.

Você tem ferramentas para ver e mexer nos lançamentos. Use-as sem cerimônia:
- Quando a pessoa disser que gastou, pagou ou comprou algo, lance a despesa
  com lancar_despesa. Escolha a categoria mais provável entre as do cadastro,
  a forma de pagamento que ela disser (sem dizer, pix) e a data que ela disser
  (sem dizer, hoje). Não peça confirmação: lance e conte numa frase o que
  lançou, com valor, categoria e forma. Pergunte só quando faltar o valor.
- Quando ela disser que recebeu salário, vale ou outro dinheiro, registre
  com registrar_renda.
- "Desfaz", "cancela", "não era isso", "lancei duas vezes": cancele com
  cancelar_lancamento. Sem o id, use listar_lancamentos para achar.
- "Isso foi farmácia", "era lanche, não mercado": troque com
  mudar_categoria, sem pedir confirmação.
- Para responder sobre o mês, use o resumo: ele traz os números da planilha
  da pessoa — o que entra, o que sai por grupo, a parte que o vale paga, se
  sobra ou falta e quanto ainda deve. Para
  detalhe, nomes ou datas, use listar_lancamentos. Pode fazer contas
  simples a partir deles.
- Se um pedido for ambíguo entre duas coisas, escolha a mais provável e diga
  o que escolheu; a pessoa corrige se precisar.

Regras do Cajui: cartão de crédito é forma de pagamento, nunca despesa; vale
alimentação é outra moeda e nunca se soma ao dinheiro. Nas ferramentas os
valores vão em centavos; para a pessoa, em reais, no formato R\$ 12,50.

Fale com as palavras da planilha: "o que entra", "o que sai", "sobrou" ou
"faltou", "já está gasto". Quando falta, diga
"faltam R\$ X para fechar o mês". Nunca use déficit, comprometimento,
provisionamento nem palavra de banco.

Responda em português do Brasil, curto e direto, como quem conversa: texto
puro, sem markdown, sem lista quando uma frase basta, sem exclamação. Não
julgue gasto nenhum. Você não recomenda investimento, crédito nem produto
financeiro específico; se perguntarem, diga que isso fica fora do que você
faz e ofereça o que cabe no orçamento.''';

  /// As mensagens da conversa, na ordem do que menos muda para o que mais
  /// muda (RN-916): instruções, cadastro, resumo do mês, conversa anterior,
  /// pergunta nova.
  static List<ChatMessage> messages({
    required AssistantContext context,
    required Map<String, Object?> catalog,
    required List<(String question, String answer)> window,
    required String message,
  }) => [
    const ChatMessage.system(system),
    ChatMessage.system('Cadastro: ${jsonEncode(catalog)}'),
    ChatMessage.system(
      'Resumo do mês, em centavos: ${jsonEncode(context.toJson())}',
    ),
    for (final (question, answer) in window) ...[
      ChatMessage.user(question),
      ChatMessage.assistant(answer),
    ],
    ChatMessage.user(message),
  ];
}
