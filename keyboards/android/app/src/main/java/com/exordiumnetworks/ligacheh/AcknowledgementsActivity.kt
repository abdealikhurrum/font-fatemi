package com.exordiumnetworks.ligacheh

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.View
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

// Lists the licenses of the components shipped in this app: the bundled
// FatemiMaqala font (MIT), the app itself (MIT), and the AndroidX libraries
// (Apache 2.0). FatemiMaqala's MIT license and the AndroidX Apache-2.0 license
// both require their notices to travel with the binaries that include them —
// this screen and the bundled res/raw/apache_license_2_0.txt satisfy that.
class AcknowledgementsActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        supportActionBar?.title = "Acknowledgements"

        val root = ScrollView(this)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(20), dp(20), dp(32))
        }
        root.addView(content)
        setContentView(root)

        content.addView(TextView(this).apply {
            text = "LigaCheh is open source under the MIT License and includes " +
                "the following components."
            textSize = 14f
            setTextColor(0xFF555555.toInt())
            setPadding(0, 0, 0, dp(16))
        })

        content.addView(creditCard(
            "FatemiMaqala",
            "The Lisan ud Dawat typeface bundled with this app. A Unicode-" +
                "compliant fork of the AlFatemi font project.",
            mitLicense("Abdeali Khurrum")
        ))

        content.addView(creditCard(
            "LigaCheh Keyboard",
            "This app and its keyboard input method.",
            mitLicense("Abdeali Khurrum")
        ))

        content.addView(creditCard(
            "AndroidX libraries",
            "androidx.core:core-ktx and androidx.appcompat:appcompat, " +
                "© The Android Open Source Project.",
            readRaw(R.raw.apache_license_2_0)
        ))
    }

    private fun creditCard(name: String, summary: String, license: String): LinearLayout {
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(12).toFloat()
            }
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT)
            lp.bottomMargin = dp(16)
            layoutParams = lp
        }
        card.addView(TextView(this).apply {
            text = name
            textSize = 16f
            setTypeface(null, Typeface.BOLD)
            setTextColor(0xFF1C1C1E.toInt())
            setPadding(0, 0, 0, dp(4))
        })
        card.addView(TextView(this).apply {
            text = summary
            textSize = 13f
            setTextColor(0xFF888888.toInt())
            setPadding(0, 0, 0, dp(10))
        })
        card.addView(View(this).apply {
            setBackgroundColor(0xFFE5E5EA.toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 1)
        })
        card.addView(TextView(this).apply {
            text = license
            textSize = 11f
            typeface = Typeface.MONOSPACE
            setTextColor(0xFF666666.toInt())
            setPadding(0, dp(10), 0, 0)
        })
        return card
    }

    private fun readRaw(resId: Int): String =
        resources.openRawResource(resId).bufferedReader().use { it.readText() }

    private fun mitLicense(holder: String): String = """
        MIT License

        Copyright (c) 2026 $holder

        Permission is hereby granted, free of charge, to any person obtaining a
        copy of this software and associated documentation files (the
        "Software"), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, sublicense, and/or sell copies of the Software, and to
        permit persons to whom the Software is furnished to do so, subject to
        the following conditions:

        The above copyright notice and this permission notice shall be included
        in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
        CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
        TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
        SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    """.trimIndent()

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}
