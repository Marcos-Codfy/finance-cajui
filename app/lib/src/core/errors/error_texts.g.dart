// Gerado por tool/contract/build_error_texts.py a partir de
// docs/spec/error-catalog.md. Não edite à mão: mude o catálogo e gere de novo.
// ignore_for_file: lines_longer_than_80_chars

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_text.dart';

/// O texto e as saídas de cada erro, como estão no catálogo (ADR-015).
///
/// O `switch` é exaustivo: código novo no contrato sem texto aqui não compila.
abstract final class ErrorTexts {
  /// O texto e as saídas de [code].
  static ErrorText of(ErrorCode code) => switch (code) {
    ErrorCode.entry01 => const ErrorText(
      'As formas de pagamento somam {soma}, e a compra é de {valor}. Faltam {diferença} para fechar a conta.',
      actions: ['Ajustar os valores', 'Colocar o resto em {forma}'],
    ),
    ErrorCode.entry02 => const ErrorText(
      'Esta data ainda não chegou. O Cajui registra o que já foi comprado; o que está por vir entra como compromisso no plano do mês.',
      actions: ['Usar a data de hoje', 'Escolher outra data'],
    ),
    ErrorCode.entry03 => const ErrorText(
      'Digite um valor maior que zero. Para registrar um dinheiro que voltou, use "Estorno" no lançamento original.',
    ),
    ErrorCode.entry04 => const ErrorText(
      'Este lançamento tem {restante} para estornar, e o estorno pedido é de {pedido}.',
      actions: ['Estornar {restante}', 'Corrigir o valor'],
    ),
    ErrorCode.voucher01 => const ErrorText(
      'O vale tem {saldo}, e esta compra é de {valor}. Dá para pagar {saldo} no vale e o resto de outro jeito.',
      actions: ['Dividir o pagamento', 'Trocar a forma de pagamento'],
    ),
    ErrorCode.voucher02 => const ErrorText(
      'O vale alimentação só paga alimentação, e "{categoria}" está fora.',
      actions: ['Trocar a forma de pagamento', 'Trocar a categoria'],
    ),
    ErrorCode.card01 => const ErrorText(
      'O dia precisa ficar entre 1 e 31. Se o cartão fecha no último dia do mês, use 31: o Cajui ajusta nos meses mais curtos.',
    ),
    ErrorCode.card02 => const ErrorText(
      '"{nome}" parece um cartão, e no Cajui cartão é forma de pagamento, não despesa. A categoria diz o que foi comprado; o cartão entra em "por onde pagou".',
      actions: ['Cadastrar como cartão', 'Dar outro nome'],
    ),
    ErrorCode.budg01 => const ErrorText(
      'O mínimo ({mínimo}) ficou maior que o máximo ({máximo}). O Cajui planeja o mês pelo máximo, o pior caso.',
      actions: ['Inverter os valores', 'Corrigir'],
    ),
    ErrorCode.budg02 => const ErrorText(
      '{mês} ainda não terminou. Dá para fechar a partir de {data}. Até lá, os números são a projeção do mês.',
      actions: ['Entendi'],
    ),
    ErrorCode.budg03 => const ErrorText(
      '{categoria} tem mínimo de {mínimo}, e o ajuste a deixaria em {resultado}. O mínimo é o que você disse que não dá para cortar.',
      actions: ['Ajustar até {mínimo}', 'Rever a faixa'],
    ),
    ErrorCode.budg04 => const ErrorText(
      '{origem} tem {folga} de folga, e o pedido é mover {pedido}.',
      actions: ['Mover {folga}', 'Escolher outra origem'],
    ),
    ErrorCode.debt01 => const ErrorText(
      'A dívida tem {total} parcelas, e {pagas} aparecem como pagas.',
    ),
    ErrorCode.capt01 => const ErrorText(
      'Não consegui ler este comprovante: a imagem ficou escura ou pequena demais para o texto aparecer. O arquivo está guardado.',
      actions: ['Tirar outra foto', 'Digitar os dados'],
    ),
    ErrorCode.capt02 => const ErrorText(
      'Este arquivo não é uma imagem, um PDF nem um texto. O Cajui lê JPEG, PNG, WebP, PDF e texto.',
      actions: ['Escolher outro'],
    ),
    ErrorCode.capt03 => const ErrorText(
      'Este arquivo tem {tamanho} e o limite é 15 MB. Um print da tela do comprovante resolve.',
      actions: ['Escolher outro'],
    ),
    ErrorCode.capt04 => const ErrorText(
      'Este PDF está protegido por senha, e o Cajui não abre arquivo protegido. Um print da página com o valor resolve.',
      actions: ['Escolher outro', 'Digitar os dados'],
    ),
    ErrorCode.capt05 => const ErrorText(
      'O app de origem não liberou o arquivo. Tente compartilhar de novo, ou salve o comprovante na galeria e compartilhe de lá.',
      actions: ['Entendi'],
    ),
    ErrorCode.capt06 => const ErrorText(
      'Não há espaço no aparelho para guardar o comprovante (faltam cerca de {falta}). Nada foi perdido: ele continua no app de origem.',
      actions: ['Abrir armazenamento', 'Digitar os dados'],
    ),
    ErrorCode.capt07 => const ErrorText(
      'Não consegui ler esta página a tempo. O comprovante está guardado.',
      actions: ['Tentar de novo', 'Digitar o valor'],
    ),
    ErrorCode.net01 => const ErrorText(
      'Sem conexão agora. {recurso} só funciona com internet, porque a resposta vem do servidor. Seus números continuam no painel.',
      actions: ['Tentar de novo'],
    ),
    ErrorCode.net02 => const ErrorText(
      'O servidor não respondeu a tempo. {preservado}.',
      actions: ['Tentar de novo'],
    ),
    ErrorCode.sync01 => const ErrorText(
      'Um lançamento feito sem conexão não pôde ser enviado: {motivo}. Ele continua guardado no aparelho, em "Para conferir".',
      actions: ['Abrir o lançamento'],
    ),
    ErrorCode.sync02 => const ErrorText(
      'Este item mudou em outro lugar enquanto você editava. Nada foi perdido: mostro a versão atual e o que você ia salvar.',
      actions: ['Ver as duas versões', 'Manter a atual'],
    ),
    ErrorCode.ai01 => const ErrorText(
      'Na captura: A classificação automática está fora do ar. Usei as regras locais — confira a categoria antes de lançar. · No assistente: O assistente está fora do ar. Seus números continuam no painel, e lançar funciona normalmente.',
      actions: ['Lançar', 'Conferir depois', 'Perguntar de novo'],
    ),
    ErrorCode.ai02 => const ErrorText(
      'Muitas perguntas em pouco tempo. O serviço de IA pediu uma pausa; dá para perguntar de novo em {segundos} segundos.',
    ),
    ErrorCode.ai03 => const ErrorText(
      'O uso da IA chegou ao teto de {mês}. A classificação segue pelas regras locais, e a conversa volta no dia 1º.',
      actions: ['Rever o teto', 'Ver o consumo'],
    ),
    ErrorCode.ai04 => const ErrorText(
      'A classificação automática devolveu algo que não deu para aproveitar. Usei as regras locais — confira a categoria antes de lançar.',
      actions: ['Lançar', 'Conferir depois'],
    ),
    ErrorCode.auth01 => const ErrorText(
      'Este aparelho não tem biometria configurada. O Cajui usa a biometria do Android para proteger seus dados.',
      actions: ['Abrir as configurações do Android'],
    ),
    ErrorCode.auth02 => const ErrorText(
      'Não reconheci.',
      actions: ['Tentar de novo'],
    ),
    ErrorCode.auth03 => const ErrorText(
      'Não foi possível confirmar este aparelho. Seus dados continuam protegidos no servidor.',
      actions: ['Entrar de novo'],
    ),
    ErrorCode.auth04 => const ErrorText(
      'Este código não serve mais. Gere outro no app do celular, em Ajustes › Computador.',
      actions: ['Digitar outro código'],
    ),
    ErrorCode.rate01 => const ErrorText(
      'Foram muitos pedidos em pouco tempo. Nada se perdeu. Dá para tentar de novo em {segundos} segundos.',
    ),
    ErrorCode.data01 => const ErrorText(
      'O registro dos seus dados tem um trecho que não confere, a partir do evento {número}. Parei de gravar para não piorar; ler continua funcionando. O último backup íntegro é de {data}.',
      actions: ['Ver o roteiro de restauração'],
    ),
    ErrorCode.data02 => const ErrorText(
      'Os totais guardados não batem com o histórico. Vou refazer os totais a partir do histórico, que é a fonte da verdade; leva cerca de {tempo}.',
      actions: ['Refazer agora'],
    ),
    ErrorCode.storage01 => const ErrorText(
      'O aparelho está sem espaço, e não deu para guardar {item}. O que já estava salvo continua salvo.',
      actions: ['Abrir armazenamento'],
    ),
    ErrorCode.req01 => const ErrorText(
      'O app enviou um pedido que o servidor não entendeu. É uma falha do app, não sua; o que você preencheu continua na tela.',
      actions: ['Tentar de novo', 'Copiar o código'],
    ),
    ErrorCode.req02 => const ErrorText(
      'Este item não existe mais — pode ter sido apagado em outro aparelho.',
      actions: ['Voltar para a lista'],
    ),
    ErrorCode.req03 => const ErrorText(
      'Esta versão do app ficou antiga para falar com o servidor. Seus lançamentos pendentes continuam guardados. Instale a versão {versão} para enviar.',
      actions: ['Ver como atualizar'],
    ),
    ErrorCode.req04 => const ErrorText(
      'Este comprovante tem texto demais para analisar de uma vez. Usei as regras locais — confira a categoria antes de lançar.',
      actions: ['Lançar', 'Conferir depois'],
    ),
    ErrorCode.srv01 => const ErrorText(
      'O servidor falhou ao {ação}. Seus dados estão guardados; foi só esta consulta que não voltou.',
      actions: ['Tentar de novo'],
    ),
    ErrorCode.srv02 => const ErrorText(
      'O servidor está reiniciando. Costuma levar menos de um minuto; o que você lançar agora fica na fila.',
      actions: ['Tentar de novo'],
    ),
    ErrorCode.srv03 => const ErrorText(
      'O último backup foi há {tempo}. Seus dados seguem no servidor, sem cópia recente fora dele.',
      actions: ['Ver o que aconteceu'],
    ),
    ErrorCode.web01 => const ErrorText(
      'Não consegui abrir o painel. O carregamento parou no meio.',
      actions: ['Tentar de novo'],
    ),
    ErrorCode.app01 => const ErrorText(
      'O Cajui encontrou uma falha que ainda não tem nome. O que estava salvo continua salvo{fila}.',
      actions: ['Reabrir o app', 'Copiar o código'],
    ),
  };
}
