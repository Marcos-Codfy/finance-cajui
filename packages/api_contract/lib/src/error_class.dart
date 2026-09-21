/// As classes de erro do catálogo. A classe decide **onde** o erro aparece
/// (sob o campo, como aviso, em tela inteira), se toca som e se o app tenta
/// de novo sozinho.
enum ErrorClass {
  /// Erro de campo: aparece sob o campo, até ser corrigido.
  validation('validação'),

  /// Uma regra de negócio recusou a ação; depende de uma escolha da pessoa.
  rule('regra'),

  /// Algo impediu a leitura de um comprovante.
  capture('captura'),

  /// Sem conexão, ou o servidor não respondeu a tempo.
  network('rede'),

  /// A fila offline encontrou rejeição ou conflito.
  sync('sincronização'),

  /// A IA está fora do ar, limitada ou sem orçamento. O app segue sem ela.
  ai('ia'),

  /// Limite de taxa: o app espera o prazo informado.
  limit('limite'),

  /// Autenticação e sessão: vago de propósito (RNF-SEC-18).
  security('segurança'),

  /// O registro de eventos não confere. Bloqueia a escrita.
  data('dados'),

  /// Falta algo no aparelho: espaço, biometria.
  device('aparelho'),

  /// O servidor falhou, ou o pedido não foi entendido.
  server('servidor'),

  /// Falha não prevista dentro do app.
  app('app');

  new(this.label);

  /// O nome da classe como aparece no catálogo e no corpo de erro da API.
  final String label;
}
