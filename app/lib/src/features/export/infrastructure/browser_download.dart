// O download do navegador, escolhido pela plataforma em tempo de compilação:
// o de verdade onde há navegador, e um vazio onde não há.
export 'browser_download_stub.dart'
    if (dart.library.js_interop) 'browser_download_web.dart';
