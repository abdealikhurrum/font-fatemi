package com.lisanuddawat.keyboard

import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.*
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private var fatemiTypeface: Typeface? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        fatemiTypeface = runCatching { resources.getFont(R.font.fatemi_maqala_regular) }.getOrNull()

        val root = ScrollView(this)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(48), dp(24), dp(32))
        }
        root.addView(content)
        setContentView(root)

        // Font preview
        content.addView(TextView(this).apply {
            text      = "كيم چھو؟"
            textSize  = 18f
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            typeface  = fatemiTypeface
            setTextColor(0xFF555555.toInt())
            setPadding(0, 0, 0, dp(32))
        })

        content.addView(TextView(this).apply {
            text     = "Lisan ud Dawat Keyboard"
            textSize = 22f
            setTypeface(null, Typeface.BOLD)
            setPadding(0, 0, 0, dp(4))
        })
        content.addView(TextView(this).apply {
            text     = "Arabic/Urdu keyboard with FatemiMaqala font"
            textSize = 14f
            setTextColor(0xFF888888.toInt())
            setPadding(0, 0, 0, dp(32))
        })

        // Setup steps
        content.addView(makeStep("1. Enable the keyboard",
            "Open Android keyboard settings and toggle on \"Lisan ud Dawat\"."))
        content.addView(Button(this).apply {
            text = "Open Keyboard Settings"
            setOnClickListener { startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)) }
        })

        content.addView(makeStep("2. Select the keyboard",
            "Tap the keyboard/globe icon in any text field and pick \"Lisan ud Dawat\"."))
        content.addView(Button(this).apply {
            text = "Switch Input Method"
            setOnClickListener {
                (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager).showInputMethodPicker()
            }
        })

        content.addView(makeStep("Font included",
            "FatemiMaqala is bundled inside this app — no separate font installation needed. " +
            "The keyboard renders all Arabic/Urdu characters using this font automatically."))

        // Practice
        content.addView(makeStep("Practice",
            "Use the interactive lesson modules to learn double-press characters, diacritics, and special keys."))
        content.addView(Button(this).apply {
            text = "Open Lessons"
            setOnClickListener { startActivity(Intent(this@MainActivity, LearnActivity::class.java)) }
        })

        // Settings
        content.addView(makeStep("Settings", "Adjust keyboard layout and behaviour."))
        content.addView(buildSettingsCard())
    }

    // ── Settings card ─────────────────────────────────────────────────────

    private fun buildSettingsCard(): LinearLayout {
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(4), dp(16), dp(12))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(12).toFloat()
            }
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT)
            lp.topMargin = dp(8)
            layoutParams = lp
        }

        // Layout picker
        card.addView(settingRow("Layout", segControl(
            items    = listOf("LSD", "Arabic", "Urdu"),
            current  = when (KeyboardSettings.getLayout(this)) {
                KeyboardSettings.LayoutType.LSD            -> 0
                KeyboardSettings.LayoutType.ARABIC_STANDARD -> 1
                KeyboardSettings.LayoutType.CRULP_URDU      -> 2
            },
            onSelect = { idx ->
                KeyboardSettings.setLayout(this, when (idx) {
                    0    -> KeyboardSettings.LayoutType.LSD
                    1    -> KeyboardSettings.LayoutType.ARABIC_STANDARD
                    else -> KeyboardSettings.LayoutType.CRULP_URDU
                })
            }
        )))

        // Yeh style — always visible, note that it only affects the Urdu layout
        card.addView(hairline())
        card.addView(settingRow("Default yeh (Urdu)", segControl(
            items    = listOf("ی", "ي"),
            current  = if (KeyboardSettings.getUrduYehStyle(this) == KeyboardSettings.UrduYehStyle.FARSI_YEH) 0 else 1,
            font     = fatemiTypeface,
            onSelect = { idx ->
                KeyboardSettings.setUrduYehStyle(this,
                    if (idx == 0) KeyboardSettings.UrduYehStyle.FARSI_YEH
                    else          KeyboardSettings.UrduYehStyle.ARABIC_YEH)
            }
        )))

        card.addView(hairline())
        card.addView(toggleRow("Word predictions",
            get = { KeyboardSettings.getPredictions(this) },
            set = { KeyboardSettings.setPredictions(this, it) }))

        card.addView(hairline())
        card.addView(toggleRow("Double-press",
            get = { KeyboardSettings.getDoublePressEnabled(this) },
            set = { KeyboardSettings.setDoublePressEnabled(this, it) }))

        card.addView(hairline())
        val windowValues = listOf(250L, 400L, 600L)
        card.addView(settingRow("Press window", segControl(
            items    = listOf("0.25s", "0.40s", "0.60s"),
            current  = windowValues.indexOfFirst { it == KeyboardSettings.getDoublePressWindowMs(this) }.coerceAtLeast(1),
            onSelect = { idx -> KeyboardSettings.setDoublePressWindowMs(this, windowValues[idx]) }
        )))

        card.addView(hairline())
        card.addView(settingRow("Double ا", segControl(
            items    = listOf("اٰ", "آ"),
            current  = if (KeyboardSettings.getDoubleAlefStyle(this) == KeyboardSettings.DoubleAlefStyle.KHARO_ZABAR) 0 else 1,
            font     = fatemiTypeface,
            onSelect = { idx ->
                KeyboardSettings.setDoubleAlefStyle(this,
                    if (idx == 0) KeyboardSettings.DoubleAlefStyle.KHARO_ZABAR
                    else          KeyboardSettings.DoubleAlefStyle.ALEF_MADDA)
            }
        )))

        return card
    }

    // ── Widget helpers ────────────────────────────────────────────────────

    private fun settingRow(label: String, control: View): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(48))
            addView(TextView(this@MainActivity).apply {
                text     = label
                textSize = 14f
                setTextColor(0xFF1C1C1E.toInt())
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            })
            addView(control)
        }

    private fun toggleRow(label: String, get: () -> Boolean, set: (Boolean) -> Unit): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(48))
            addView(TextView(this@MainActivity).apply {
                text     = label
                textSize = 14f
                setTextColor(0xFF1C1C1E.toInt())
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            })
            addView(Switch(this@MainActivity).apply {
                isChecked = get()
                setOnCheckedChangeListener { _, v -> set(v) }
            })
        }

    private fun segControl(
        items: List<String>,
        current: Int,
        font: Typeface? = null,
        onSelect: (Int) -> Unit
    ): LinearLayout {
        var sel = current
        val buttons = mutableListOf<TextView>()

        fun refresh() {
            for ((i, b) in buttons.withIndex()) {
                b.background = if (i == sel) GradientDrawable().apply {
                    setColor(Color.parseColor("#007AFF")); cornerRadius = dp(5).toFloat()
                } else null
                b.setTextColor(if (i == sel) Color.WHITE else 0xFF555555.toInt())
            }
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            background  = GradientDrawable().apply {
                setColor(0xFFE5E5EA.toInt()); cornerRadius = dp(7).toFloat()
            }
            setPadding(dp(2), dp(2), dp(2), dp(2))
        }
        for ((i, text) in items.withIndex()) {
            val b = TextView(this).apply {
                this.text = text
                textSize  = if (font != null) 15f else 12f
                typeface  = font ?: Typeface.DEFAULT
                gravity   = Gravity.CENTER
                isClickable = true; isFocusable = true
                setPadding(dp(10), dp(5), dp(10), dp(5))
                setOnClickListener { sel = i; refresh(); onSelect(i) }
            }
            buttons.add(b)
            container.addView(b, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT))
        }
        refresh()
        return container
    }

    private fun hairline() = View(this).apply {
        setBackgroundColor(0xFFE5E5EA.toInt())
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 1)
    }

    private fun makeStep(title: String, body: String): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(20), 0, dp(8))
            addView(TextView(this@MainActivity).apply {
                text     = title
                textSize = 16f
                setTypeface(null, Typeface.BOLD)
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
