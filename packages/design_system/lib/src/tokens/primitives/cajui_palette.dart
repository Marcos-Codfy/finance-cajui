import 'package:flutter/painting.dart';

/// A paleta crua do Cerrado: os únicos valores hexadecimais do projeto.
///
/// Ninguém fora da camada de tokens semânticos lê esta classe. Componente que
/// precisa de cor pede um papel (`text.muted`, `action.primary`), nunca um
/// tom — é isso que mantém uma mudança de cor restrita a um lugar só.
///
/// Os valores vêm de `docs/brand/color.md`. Três deles foram ajustados aqui
/// para fechar furos de contraste medidos (BL-016): [inkFaint], [moonFaint] e
/// os contornos de campo.
abstract final class CajuiPalette {
  // Superfícies claras.
  /// Areia: fundo do tema claro.
  static const sand = Color(0xFFFBF6EE);

  /// Areia funda: seção, campo, chip.
  static const sandDeep = Color(0xFFF3EADC);

  /// Papel: cartão e folha elevada.
  static const paper = Color(0xFFFFFFFF);

  // Tinta (texto no claro).
  /// Castanha: texto principal.
  static const ink = Color(0xFF2A1D17);

  /// Castanha suave: texto secundário.
  static const inkSoft = Color(0xFF5F4E44);

  /// Castanha tênue. Escurecida de 7A685D para passar de 4,5:1 também sobre
  /// a areia funda, que é o caso do texto de apoio dentro de campo.
  static const inkFaint = Color(0xFF726157);

  /// Contorno de campo no claro: 3:1 contra areia, areia funda e papel.
  static const inkOutline = Color(0xFF8F8073);

  // Superfícies escuras.
  /// Noite: fundo do tema escuro. Azul-petróleo, não preto.
  static const night = Color(0xFF0F1A1E);

  /// Noite funda: área rebaixada no escuro.
  static const nightDeep = Color(0xFF0B1417);

  /// Noite elevada: cartão.
  static const nightRaised = Color(0xFF17262C);

  /// Noite alta: folha, menu, campo.
  static const nightHigh = Color(0xFF203239);

  // Luar (texto no escuro).
  /// Luar: texto principal.
  static const moon = Color(0xFFF4ECE0);

  /// Luar suave: texto secundário.
  static const moonSoft = Color(0xFFB9AFA3);

  /// Luar tênue. Clareado de 94897E para passar de 4,5:1 sobre a noite alta.
  static const moonFaint = Color(0xFFA3988D);

  /// Contorno de campo no escuro: 3:1 contra as três superfícies escuras.
  static const moonOutline = Color(0xFF6E7F84);

  // Cajuí: o acento da marca.
  /// Cajuí puro. Só áreas grandes e gráficos (3,42:1 sobre a areia).
  static const cajui = Color(0xFFE4572E);

  /// Cajuí forte: botão e texto de destaque no claro.
  static const cajuiStrong = Color(0xFFB93D17);

  /// Cajuí forte ao passar o cursor.
  static const cajuiStrongHover = Color(0xFFA33512);

  /// Cajuí profundo: botão pressionado no claro.
  static const cajuiDeep = Color(0xFF8F2D10);

  /// Cajuí claro: o acento no tema escuro.
  static const cajuiLight = Color(0xFFFF8A5C);

  /// Cajuí claro ao passar o cursor.
  static const cajuiLightHover = Color(0xFFFF9C75);

  /// Cajuí claro pressionado.
  static const cajuiLightPressed = Color(0xFFF07A4C);

  // Capim dourado: conquista. Nunca carrega texto sozinho.
  /// Capim dourado, decorativo.
  static const gold = Color(0xFFD9A441);

  /// Capim forte: o ouro quando precisa ser lido no claro.
  static const goldStrong = Color(0xFF8A6210);

  /// Capim claro: o ouro no tema escuro.
  static const goldLight = Color(0xFFF0C26A);

  /// O fim da hora azul: o roxo escuro em que a aurora do widget se apaga.
  /// Só fundo de luz difusa, nunca de texto pequeno.
  static const dusk = Color(0xFF241B2E);

  // Vereda, barro, céu e o vermelho reservado.
  /// Vereda: sobra, progresso, confirmação.
  static const vereda = Color(0xFF2E6F57);

  /// Vereda clara, para o tema escuro.
  static const veredaLight = Color(0xFF6FCBA6);

  /// Barro: atenção sem alarme.
  static const clay = Color(0xFF8C4A2F);

  /// Barro claro, para o tema escuro.
  static const clayLight = Color(0xFFE0A07F);

  /// Ipê-roxo: as assinaturas no gráfico e nas listas — o tom que faltava
  /// entre fixas, dia a dia, dívidas e vale (17/10/2026).
  static const ipe = Color(0xFF8E2F7A);

  /// Ipê-roxo claro, para o fundo escuro.
  static const ipeLight = Color(0xFFD9A0CC);

  /// Céu: informação, foco de teclado, link.
  static const sky = Color(0xFF2F6F8F);

  /// Céu claro, para o tema escuro.
  static const skyLight = Color(0xFF7FC1E0);

  /// Vermelho: só erro de sistema e ação destrutiva (D-UX-02).
  static const red = Color(0xFFB3261E);

  /// Vermelho claro, para o tema escuro.
  static const redLight = Color(0xFFFF8A80);

  // Fundos sutis dos avisos, claro e escuro.
  /// Fundo sutil de vereda.
  static const veredaWash = Color(0xFFE3EFE9);

  /// Fundo sutil de barro.
  static const clayWash = Color(0xFFF3E3DA);

  /// Fundo sutil de céu.
  static const skyWash = Color(0xFFE1EDF3);

  /// Fundo sutil de capim.
  static const goldWash = Color(0xFFF8EBCB);

  /// Fundo sutil de vermelho.
  static const redWash = Color(0xFFF9E1DE);

  /// Fundo sutil de vereda no escuro.
  static const veredaShade = Color(0xFF15302A);

  /// Fundo sutil de barro no escuro.
  static const clayShade = Color(0xFF33231C);

  /// Fundo sutil de céu no escuro.
  static const skyShade = Color(0xFF16303B);

  /// Fundo sutil de capim no escuro.
  static const goldShade = Color(0xFF33290F);

  /// Fundo sutil de vermelho no escuro.
  static const redShade = Color(0xFF3A1E1C);

  // Estados desabilitados. Texto desabilitado é isento de contraste mínimo.
  /// Fundo desabilitado no claro.
  static const sandMuted = Color(0xFFE9DFD0);

  /// Texto desabilitado no claro.
  static const inkDisabled = Color(0xFF9A8B80);

  /// Texto desabilitado no escuro.
  static const moonDisabled = Color(0xFF66777C);

  // O gradiente do fruto, o mesmo do símbolo da marca.
  /// Topo do fruto: amarelo-capim.
  static const fruitTop = Color(0xFFF4B740);

  /// Meio do fruto.
  static const fruitMiddle = Color(0xFFEE7B33);

  /// Base do fruto: vermelho-cajuí.
  static const fruitBottom = Color(0xFFD5411E);
}
