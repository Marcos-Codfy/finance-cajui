/// O texto de um comprovante de Pix como um banco digital o entrega em PDF.
///
/// A **estrutura** é a de um comprovante de verdade — foi ela que mostrou o
/// que o leitor não entendia: mês por extenso na data, valor na linha de
/// baixo do rótulo, recebedor quebrado em várias linhas depois de "Para".
/// Os **dados** são todos inventados: nenhum nome, documento, chave ou
/// identificador daqui existe.
const pixReceiptText = r'''
Comprovante de Pix
12/set/2026 - 081843
Valor
R$ 6,00
Para
LANCHONETE E
RESTAURANTE SABOR DA
PRACA
11.222.333/000181
COOPERATIVA DE CRÉDITO
DE LIVRE ADMISSÃO DO
CERRADO LTDA
De
FULANO DE TAL
DA SILVA
***.123.456**
BANCO EXEMPLO
ID da transação
E00000000202609121118a1B222c3d
44
Detalhes da cobrança
Valor original
R$ 6,00
Identificador
AB1CDEFGHIJK1L2345678901234567
89012
Banco Exemplo Instituição de Pagamento SA
CNPJ nº 00000000/0001-91.
Ouvidoria:
0800 000 0000 (dias úteis de 09h às 18h)
SAC: 0800 000 0001
Canais de atendimento em libras:
exemplo.callvideo.io/banco''';
