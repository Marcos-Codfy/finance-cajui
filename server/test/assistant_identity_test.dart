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
    expect(AssistantPrompt.version, 6);
    expect(AssistantPrompt.system, contains('pode gastar por semana'));
    expect(AssistantPrompt.system, contains('faltam R\$ X para fechar'));
    expect(AssistantPrompt.system, contains('mudar_categoria'));
  });
}
