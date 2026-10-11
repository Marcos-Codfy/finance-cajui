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

  /// O nome da ferramenta que registra uma renda.
  static const recordIncome = 'registrar_renda';

  /// O nome da ferramenta que troca a categoria de um lançamento.
  static const recategorize = 'mudar_categoria';

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
  ];
}
