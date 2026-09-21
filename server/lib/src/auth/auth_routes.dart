import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:server/src/auth/challenge_book.dart';
import 'package:server/src/auth/device_registry.dart';
import 'package:server/src/auth/enrollment_codes.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/auth/session_scope.dart';
import 'package:server/src/auth/signature_verifier.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/json_body.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// As rotas de autenticação: cadastrar o aparelho, pedir um desafio, e trocar
/// o desafio assinado por uma sessão (ADR-008).
///
/// Toda recusa responde a mesma coisa — `E-AUTH-03` ou `E-AUTH-04` —, sem
/// dizer se o aparelho existe, se o desafio venceu ou se a assinatura estava
/// errada (RNF-SEC-18).
final class AuthRoutes {
  /// Cria as rotas sobre as peças de autenticação.
  new({
    required this.devices,
    required this.codes,
    required this.challenges,
    required this.sessions,
  });

  /// Os aparelhos cadastrados.
  final DeviceRegistry devices;

  /// Os códigos de cadastro.
  final EnrollmentCodes codes;

  /// Os desafios em aberto.
  final ChallengeBook challenges;

  /// As sessões abertas.
  final SessionBook sessions;

  /// O roteador, montado em `/v1/auth`.
  Router get router => Router()
    ..post('/enroll', _enroll)
    ..post('/challenge', _challenge)
    ..post('/session', _session);

  Future<Response> _enroll(Request request) async {
    final body = JsonReader(
      await JsonBody.read(request),
      allowed: const {'code', 'deviceId', 'name', 'publicKey'},
    );
    final publicKey = base64Decode(body.string('publicKey'));
    final accepted =
        SignatureVerifier.isValidPublicKey(publicKey) &&
        codes.consume(body.string('code', maxLength: 16));
    if (!accepted) return Responses.error(request, ErrorCode.auth04);
    final deviceId = body.string('deviceId', maxLength: 64);
    await devices.enroll(
      deviceId: deviceId,
      name: body.string('name', maxLength: 60),
      publicKey: publicKey,
    );
    return Responses.json({'deviceId': deviceId}, status: 201);
  }

  Future<Response> _challenge(Request request) async {
    final body = JsonReader(
      await JsonBody.read(request),
      allowed: const {'deviceId'},
    );
    final challenge = challenges.issue(body.string('deviceId', maxLength: 64));
    return Responses.json({
      'challengeId': challenge.id,
      'nonce': base64Encode(challenge.nonce),
    });
  }

  Future<Response> _session(Request request) async {
    final body = JsonReader(
      await JsonBody.read(request),
      allowed: const {'challengeId', 'signature'},
    );
    final challenge = challenges.take(body.string('challengeId'));
    final publicKey = challenge == null
        ? null
        : devices.publicKeyOf(challenge.deviceId);
    final valid =
        challenge != null &&
        publicKey != null &&
        SignatureVerifier.verify(
          publicKey: publicKey,
          message: challenge.nonce,
          signature: base64Decode(body.string('signature')),
        );
    if (!valid) return Responses.error(request, ErrorCode.auth03, status: 401);
    return Responses.json({
      'token': sessions.open(challenge.deviceId, scope: SessionScope.device),
      'expiresInSeconds': SessionBook.deviceLifetime.inSeconds,
    });
  }
}
