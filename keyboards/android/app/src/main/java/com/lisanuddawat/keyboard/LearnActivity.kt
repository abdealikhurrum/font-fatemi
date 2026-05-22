package com.lisanuddawat.keyboard

import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.widget.*
import androidx.appcompat.app.AppCompatActivity

class LearnActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val fatemiTypeface: Typeface? = runCatching {
            resources.getFont(R.font.fatemi_maqala_regular)
        }.getOrNull()

        val root = ScrollView(this)
        root.setBackgroundColor(0xFFF2F2F7.toInt())

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(32))
        }
        root.addView(content)
        setContentView(root)

        // Header
        content.addView(TextView(this).apply {
            text     = "Practice"
            textSize = 28f
            setTypeface(null, Typeface.BOLD)
            setTextColor(0xFF1C1C1E.toInt())
            setPadding(dp(4), dp(8), 0, dp(4))
        })
        content.addView(TextView(this).apply {
            text     = "Learn keyboard features step by step"
            textSize = 14f
            setTextColor(0xFF6C6C70.toInt())
            setPadding(dp(4), 0, 0, dp(24))
        })

        // Module cards
        for (module in LessonCatalog.all) {
            content.addView(makeModuleCard(module, fatemiTypeface))
        }
    }

    private fun makeModuleCard(module: LessonModule, fatemiTypeface: Typeface?): LinearLayout {
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.CENTER_VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
            background = cardBackground()
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            lp.bottomMargin = dp(12)
            layoutParams = lp
            setOnClickListener {
                startActivity(Intent(this@LearnActivity, LessonActivity::class.java).apply {
                    putExtra(LessonActivity.EXTRA_MODULE_ID, module.id)
                })
            }
        }

        // Colored icon tile
        val iconTile = FrameLayout(this).apply {
            background = circleBackground(module.accentColor)
            val size = dp(52)
            val lp = LinearLayout.LayoutParams(size, size)
            lp.marginEnd = dp(16)
            layoutParams = lp
        }
        val iconText = TextView(this).apply {
            text      = module.iconChar
            textSize  = 22f
            typeface  = fatemiTypeface
            gravity   = Gravity.CENTER
            setTextColor(Color.WHITE)
            val lp = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            layoutParams = lp
        }
        iconTile.addView(iconText)

        // Text content
        val textBlock = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        textBlock.addView(TextView(this).apply {
            text     = module.title
            textSize = 16f
            setTypeface(null, Typeface.BOLD)
            setTextColor(0xFF1C1C1E.toInt())
        })
        textBlock.addView(TextView(this).apply {
            text     = module.subtitle
            textSize = 13f
            setTextColor(0xFF6C6C70.toInt())
            setPadding(0, dp(2), 0, dp(4))
        })
        textBlock.addView(TextView(this).apply {
            text     = "${module.stepCount} steps"
            textSize = 12f
            setTextColor(0xFF8E8E93.toInt())
        })

        // Chevron
        val chevron = TextView(this).apply {
            text     = "›"
            textSize = 24f
            setTextColor(0xFFBEBEC0.toInt())
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            lp.marginStart = dp(8)
            layoutParams = lp
        }

        card.addView(iconTile)
        card.addView(textBlock)
        card.addView(chevron)
        return card
    }

    private fun cardBackground(): GradientDrawable = GradientDrawable().apply {
        setColor(Color.WHITE)
        cornerRadius = dp(12).toFloat()
    }

    private fun circleBackground(color: Int): GradientDrawable = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = dp(14).toFloat()
        setColor(color)
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}
