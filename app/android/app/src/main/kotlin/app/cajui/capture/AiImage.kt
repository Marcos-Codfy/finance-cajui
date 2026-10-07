package app.cajui.capture

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.media.ExifInterface
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * A imagem que vai para a IA ler o comprovante (ADR-022): JPEG, com o lado
 * maior em [MAX_SIDE] px, de pé como a pessoa a viu.
 *
 * O provedor reduz toda imagem a uns 1300×1300 de área; mandar mais que
 * isso só gastaria a rede do celular. Mandar menos deixaria a letra miúda de
 * cupom ilegível. A foto da câmera vem deitada no arquivo e de pé na
 * marcação EXIF: sem girar, a IA leria o cupom de lado.
 */
object AiImage {

    /** O lado maior da imagem enviada. */
    const val MAX_SIDE = 2000

    private const val QUALITY = 80

    /** A foto ou o print em [file], reduzido, de pé e em JPEG. */
    fun fromFile(file: File): ByteArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, bounds)
        val longest = maxOf(bounds.outWidth, bounds.outHeight)
        var sample = 1
        while (longest / (sample * 2) >= MAX_SIDE) sample *= 2
        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        val decoded = BitmapFactory.decodeFile(file.path, options)
            ?: throw ReadFailure("E-CAPT-01")
        return jpeg(upright(scaled(decoded), orientationOf(file)))
    }

    /** Uma página de PDF já desenhada, reduzida e em JPEG. */
    fun fromBitmap(bitmap: Bitmap): ByteArray = jpeg(scaled(bitmap))

    private fun scaled(bitmap: Bitmap): Bitmap {
        val longest = maxOf(bitmap.width, bitmap.height)
        if (longest <= MAX_SIDE) return bitmap
        val scale = MAX_SIDE.toFloat() / longest
        return Bitmap.createScaledBitmap(
            bitmap,
            (bitmap.width * scale).toInt(),
            (bitmap.height * scale).toInt(),
            true,
        )
    }

    private fun orientationOf(file: File): Int = try {
        ExifInterface(file.path).getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL,
        )
    } catch (unreadable: Exception) {
        ExifInterface.ORIENTATION_NORMAL
    }

    private fun upright(bitmap: Bitmap, orientation: Int): Bitmap {
        val degrees = when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> return bitmap
        }
        val matrix = Matrix().apply { postRotate(degrees) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    /**
     * Em JPEG, sobre fundo branco: um print com transparência viraria preto
     * no preto ao perder o canal alfa.
     */
    private fun jpeg(bitmap: Bitmap): ByteArray {
        val opaque = if (bitmap.hasAlpha()) onWhite(bitmap) else bitmap
        return ByteArrayOutputStream().use { out ->
            opaque.compress(Bitmap.CompressFormat.JPEG, QUALITY, out)
            out.toByteArray()
        }
    }

    private fun onWhite(bitmap: Bitmap): Bitmap {
        val flat = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        Canvas(flat).apply {
            drawColor(Color.WHITE)
            drawBitmap(bitmap, 0f, 0f, null)
        }
        return flat
    }
}
