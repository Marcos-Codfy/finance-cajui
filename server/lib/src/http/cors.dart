import 'package:shelf/shelf.dart';

/// Deixa a web de consulta — e **só ela** — falar com o servidor a partir
/// de outra origem.
///
/// A web mora na Vercel e o servidor na VM (ADR-011, desvio 2 do plano). O
/// navegador só entrega a resposta ao código da página se o servidor disser,
/// por cabeçalho, que aquela origem pode ler; e antes de um `POST` com JSON
/// ele pergunta primeiro, com um `OPTIONS`. Sem isto a web abre, mas
/// nenhuma chamada dela chega ao livro — e foi assim até 27/09/2026, sem
/// ninguém notar, porque a web ainda não tinha sido pareada.
///
/// A origem é uma só, combinada na composição. O app Android não manda
/// `Origin`, e passa por aqui sem que nada mude. Não há credencial de
/// cookie a liberar: a sessão web é um token em memória (ADR-008).
abstract final class Cors {
  /// Aceita chamadas vindas de [allowed]; qualquer outra origem passa sem
  /// cabeçalho nenhum, e o navegador dela bloqueia sozinho.
  static Middleware allow(String allowed) =>
      (inner) => (request) async {
        final origin = request.headers['origin'];
        if (origin != allowed) return await inner(request);
        if (request.method == 'OPTIONS') return _preflight(origin!);
        final response = await inner(request);
        return response.change(headers: _shared(origin!));
      };

  /// A resposta à pergunta prévia do navegador: o que pode, por dez minutos.
  static Response _preflight(String origin) => Response(
    204,
    headers: {
      ..._shared(origin),
      'access-control-allow-methods': 'GET, POST, PUT, DELETE',
      'access-control-allow-headers': 'authorization, content-type',
      'access-control-max-age': '600',
    },
  );

  /// `Vary: Origin` avisa qualquer cache no caminho que a resposta muda
  /// conforme quem pergunta.
  static Map<String, String> _shared(String origin) => {
    'access-control-allow-origin': origin,
    'vary': 'origin',
  };
}
