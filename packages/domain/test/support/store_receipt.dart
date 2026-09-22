/// O texto de um cupom fiscal de supermercado, no formato em que o OCR o
/// entrega: cabeçalho com razão social, CNPJ e endereço; uma linha por item,
/// com código, descrição, quantidade e valor; e o rodapé com total, desconto
/// e o que foi pago.
///
/// A estrutura é a de um cupom de verdade — inclusive a ordem "valor total,
/// desconto, valor a pagar", que é onde o leitor errava. Os dados são todos
/// inventados.
const storeReceiptText = r'''
MAR DOCE SUPERMERCADOS LTDA
CNPJ: 11.222.333/0001-81
AV JOAQUIM EXEMPLO,5500,PLANO DIRETOR SUL,PALMAS
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
NAO E DOCUMENTO FISCAL
Codigo Descricao Qtde UN Vl Unit Vl Total
AR075629 POSTA TILAPIA CONGELADA 1X800G 1 UND 25,75 25,75
AR085606 MUSSARELA FATIADA 0,406kg x 51,90 R$/kg 21,07
AR070958 MASSA PASTEL GRANDE 1X500G 1 PCT 9,90 9,90
AR066649 FEIJAO PRETO TEMPERADO 1X800G 1 UND 13,80 13,80
AR001646 BANANA PRATA 0,900kg x 4,99 R$/kg 4,49
desconto sobre item 0,45
AR021933 ALHO A GRANEL 0,255kg x 19,90 R$/kg 5,07
AR009803 ACUCAR CRISTAL 1X400G 1 UND 13,90 13,90
AR057161 PAO FORMA 1X2Kg 1 UND 5,85 5,85
Qtde. total de itens 65
Valor total R$ 664,41
Desconto total R$ 10,83
Valor a Pagar R$ 653,58
FORMA DE PAGAMENTO VALOR PAGO R$
Outros 653,58
Consulte pela Chave de Acesso em
http://www.sefaz.exemplo.gov.br/nfce/qrcode''';
