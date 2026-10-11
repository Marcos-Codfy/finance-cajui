import 'package:server/src/assistant/assistant_prompt.dart';
import 'package:test/test.dart';

void main() {
  test('a assistente se chama Juju nas instruções da IA, e a versão das '
      'instruções subiu com o nome', () {
    expect(
      AssistantPrompt.system,
      startsWith('Você se chama Juju e é a assistente do Cajui'),
    );
    expect(AssistantPrompt.version, 5);
  });
}
