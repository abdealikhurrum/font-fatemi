package com.lisanuddawat.keyboard

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity

class LessonActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_MODULE_ID = "module_id"
    }

    private lateinit var module: LessonModule
    private var stepIndex = 0

    private lateinit var progressText: TextView
    private lateinit var progressBar: ProgressBar
    private lateinit var headingView: TextView
    private lateinit var bodyView: TextView
    private lateinit var targetCard: LinearLayout
    private lateinit var targetText: TextView
    private lateinit var hintText: TextView
    private lateinit var scratchPad: EditText
    private lateinit var prevButton: Button
    private lateinit var nextButton: Button

    private var fatemiTypeface: Typeface? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val moduleId = intent.getStringExtra(EXTRA_MODULE_ID) ?: run { finish(); return }
        module = LessonCatalog.byId(moduleId)

        fatemiTypeface = runCatching { resources.getFont(R.font.fatemi_maqala_regular) }.getOrNull()

        buildUi()
        showStep(0)
    }

    private fun buildUi() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFFF2F2F7.toInt())
        }
        setContentView(root)

        // ── Top bar ────────────────────────────────────────────────────────
        val topBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(8), dp(8), dp(8), dp(8))
            elevation   = dp(2).toFloat()
        }
        val backBtn = Button(this).apply {
            text     = "‹ Back"
            textSize = 16f
            setTextColor(0xFF007AFF.toInt())
            background = null
            setOnClickListener { finish() }
        }
        val titleView = TextView(this).apply {
            text     = module.title
            textSize = 15f
            setTypeface(null, Typeface.BOLD)
            setTextColor(0xFF1C1C1E.toInt())
            gravity  = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        topBar.addView(backBtn)
        topBar.addView(titleView)
        // spacer to balance back button
        topBar.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(backBtn.layoutParams?.width ?: dp(80), 1)
        })
        root.addView(topBar)

        // ── Progress ───────────────────────────────────────────────────────
        val progressContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(16), dp(8), dp(16), dp(12))
        }
        progressText = TextView(this).apply {
            textSize = 12f
            setTextColor(0xFF6C6C70.toInt())
            setPadding(0, 0, 0, dp(4))
        }
        progressBar = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(4)
            )
        }
        progressContainer.addView(progressText)
        progressContainer.addView(progressBar)
        root.addView(progressContainer)

        // ── Scrollable content ─────────────────────────────────────────────
        val scroll = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0, 1f
            )
        }
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(20), dp(16), dp(16))
        }
        scroll.addView(content)
        root.addView(scroll)

        headingView = TextView(this).apply {
            textSize = 20f
            setTypeface(null, Typeface.BOLD)
            setTextColor(0xFF1C1C1E.toInt())
            setPadding(0, 0, 0, dp(12))
        }
        content.addView(headingView)

        bodyView = TextView(this).apply {
            textSize = 15f
            setTextColor(0xFF3C3C43.toInt())
            //lineSpacingMultiplier = 1.4f
            setPadding(0, 0, 0, dp(20))
        }
        content.addView(bodyView)

        // Target word card (shown only when step has a target)
        targetCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
            background = cardBackground(module.accentColor)
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            lp.bottomMargin = dp(16)
            layoutParams = lp
        }
        val targetLabel = TextView(this).apply {
            text     = "Type this:"
            textSize = 11f
            setTextColor(Color.WHITE)
            alpha    = 0.8f
            setPadding(0, 0, 0, dp(6))
        }
        targetText = TextView(this).apply {
            textSize = 34f
            typeface = fatemiTypeface
            gravity  = Gravity.CENTER
            setTextColor(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        hintText = TextView(this).apply {
            textSize = 12f
            typeface = fatemiTypeface
            gravity  = Gravity.CENTER
            setTextColor(Color.WHITE)
            alpha    = 0.85f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        targetCard.addView(targetLabel)
        targetCard.addView(targetText)
        targetCard.addView(hintText)
        content.addView(targetCard)

        // Scratch pad
        val scratchLabel = TextView(this).apply {
            text     = "Scratch pad — try it:"
            textSize = 12f
            setTextColor(0xFF6C6C70.toInt())
            setPadding(dp(4), 0, 0, dp(4))
        }
        content.addView(scratchLabel)

        scratchPad = EditText(this).apply {
            hint        = "Type here using the keyboard…"
            textSize    = 20f
            typeface    = fatemiTypeface
            gravity     = Gravity.TOP or Gravity.END    // RTL: cursor starts right
            inputType   = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE
            minLines    = 4
            background  = cardBackground(Color.WHITE)
            setPadding(dp(12), dp(10), dp(12), dp(10))
            textDirection = View.TEXT_DIRECTION_RTL
        }
        content.addView(scratchPad)

        // ── Bottom nav ─────────────────────────────────────────────────────
        val navBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(dp(16), dp(12), dp(16), dp(12))
            elevation   = dp(4).toFloat()
        }
        prevButton = Button(this).apply {
            text     = "Previous"
            textSize = 15f
            setTextColor(0xFF007AFF.toInt())
            background = null
            setOnClickListener { if (stepIndex > 0) showStep(stepIndex - 1) }
        }
        val spacer = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, 1, 1f)
        }
        nextButton = Button(this).apply {
            text     = "Next"
            textSize = 15f
            setTextColor(Color.WHITE)
            background = pillBackground(Color.parseColor("#007AFF"))
            val lp = LinearLayout.LayoutParams(dp(100), dp(40))
            layoutParams = lp
            setOnClickListener {
                if (stepIndex < module.steps.lastIndex) {
                    showStep(stepIndex + 1)
                } else {
                    finish()
                }
            }
        }
        navBar.addView(prevButton)
        navBar.addView(spacer)
        navBar.addView(nextButton)
        root.addView(navBar)
    }

    private fun showStep(index: Int) {
        stepIndex = index
        val step  = module.steps[index]
        val total = module.steps.size

        progressText.text = "Step ${index + 1} of $total"
        progressBar.progress = ((index + 1) * 100) / total

        headingView.text = step.heading
        bodyView.text    = step.body

        if (step.target.isNotEmpty()) {
            targetCard.visibility = View.VISIBLE
            targetText.text = step.target
            hintText.text   = step.keyHint
            hintText.visibility = if (step.keyHint.isNotEmpty()) View.VISIBLE else View.GONE
        } else {
            targetCard.visibility = View.GONE
        }

        scratchPad.text.clear()

        prevButton.isEnabled = index > 0
        prevButton.alpha     = if (index > 0) 1f else 0.3f

        val isLast = index == module.steps.lastIndex
        nextButton.text = if (isLast) "Done" else "Next"
    }

    private fun cardBackground(color: Int): GradientDrawable = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(12).toFloat()
    }

    private fun pillBackground(color: Int): GradientDrawable = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(20).toFloat()
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}
