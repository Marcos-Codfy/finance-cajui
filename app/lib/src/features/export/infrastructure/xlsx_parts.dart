/// As partes fixas de um arquivo `.xlsx` (Office Open XML): o índice de
/// tipos, as relações, a pasta de trabalho e os estilos.
///
/// Um `.xlsx` é um zip de XMLs. Escrevê-lo aqui, em vez de puxar uma
/// biblioteca de planilha, custa cem linhas e dá controle do que importa: o
/// formato de real, a data brasileira e o negrito dos títulos.
abstract final class XlsxParts {
  /// Texto comum.
  static const textStyle = 0;

  /// Texto em negrito.
  static const boldStyle = 1;

  /// Dinheiro: "R$ 1.234,56".
  static const moneyStyle = 2;

  /// Dinheiro em negrito, para os totais.
  static const boldMoneyStyle = 3;

  /// Data: "03/10/2026".
  static const dateStyle = 4;

  /// Número inteiro.
  static const countStyle = 5;

  /// Percentual: "72%".
  static const percentStyle = 6;

  /// A primeira linha de todo XML do arquivo.
  static const declaration =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

  /// O índice de tipos, com uma entrada para cada uma das [sheets] abas.
  static String contentTypes(int sheets) {
    const sheet =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.'
        'worksheet+xml';
    final overrides = [
      for (var i = 1; i <= sheets; i++)
        '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="$sheet"/>',
    ];
    return '''
$declaration
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
${overrides.join('\n')}
</Types>''';
  }

  /// A relação da raiz com a pasta de trabalho.
  static const String rootRels =
      '''
$declaration
<Relationships xmlns="$_relsNs">
<Relationship Id="rId1" Type="$_docNs/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';

  /// A pasta de trabalho, com as abas [names], na ordem.
  static String workbook(List<String> names) {
    final sheets = [
      for (final (i, name) in names.indexed)
        '<sheet name="${escape(name)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>',
    ];
    return '''
$declaration
<workbook xmlns="$_mainNs" xmlns:r="$_docNs">
<sheets>${sheets.join()}</sheets>
</workbook>''';
  }

  /// As relações da pasta de trabalho com as [sheets] abas e os estilos.
  static String workbookRels(int sheets) {
    final links = [
      for (var i = 1; i <= sheets; i++)
        '<Relationship Id="rId$i" Type="$_docNs/worksheet" Target="worksheets/sheet$i.xml"/>',
    ];
    return '''
$declaration
<Relationships xmlns="$_relsNs">
${links.join('\n')}
<Relationship Id="rId${sheets + 1}" Type="$_docNs/styles" Target="styles.xml"/>
</Relationships>''';
  }

  /// Os estilos. A ordem de `cellXfs` é a das constantes acima: o formato
  /// 164 é o real, com o sinal antes do "R$"; o 165, a data brasileira. O
  /// estilo "Normal" no fim é o que todo leitor espera achar; sem ele, há
  /// leitor que avisa e aplica um padrão próprio.
  static const String styles =
      '''
$declaration
<styleSheet xmlns="$_mainNs">
<numFmts count="2">
<numFmt numFmtId="164" formatCode="&quot;R\$&quot;\\ #,##0.00;\\-&quot;R\$&quot;\\ #,##0.00"/>
<numFmt numFmtId="165" formatCode="dd/mm/yyyy"/>
</numFmts>
<fonts count="2">
<font><sz val="11"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><name val="Calibri"/></font>
</fonts>
<fills count="2">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
</fills>
<borders count="1"><border/></borders>
<cellStyleXfs count="1"><xf/></cellStyleXfs>
<cellXfs count="7">
<xf/>
<xf fontId="1" applyFont="1"/>
<xf numFmtId="164" applyNumberFormat="1"/>
<xf numFmtId="164" fontId="1" applyNumberFormat="1" applyFont="1"/>
<xf numFmtId="165" applyNumberFormat="1"/>
<xf numFmtId="1" applyNumberFormat="1"/>
<xf numFmtId="9" applyNumberFormat="1"/>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''';

  /// O espaço de nomes das planilhas.
  static const String mainNs = _mainNs;

  /// [text] seguro dentro de XML. Os caracteres de controle que o XML 1.0
  /// não aceita nem como referência saem antes: uma descrição colada com um
  /// deles fazia o Excel recusar o arquivo inteiro.
  static String escape(String text) => text
      .replaceAll(_illegal, '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static final _illegal = RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F￾￿]');

  static const _mainNs =
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const _relsNs =
      'http://schemas.openxmlformats.org/package/2006/relationships';
  static const _docNs =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
}
