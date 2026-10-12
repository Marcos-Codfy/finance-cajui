package app.cajui.capture

import com.google.mlkit.vision.text.Text
import kotlin.math.abs

/**
 * O texto de uma página remontado em linhas pela posição (ADR-030).
 *
 * O ML Kit devolve o texto por blocos, e numa página em forma de tabela —
 * data, descrição, valor — cada coluna pode virar um bloco: a data de uma
 * linha chega longe do valor dela, e quem lê o extrato junta pedaços de
 * linhas diferentes. Visto no S22 em 12/10, com um extrato fictício: o
 * nome do restaurante saiu com o valor do mercado e a data de outra linha.
 *
 * Aqui cada pedaço lido volta para a altura em que está na página: os que
 * dividem a mesma faixa formam uma linha, da esquerda para a direita, como
 * no papel. Só o extrato usa este texto; o comprovante segue lendo o do
 * ML Kit, que as regras dele já conhecem.
 */
object TextRows {

    /** As linhas de [result], uma por faixa da página. */
    fun of(result: Text): String = join(
        result.textBlocks.flatMap { it.lines }.mapNotNull { line ->
            line.boundingBox?.let { Piece(line.text, it.left, it.top, it.bottom) }
        },
    )

    /** Um pedaço lido e a sua caixa na página. */
    data class Piece(val text: String, val left: Int, val top: Int, val bottom: Int) {
        val middle: Double get() = (top + bottom) / 2.0
        val height: Int get() = bottom - top
    }

    /** Junta [pieces] em linhas: de cima para baixo e, em cada uma, da esquerda para a direita. */
    fun join(pieces: List<Piece>): String {
        val rows = mutableListOf<MutableList<Piece>>()
        for (piece in pieces.sortedBy { it.middle }) {
            val row = rows.lastOrNull()
            if (row != null && sameRow(row, piece)) row.add(piece) else rows.add(mutableListOf(piece))
        }
        return rows.joinToString("\n") { row ->
            row.sortedBy { it.left }.joinToString("  ") { it.text }
        }
    }

    /**
     * Mesma linha quando o meio do pedaço fica a menos de meia altura do
     * meio da linha. As linhas de um extrato ficam a uma altura inteira uma
     * da outra, então a folga não junta duas.
     */
    private fun sameRow(row: List<Piece>, piece: Piece): Boolean {
        val middle = row.map { it.middle }.average()
        val height = maxOf(row.map { it.height }.average(), piece.height.toDouble())
        return abs(piece.middle - middle) < height / 2
    }
}
