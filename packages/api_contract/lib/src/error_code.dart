// Gerado por tool/contract/build_error_codes.py a partir de
// docs/spec/error-catalog.md. Não edite à mão: mude o catálogo e gere de novo.

import 'package:api_contract/src/error_class.dart';

/// Os códigos de erro do Cajui: um valor por linha do catálogo.
///
/// App e servidor compartilham este enum, então código que não está no
/// catálogo **não existe**. O texto de cada erro não mora aqui nem na API: o
/// app monta a frase a partir do código e dos valores (ADR-015).
enum ErrorCode {
  /// A soma das linhas de pagamento difere do valor do lançamento.
  entry01('E-ENTRY-01', ErrorClass.rule, 422),

  /// Data da compra no futuro.
  entry02('E-ENTRY-02', ErrorClass.validation, 422),

  /// Valor zero ou negativo.
  entry03('E-ENTRY-03', ErrorClass.validation, 422),

  /// Estorno maior que o que resta do lançamento.
  entry04('E-ENTRY-04', ErrorClass.rule, 422),

  /// Pagamento no vale maior que o saldo.
  voucher01('E-VOUCHER-01', ErrorClass.rule, 422),

  /// Categoria não elegível ao vale.
  voucher02('E-VOUCHER-02', ErrorClass.rule, 422),

  /// Dia de fechamento ou de vencimento fora de 1 a 31.
  card01('E-CARD-01', ErrorClass.validation, 422),

  /// Tentativa de criar categoria que representa cartão ou fatura.
  card02('E-CARD-02', ErrorClass.rule, 422),

  /// Faixa com mínimo maior que o máximo.
  budg01('E-BUDG-01', ErrorClass.validation, 422),

  /// Fechar um mês que ainda não terminou.
  budg02('E-BUDG-02', ErrorClass.rule, 422),

  /// Ajuste abaixo do mínimo da faixa.
  budg03('E-BUDG-03', ErrorClass.rule, 422),

  /// Remanejamento maior que a folga da origem.
  budg04('E-BUDG-04', ErrorClass.rule, 422),

  /// Parcelas pagas maior que o total de parcelas.
  debt01('E-DEBT-01', ErrorClass.validation, 422),

  /// A leitura não achou texto.
  capt01('E-CAPT-01', ErrorClass.capture, null),

  /// Tipo de arquivo que o app não lê.
  capt02('E-CAPT-02', ErrorClass.capture, null),

  /// Arquivo acima de 15 MB.
  capt03('E-CAPT-03', ErrorClass.capture, null),

  /// PDF protegido por senha.
  capt04('E-CAPT-04', ErrorClass.capture, null),

  /// O app de origem não liberou a leitura.
  capt05('E-CAPT-05', ErrorClass.capture, null),

  /// Sem espaço para guardar o arquivo.
  capt06('E-CAPT-06', ErrorClass.capture, null),

  /// Uma página passou de 10 s na leitura (RNF-PERF-06).
  capt07('E-CAPT-07', ErrorClass.capture, null),

  /// Sem conexão numa ação que só existe com rede (assistente, web).
  net01('E-NET-01', ErrorClass.network, null),

  /// O servidor não respondeu em 10 s.
  net02('E-NET-02', ErrorClass.network, null),

  /// Um comando da fila offline foi rejeitado pelo servidor.
  sync01('E-SYNC-01', ErrorClass.sync, 422),

  /// Conflito de escrita: outro comando gravou primeiro.
  sync02('E-SYNC-02', ErrorClass.sync, 409),

  /// A IA não respondeu em 20 s, ou está fora do ar.
  ai01('E-AI-01', ErrorClass.ai, 503),

  /// O serviço de IA limitou as requisições.
  ai02('E-AI-02', ErrorClass.ai, 429),

  /// Teto mensal de tokens atingido (RNF-AI-04).
  ai03('E-AI-03', ErrorClass.ai, 403),

  /// Resposta da IA fora do esquema.
  ai04('E-AI-04', ErrorClass.ai, 200),

  /// Li só parte desta página do extrato (RN-1103).
  ai05('E-AI-05', ErrorClass.ai, 200),

  /// Biometria indisponível no aparelho.
  auth01('E-AUTH-01', ErrorClass.security, null),

  /// Biometria não reconhecida.
  auth02('E-AUTH-02', ErrorClass.security, null),

  /// Sessão, aparelho ou pino recusado.
  auth03('E-AUTH-03', ErrorClass.security, 401),

  /// Código do autenticador errado, já usado ou com a entrada em espera (ADR-027).
  auth04('E-AUTH-04', ErrorClass.security, 401),

  /// Limite de taxa do servidor (RNF-API-04).
  rate01('E-RATE-01', ErrorClass.limit, 429),

  /// Cadeia do registro de eventos quebrada.
  data01('E-DATA-01', ErrorClass.data, 503),

  /// O registro deste aparelho não abre ao abrir o app: um trecho não confere.
  data03('E-DATA-03', ErrorClass.data, null),

  /// Resumo guardado e registro de eventos discordam.
  data02('E-DATA-02', ErrorClass.data, 503),

  /// Armazenamento do aparelho cheio.
  storage01('E-STORAGE-01', ErrorClass.device, null),

  /// Corpo da requisição fora do esquema.
  req01('E-REQ-01', ErrorClass.server, 400),

  /// O item pedido não existe mais.
  req02('E-REQ-02', ErrorClass.server, 404),

  /// App antigo demais para a API (RNF-COMPAT-05).
  req03('E-REQ-03', ErrorClass.server, 426),

  /// Texto enviado acima do limite da API.
  req04('E-REQ-04', ErrorClass.server, 413),

  /// Erro interno do servidor.
  srv01('E-SRV-01', ErrorClass.server, 500),

  /// Servidor reiniciando ou em atualização.
  srv02('E-SRV-02', ErrorClass.server, 503),

  /// Último backup há mais de 36 h (RNF-REL-10).
  srv03('E-SRV-03', ErrorClass.server, 200),

  /// A web não desenhou o primeiro quadro em 10 s (RNF-WEB-10).
  web01('E-WEB-01', ErrorClass.app, null),

  /// Exceção não prevista dentro do app.
  app01('E-APP-01', ErrorClass.app, null);

  new(this.code, this.errorClass, this.httpStatus);

  /// O código como aparece no catálogo e na API: `E-VOUCHER-01`.
  final String code;

  /// A classe do erro, que decide onde e como ele aparece.
  final ErrorClass errorClass;

  /// O status HTTP com que a API devolve este erro; nulo quando o erro só
  /// nasce no aparelho.
  final int? httpStatus;

  /// O código correspondente a [code], ou nulo se ele não for conhecido —
  /// caso em que o app trata a resposta como `E-SRV-01`.
  static ErrorCode? tryParse(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
