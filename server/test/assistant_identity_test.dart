import 'package:server/src/assistant/assistant_prompt.dart';
import 'package:test/test.dart';

void main() {
  test('a assistente se chama Juju nas instruções da IA, e a versão das '
      'instruções subiu com o nome', () {
    expect(
      AssistantPrompt.system,
      startsWith('Você se chama Juju e é a assistente do Cajui'),
    );
    expect(AssistantPrompt.version, greaterThanOrEqualTo(5));
  });

  test('ADR-023 · as instruções falam com as palavras da planilha e proíbem '
      'as de banco', () {
    expect(AssistantPrompt.version, 8);
    // O "pode gastar por semana" saiu do app em 11/10/2026: a Juju não fala
    // de um número que nenhuma tela mostra.
    expect(AssistantPrompt.system, isNot(contains('por semana')));
    expect(AssistantPrompt.system, contains(r'faltam R$ X para fechar'));
    expect(AssistantPrompt.system, contains('mudar_categoria'));
    // 22/10/2026: o valor vem já escrito em "reais", e a Juju não faz conta.
    expect(AssistantPrompt.system, contains('Nunca converta centavos'));
  });
}
