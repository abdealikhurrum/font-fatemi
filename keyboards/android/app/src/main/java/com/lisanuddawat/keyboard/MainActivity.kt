package com.lisanuddawat.keyboard

import android.content.Intent
import android.graphics.Typeface
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.*
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = ScrollView(this)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(48), dp(24), dp(32))
        }
        root.addView(content)
        setContentView(root)

        val fatemiTypeface: Typeface? = runCatching {
            resources.getFont(R.font.fatemi_maqala_regular)
        }.getOrNull()

        // Font preview
        content.addView(TextView(this).apply {
            text      = "بسم الله الرحمن الرحيم"
            textSize  = 28f
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            typeface  = fatemiTypeface
            setPadding(0, 0, 0, dp(8))
        })
        content.addView(TextView(this).apply {
            text      = "الفاتمي مقالة"
            textSize  = 18f
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            typeface  = fatemiTypeface
            setTextColor(0xFF555555.toInt())
            setPadding(0, 0, 0, dp(32))
        })

        content.addView(TextView(this).apply {
            text     = "Lisan ud Dawat Keyboard"
            textSize = 22f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(0, 0, 0, dp(4))
        })
        content.addView(TextView(this).apply {
            text     = "Arabic/Urdu keyboard with FatemiMaqala font"
            textSize = 14f
            setTextColor(0xFF888888.toInt())
            setPadding(0, 0, 0, dp(32))
        })

        // Step 1
        content.addView(makeStep(
            "1. Enable the keyboard",
            "Open Android keyboard settings and toggle on \"Lisan ud Dawat\"."
        ))
        content.addView(Button(this).apply {
            text = "Open Keyboard Settings"
            setOnClickListener { startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)) }
        })

        // Step 2
        content.addView(makeStep(
            "2. Select the keyboard",
            "Tap the keyboard/globe icon in any text field and pick \"Lisan ud Dawat\"."
        ))
        content.addView(Button(this).apply {
            text = "Switch Input Method"
            setOnClickListener {
                (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager)
                    .showInputMethodPicker()
            }
        })

        // Font note
        content.addView(makeStep(
            "Font included",
            "FatemiMaqala is bundled inside this app — no separate font installation is needed on Android. " +
            "The keyboard renders all Arabic/Urdu characters using this font automatically."
        ))
    }

    private fun makeStep(title: String, body: String): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(20), 0, dp(8))
            addView(TextView(this@MainActivity).apply {
                text     = title
                textSize = 16f
                setTypeface(null, android.graphics.Typeface.BOLD)
                setPadding(0, 0, 0, dp(4))
            })
            addView(TextView(this@MainActivity).apply {
                text     = body
                textSize = 14f
                setTextColor(0xFF555555.toInt())
            })
        }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}
