import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/ai_statement_reader.dart';
import 'package:server/src/ai/receipt_image.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/request_body.dart';
import 'package:server/src/ledger/household_facts.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// A rota de leitura de extrato, uma página por pedido (ADR-030):
/// `POST /v1/statements/read-part`.
///
/// Quem faz o laço é o celular, página a página, com "Lendo a página 3 de
/// 7": várias leituras de 35 s num pedido só estourariam o prazo dele. Aqui
/// entra a mesma chave da casa das outras rotas; a sessão da web, que só
/// consulta, não lê extrato (RN-1100).
final class StatementRoutes {
  /// Cria a rota. Sem [reader] — servidor sem a credencial da IA —, toda
  /// página recebe `E-AI-01`, e o resto do servidor segue funcionando.
  new({required this.state, required this.clock, this.reader});

  /// O estado, de onde vêm as categorias e os nomes da casa.
  final LedgerState state;

  /// O relógio, para recusar data futura.
  final Clock clock;

  /// Quem lê a página com a IA.
  final AiStatementReader? reader;

  /// O roteador, montado em `/v1/statements`.
  Router get router => Router()..post('/read-part', _readPart);

  /// O maior corpo aceito: a imagem de uma página em base64 e as linhas.
  static const int maxBodyBytes = 4 * 1024 * 1024;

  Future<Response> _readPart(Request request) =>
      RequestBody.handle(request, _pageOf, (page) async {
        final reader = this.reader;
        if (reader == null) return Responses.error(request, ErrorCode.ai01);
        final outcome = await reader.read(
          _withUsableExamples(page),
          categories: state.categories.values.toList(),
          today: clock.today(),
          // Os nomes da casa saem do texto antes da IA (RN-732, BL-093).
          householdNames: HouseholdFacts.namesIn(state),
        );
        if (outcome.reply case final reply?) {
          return Responses.json(reply.toJson());
        }
        final code = outcome.error ?? ErrorCode.ai01;
        return Responses.error(
          request,
          code,
          retryAfterSeconds: outcome.retryAfterSeconds,
          // Resposta da IA fora do esquema é falha da página, e não aviso: o
          // celular tenta a página de novo (RN-1102).
          status: code == ErrorCode.ai04 ? 502 : null,
        );
      }, limit: maxBodyBytes);

  /// A página do extrato, já conferida. O tipo da imagem vem dos primeiros
  /// bytes, nunca do que o app disse.
  static StatementPageRequest _pageOf(Object? json) {
    final page = StatementPageRequest.fromJson(json);
    final image = page.image;
    if (image != null && ReceiptImage.mimeOf(image) == null) {
      throw const FormatException('imagem fora do formato');
    }
    return page;
  }

  /// Os exemplos que podem ir à IA: de categoria que o servidor conhece, e
  /// nunca de pessoa (RN-1107). O celular já os tira; o servidor confere
  /// de novo, porque não confia em ninguém para isso.
  StatementPageRequest _withUsableExamples(StatementPageRequest page) =>
      StatementPageRequest(
        lines: page.lines,
        page: page.page,
        pageCount: page.pageCount,
        image: page.image,
        period: page.period,
        examples: {
          for (final MapEntry(:key, :value) in page.examples.entries)
            if (!_aboutPerson(key) && state.categories.containsKey(value))
              key: value,
        },
      );

  static bool _aboutPerson(String key) =>
      key.trim().toLowerCase().startsWith(StatementLineResolver.personPrefix);
}
