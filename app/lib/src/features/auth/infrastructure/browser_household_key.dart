// A chave do navegador, escolhida pela plataforma em tempo de compilação:
// o armazenamento local onde há navegador, e um vazio onde não há.
export 'browser_household_key_stub.dart'
    if (dart.library.js_interop) 'browser_household_key_web.dart';
