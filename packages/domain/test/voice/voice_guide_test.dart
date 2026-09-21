import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RN-944 · termos que o guia de voz reprova', () {
    test('acha o termo em qualquer caixa e diz qual foi', () {
      expect(VoiceGuide.violations('Você ESTOUROU o limite. Infelizmente.'), [
        'estourou',
        'infelizmente',
      ]);
    });

    test('o jeito da casa de dar má notícia passa', () {
      const calm =
          r'Faltam R$ 180 para fechar setembro. Separei três ajustes que '
          'cobrem isso.';

      expect(VoiceGuide.violations(calm), isEmpty);
    });

    test('erro que não diz o quê também é reprovado', () {
      expect(VoiceGuide.violations('Ops! Algo deu errado.'), [
        'algo deu errado',
        'ops!',
      ]);
    });
  });
}
