/// O contrato entre o app e o servidor do Cajui: códigos de erro, corpo de
/// erro e DTOs. O mesmo pacote dos dois lados — um campo que muda aqui quebra
/// a compilação de quem ficou para trás.
library;

export 'src/api_error.dart';
export 'src/card_codec.dart';
export 'src/create_entry_request.dart';
export 'src/entry_codec.dart';
export 'src/error_class.dart';
export 'src/error_code.dart';
export 'src/failure_mapper.dart';
export 'src/json_reader.dart';
export 'src/payment_line_dto.dart';
