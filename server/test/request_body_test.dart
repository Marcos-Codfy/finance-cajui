import 'package:api_contract/api_contract.dart';
import 'package:server/src/http/request_body.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Request _post(String body) =>
    Request('POST', Uri.parse('http://localhost/v1/x'), body: body);

String _text(Object? json) {
  if (json is Map<String, Object?> && json['name'] is String) {
    return json['name']! as String;
  }
  throw const FormatException('esperava name');
}

void main() {
  group(
    'RNF-SEC-09 · o corpo da requisição vira valor antes de chegar à rota',
    () {
      test('corpo bem formado é entendido', () async {
        final read = await RequestBody.decode(_post('{"name":"ana"}'), _text);

        expect(read, isA<Understood<String>>());
        expect((read as Understood<String>).value, 'ana');
      });

      test('o que não é JSON é recusado com E-REQ-01', () async {
        final read = await RequestBody.decode(_post('isto nao e json'), _text);

        expect((read as Refused<String>).code, ErrorCode.req01);
      });

      test('JSON fora do esquema é recusado com E-REQ-01', () async {
        final read = await RequestBody.decode(_post('{"outro":1}'), _text);

        expect((read as Refused<String>).code, ErrorCode.req01);
      });

      test(
        'corpo acima do teto é recusado com E-REQ-04, sem ser lido',
        () async {
          final read = await RequestBody.decode(
            _post('{"name":"${'a' * 200}"}'),
            _text,
            limit: 64,
          );

          expect((read as Refused<String>).code, ErrorCode.req04);
        },
      );

      test('recusado, a rota nem roda e a resposta é do catálogo', () async {
        var ran = false;
        final response = await RequestBody.handle(_post('{"outro":1}'), _text, (
          value,
        ) {
          ran = true;
          return Response.ok(value);
        });

        expect(ran, isFalse);
        expect(response.statusCode, ErrorCode.req01.httpStatus);
      });
    },
  );
}
