package com.lisanuddawat.keyboard

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color

object KeyboardColors {

    fun background(ctx: Context)      = if (dark(ctx)) Color.parseColor("#232325") else Color.parseColor("#CFD1D7")
    fun predictiveBar(ctx: Context)   = if (dark(ctx)) Color.parseColor("#1C1C1E") else Color.parseColor("#D6D8DC")
    fun separator(ctx: Context)       = if (dark(ctx)) Color.parseColor("#474747") else Color.parseColor("#A1A1A1")
    fun characterKey(ctx: Context)    = if (dark(ctx)) Color.parseColor("#6B6B70") else Color.WHITE
    fun specialKey(ctx: Context)      = if (dark(ctx)) Color.parseColor("#2A2A2D") else Color.parseColor("#A6ACB7")
    fun pressedKey(ctx: Context)      = if (dark(ctx)) Color.parseColor("#3D3D41") else Color.parseColor("#A6ACB7")
    fun shiftLockedBg(ctx: Context)   = if (dark(ctx)) Color.parseColor("#D9D9D9") else Color.parseColor("#383838")
    fun shiftLockedText(ctx: Context) = if (dark(ctx)) Color.BLACK               else Color.WHITE
    fun keyLabel(ctx: Context)        = if (dark(ctx)) Color.WHITE                else Color.parseColor("#1C1C1E")
    fun calloutBubble(ctx: Context)   = if (dark(ctx)) Color.parseColor("#4F4F53") else Color.parseColor("#333333")
    fun popup(ctx: Context)           = if (dark(ctx)) Color.parseColor("#414144") else Color.parseColor("#F5F5F5")
    fun popupText(ctx: Context)       = if (dark(ctx)) Color.WHITE                else Color.parseColor("#1C1C1E")
    fun selectedItem()                = Color.parseColor("#007AFF")

    private fun dark(ctx: Context) =
        ctx.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
}
