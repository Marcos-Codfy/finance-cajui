import 'package:server/src/ai/chat_tool.dart';
import 'package:server/src/assistant/payment_choice.dart';

/// As ferramentas que o assistente oferece ao modelo (ADR-021): ver o mês e
/// mexer nele.
///
/// A lista é fechada e descrita aqui, em JSON Schema; o modelo só pede o
/// que está nela, com os argumentos que ela prevê. O que ele escreve nos
/// argumentos é conferido de novo por quem executa.
abstract final class AssistantToolCatalog {
  /// O nome da ferramenta que lança uma despesa.
  static const recordExpense = 'lancar_despesa';

  /// O nome da ferramenta que cancela um lançamento.
  static const cancelEntry = 'cancelar_lancamento';

  /// O nome da ferramenta que lista os lançamentos de um mês.
  static const listEntries = 'listar_lancamentos';

  /// O nome da ferramenta que lista as contas do mês ainda não pagas. É
  /// consulta, e não cadastro fixo: o contexto não cresce com o tamanho
  /// da planilha (RN-912).
  static const dueBills = 'contas_a_pagar';

  /// As ferramentas que só leem — as únicas da consulta pela web.
  static const Set<String> readOnly = {listEntries, dueBills};

  /// O nome da ferramenta que registra uma renda.
  static const recordIncome = 'registrar_renda';

  /// O nome da ferramenta que troca a categoria de um lançamento.
  static const recategorize = 'mudar_categoria';

  /// O nome da ferramenta que abate um valor de uma dívida (BL-117).
  static const payDownDebt = 'abater_divida';

  /// As ferramentas, como vão para o modelo.
  static const List<ChatTool> tools = [
    ChatTool(
      name: recordExpense,
      description:
          'Lança uma despesa no livro. Use quando a pessoa disser que gastou, '
          'pagou ou comprou algo. Escolha a categoria mais provável entre as '
          'do cadastro e, sem forma de pagamento dita, use pix.',
      parameters: {
        'type': 'object',
        'properties': {
          'descricao': {
            'type': 'string',
            'description':
                'O que foi comprado ou onde, curto: "mercado", '
                '"uber", "farmácia".',
          },
          'valor_centavos': {
            'type': 'integer',
            'description': r'O valor em centavos: R$ 12,50 é 1250.',
          },
          'categoria_id': {
            'type': 'string',
            'description': 'O id de uma categoria do cadastro.',
          },
          'forma': {
            'type': 'string',
            'description':
                'Por onde foi pago: ${PaymentChoice.options}, ou o id de um '
                'cartão do cadastro.',
          },
          'data': {
            'type': 'string',
            'description': 'AAAA-MM-DD. Omita para hoje.',
          },
          'parcelas': {
            'type': 'integer',
            'description': 'Só em cartão de crédito, quando parcelado.',
          },
        },
        'required': ['valor_centavos', 'categoria_id'],
      },
    ),
    ChatTool(
      name: cancelEntry,
      description:
          'Cancela um lançamento pelo id: "desfaz", "não era isso", "lancei '
          'duas vezes". Sem o id, liste os lançamentos antes.',
      parameters: {
        'type': 'object',
        'properties': {
          'id': {'type': 'string', 'description': 'O id do lançamento.'},
        },
        'required': ['id'],
      },
    ),
    ChatTool(
      name: listEntries,
      description:
          'Os lançamentos de um mês, com id, data, descrição, valor, '
          'categoria e forma de pagamento, mais os totais por moeda.',
      parameters: {
        'type': 'object',
        'properties': {
          'mes': {
            'type': 'string',
            'description': 'AAAA-MM. Omita para o mês atual.',
          },
        },
      },
    ),
    ChatTool(
      name: dueBills,
      description:
          'As contas do mês ainda não pagas: nome, categoria_id, valor, '
          'quando vence e se já venceu. Use para "o que falta pagar?" e para '
          'achar a categoria de uma conta antes de pagá-la.',
      parameters: {'type': 'object', 'properties': <String, Object?>{}},
    ),
    ChatTool(
      name: recordIncome,
      description:
          'Registra dinheiro que entrou: salário, crédito do vale, entrada '
          'avulsa. Não é despesa.',
      parameters: {
        'type': 'object',
        'properties': {
          'valor_centavos': {
            'type': 'integer',
            'description': 'O valor em centavos.',
          },
          'moeda': {
            'type': 'string',
            'enum': ['dinheiro', 'vale'],
            'description': 'Dinheiro na conta, ou crédito no vale alimentação.',
          },
          'tipo': {
            'type': 'string',
            'enum': ['salario', 'avulsa'],
            'description': 'Salário é a renda do mês; o resto é avulsa.',
          },
          'salario_id': {
            'type': 'string',
            'description':
                'De quem é o salário: o id de um dos salários do cadastro. '
                'Mande quando a casa tem mais de um e a pessoa disse de quem.',
          },
          'data': {
            'type': 'string',
            'description': 'AAAA-MM-DD. Omita para hoje.',
          },
        },
        'required': ['valor_centavos'],
      },
    ),
    ChatTool(
      name: recategorize,
      description:
          'Troca a categoria de um lançamento: "isso foi farmácia, não '
          'mercado", "a padaria de ontem era lanche". Sem o id, liste os '
          'lançamentos antes.',
      parameters: {
        'type': 'object',
        'properties': {
          'id': {'type': 'string', 'description': 'O id do lançamento.'},
          'categoria_id': {
            'type': 'string',
            'description': 'O id da categoria nova, do cadastro.',
          },
        },
        'required': ['id', 'categoria_id'],
      },
    ),
    ChatTool(
      name: payDownDebt,
      description:
          'Abate um valor de uma dívida de "dividas": lança o pagamento no '
          'bloco de dívidas e baixa o saldo dela. Use quando a pessoa disser '
          'que pagou, quitou ou abateu parte de uma dívida. Não serve para '
          'parcela no cartão, que se paga pela fatura.',
      parameters: {
        'type': 'object',
        'properties': {
          'divida_id': {
            'type': 'string',
            'description': 'O id de uma dívida de "dividas".',
          },
          'valor_centavos': {
            'type': 'integer',
            'description': 'Quanto foi pago, em centavos.',
          },
          'forma': {
            'type': 'string',
            'description': 'Por onde foi pago: ${PaymentChoice.options}.',
          },
          'data': {
            'type': 'string',
            'description': 'AAAA-MM-DD. Omita para hoje.',
          },
        },
        'required': ['divida_id', 'valor_centavos'],
      },
    ),
  ];
}
