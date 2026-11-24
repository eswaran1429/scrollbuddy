package com.example.scrollbuddy.overlay

import android.accessibilityservice.AccessibilityService
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Camera
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.annotation.SuppressLint
import android.view.MotionEvent
import android.widget.TextView
import com.example.scrollbuddy.R
import com.example.scrollbuddy.store.CounterStore
import com.example.scrollbuddy.store.LauncherIcon
import kotlin.math.abs

class CountBubble(private val service: AccessibilityService, private val store: CounterStore) {
    private val wm = service.getSystemService(WindowManager::class.java)
    private var view: FlipCounterView? = null
    private var params: WindowManager.LayoutParams? = null
    private var bubble: TextView? = null
    private val hideBubble = Runnable { removeBubble() }

    val isShown: Boolean get() = view != null

    fun show(count: Int) {
        if (view == null) attach()
        view?.setMood(mood(count))
        view?.setCount(count, animate = false)
    }

    fun update(count: Int) {
        val v = view ?: return
        val m = mood(count)
        v.setMood(m)
        v.setCount(count, animate = true)
        // While still healthy the logo cat reacts now and then: an eye-roll or yawn every
        // 10th reel, otherwise an occasional blink.
        if (m == 0) {
            when {
                count > 0 && count % 10 == 0 -> v.makeFace(if (count % 20 == 0) Face.YAWN else Face.EYEROLL, 1600)
                Math.random() < 0.3 -> v.makeFace(Face.BLINK, 260)
            }
        }
        val limit = store.limits().dailyLimit?.plus(store.bonusToday())
        val warn = limit != null && count >= limit - WARN_REELS && count < limit
        v.setWarning(warn)
        if (warn) v.shake()
        Milestones.lineFor(count, limit)?.let(::say)
    }

    private fun mood(count: Int) = LauncherIcon.mood(count, store.limits().dailyLimit)

    /** Short speech bubble above the counter (below it when there is no room), gone after a moment. */
    private fun say(text: String) {
        val v = view ?: return
        val p = params ?: return
        removeBubble()
        val density = service.resources.displayMetrics.density
        val tv = TextView(service).apply {
            this.text = text
            setTextColor(Color.rgb(255, 243, 224))
            textSize = 13f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            maxWidth = (240 * density).toInt()
            setPadding((12 * density).toInt(), (8 * density).toInt(), (12 * density).toInt(), (8 * density).toInt())
            background = GradientDrawable().apply {
                cornerRadius = 14 * density
                setColor(Color.rgb(58, 42, 92))
                setStroke((2 * density).toInt(), Color.rgb(150, 110, 230))
            }
            alpha = 0f
        }
        tv.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)
        val gap = (6 * density).toInt()
        val above = p.y - tv.measuredHeight - gap
        val bp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            x = p.x
            y = if (above >= statusBarHeight()) above else p.y + v.height + gap
        }
        runCatching { wm.addView(tv, bp) }.onSuccess {
            bubble = tv
            tv.animate().alpha(1f).setDuration(180).start()
            tv.postDelayed(hideBubble, BUBBLE_MS)
        }
    }

    private fun removeBubble() {
        bubble?.let {
            it.removeCallbacks(hideBubble)
            runCatching { wm.removeView(it) }
        }
        bubble = null
    }

    fun hide() {
        removeBubble()
        view?.let {
            it.stopAnimation()
            runCatching { wm.removeView(it) }
        }
        view = null
        params = null
    }

    private fun attach() {
        val v = FlipCounterView(service)
        val saved = store.overlayPosition()
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            x = saved?.first ?: 0
            y = saved?.second ?: (statusBarHeight() + v.dp(40f).toInt())
        }
        enableDrag(v, params)
        v.addOnLayoutChangeListener { _, l, _, r, _, ol, _, or, _ ->
            if (r - l != or - ol && view === v) {
                clamp(v, params)
                runCatching { wm.updateViewLayout(v, params) }
            }
        }
        wm.addView(v, params)
        view = v
        this.params = params
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun enableDrag(v: View, params: WindowManager.LayoutParams) {
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        v.setOnTouchListener { _, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = e.rawX
                    downY = e.rawY
                    startX = params.x
                    startY = params.y
                    v.animate().scaleX(1.06f).scaleY(1.06f).setDuration(120).start()
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = startX + (e.rawX - downX).toInt()
                    params.y = startY + (e.rawY - downY).toInt()
                    clamp(v, params)
                    runCatching { wm.updateViewLayout(v, params) }
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    v.animate().scaleX(1f).scaleY(1f).setDuration(120).start()
                    val moved = abs(e.rawX - downX) + abs(e.rawY - downY) > v.width * 0.05f
                    if (moved) store.saveOverlayPosition(params.x, params.y)
                }
            }
            true
        }
    }

    private fun clamp(v: View, params: WindowManager.LayoutParams) {
        val dm = service.resources.displayMetrics
        val maxX = ((dm.widthPixels - v.width) / 2).coerceAtLeast(0)
        params.x = params.x.coerceIn(-maxX, maxX)
        params.y = params.y.coerceIn(0, (dm.heightPixels - v.height).coerceAtLeast(0))
    }

    private fun statusBarHeight(): Int {
        val res = service.resources
        val id = res.getIdentifier("status_bar_height", "dimen", "android")
        return if (id > 0) res.getDimensionPixelSize(id) else (24 * res.displayMetrics.density).toInt()
    }

    private companion object {
        const val WARN_REELS = 10
        const val BUBBLE_MS = 2600L
    }
}

private enum class Face { BLINK, YAWN, EYEROLL }

private class FlipCounterView(context: Context) : View(context) {
    private val density = context.resources.displayMetrics.density
    fun dp(v: Float) = v * density

    private val tileW = dp(34f)
    private val tileH = dp(46f)
    private val gap = dp(6f)
    private val pad = dp(8f)
    private val frameRadius = dp(14f)
    private val tileRadius = dp(6f)
    private val catW = dp(54f)
    private val catOverlap = dp(13f)
    private val sparkRoom = dp(14f)

    // Logo while healthy, then the cat for today's mood. All are square, so the layout never changes.
    private val cats: List<Bitmap> = listOf(
        R.drawable.overlay_logo,
        R.drawable.overlay_tired,
        R.drawable.overlay_cracking,
        R.drawable.overlay_fried,
    ).map { BitmapFactory.decodeResource(context.resources, it) }
    private var cat: Bitmap = cats[0]
    private val catH = catW * cat.height / cat.width

    private val faces: Map<Face, Bitmap> = mapOf(
        Face.BLINK to R.drawable.overlay_blink,
        Face.YAWN to R.drawable.overlay_yawn,
        Face.EYEROLL to R.drawable.overlay_eyeroll,
    ).mapValues { BitmapFactory.decodeResource(context.resources, it.value) }

    /** Picture for the current mood; a face may cover it for a moment. */
    private var moodCat: Bitmap = cats[0]
    private val endFace = Runnable {
        cat = moodCat
        invalidate()
    }

    fun setMood(mood: Int) {
        val next = cats[mood.coerceIn(0, cats.lastIndex)]
        if (next === moodCat) return
        moodCat = next
        removeCallbacks(endFace)
        cat = next
        invalidate()
    }

    /** Shows [face] for [ms] milliseconds, then goes back to the mood picture. */
    fun makeFace(face: Face, ms: Long) {
        if (moodCat !== cats[0]) return
        removeCallbacks(endFace)
        cat = faces.getValue(face)
        invalidate()
        postDelayed(endFace, ms)
    }

    private var from = digitsOf(0)
    private var to = digitsOf(0)
    private var progress = 1f
    private var animator: ValueAnimator? = null

    private val framePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val frameStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = dp(2.5f)
        color = FRAME_EDGE
    }
    private val topPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = TILE_TOP }
    private val bottomPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = TILE_BOTTOM }
    private val hingePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = HINGE }
    private val notchPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = NOTCH }
    private val shadePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.BLACK }
    private val digitPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = DIGIT
        textSize = dp(32f)
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        textAlign = Paint.Align.CENTER
    }
    private val sparkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = dp(2.5f)
        strokeCap = Paint.Cap.ROUND
        color = YELLOW
    }
    private val bitmapPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)

    private var warning = false

    /** Amber frame in the last reels before the limit. */
    fun setWarning(on: Boolean) {
        if (on == warning) return
        warning = on
        frameStroke.color = if (on) AMBER else FRAME_EDGE
        invalidate()
    }

    fun shake() {
        animate().cancel()
        translationX = 0f
        val d = dp(6f)
        val steps = floatArrayOf(-d, d, -d * 0.6f, d * 0.6f, -d * 0.3f, 0f)
        fun step(i: Int) {
            if (i >= steps.size) return
            animate().translationX(steps[i]).setDuration(45).withEndAction { step(i + 1) }.start()
        }
        step(0)
    }

    private val camera = Camera()
    private val matrix = Matrix()
    private val rect = RectF()

    fun setCount(count: Int, animate: Boolean) {
        val next = digitsOf(count)
        contentDescription = "$count reels today"
        if (next.size != to.size || !animate) {
            stopAnimation()
            from = next
            to = next
            progress = 1f
            requestLayout()
            invalidate()
            return
        }
        if (next.contentEquals(to)) return
        stopAnimation()
        from = to
        to = next
        progress = 0f
        animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = FLIP_MS
            interpolator = AccelerateDecelerateInterpolator()
            addUpdateListener {
                progress = it.animatedValue as Float
                invalidate()
            }
            start()
        }
    }

    fun stopAnimation() {
        removeCallbacks(endFace)
        cat = moodCat
        animator?.cancel()
        animator = null
        from = to
        progress = 1f
    }

    private fun frameWidth() = to.size * tileW + (to.size - 1) * gap + pad * 2

    private fun frameHeight() = tileH + pad * 2

    private fun catTopRoom() = catH - catOverlap

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val w = frameWidth() + sparkRoom * 2
        val h = catTopRoom() + frameHeight() + dp(2f)
        setMeasuredDimension(w.toInt(), h.toInt())
    }

    override fun onDraw(canvas: Canvas) {
        val left = (width - frameWidth()) / 2f
        val top = catTopRoom()

        rect.set(left, top, left + frameWidth(), top + frameHeight())
        framePaint.shader = LinearGradient(0f, rect.top, 0f, rect.bottom, FRAME_TOP, FRAME_BOTTOM, Shader.TileMode.CLAMP)
        canvas.drawRoundRect(rect, frameRadius, frameRadius, framePaint)
        canvas.drawRoundRect(rect, frameRadius, frameRadius, frameStroke)

        for (i in to.indices) {
            val tl = left + pad + i * (tileW + gap)
            drawTile(canvas, RectF(tl, top + pad, tl + tileW, top + pad + tileH), from[i], to[i])
        }

        val cx = width / 2f
        rect.set(cx - catW / 2, 0f, cx + catW / 2, catH)
        canvas.drawBitmap(cat, null, rect, bitmapPaint)

        val sx = cx + catW * 0.42f
        val sy = catH * 0.22f
        canvas.drawLine(sx, sy, sx + dp(3f), sy - dp(7f), sparkPaint)
        canvas.drawLine(sx + dp(6f), sy + dp(4f), sx + dp(12f), sy - dp(1f), sparkPaint)
        canvas.drawLine(sx + dp(8f), sy + dp(11f), sx + dp(15f), sy + dp(10f), sparkPaint)
    }

    private fun drawTile(canvas: Canvas, tile: RectF, old: Char, new: Char) {
        val hinge = tile.centerY()
        if (old == new || progress >= 1f) {
            drawHalf(canvas, tile, new, top = true)
            drawHalf(canvas, tile, new, top = false)
        } else {
            drawHalf(canvas, tile, new, top = true)
            drawHalf(canvas, tile, old, top = false)
            if (progress < 0.5f) {
                val angle = progress * 2 * 90f
                drawFlap(canvas, tile, old, top = true, angle = -angle)
            } else {
                val angle = (1 - progress) * 2 * 90f
                drawFlap(canvas, tile, new, top = false, angle = angle)
            }
        }
        canvas.drawRect(tile.left, hinge - dp(1f), tile.right, hinge + dp(1f), hingePaint)
        canvas.drawRect(tile.left - dp(3f), hinge - dp(3f), tile.left + dp(1f), hinge + dp(3f), notchPaint)
        canvas.drawRect(tile.right - dp(1f), hinge - dp(3f), tile.right + dp(3f), hinge + dp(3f), notchPaint)
    }

    private fun drawHalf(canvas: Canvas, tile: RectF, digit: Char, top: Boolean) {
        val hinge = tile.centerY()
        canvas.save()
        if (top) canvas.clipRect(tile.left, tile.top, tile.right, hinge) else canvas.clipRect(tile.left, hinge, tile.right, tile.bottom)
        canvas.drawRoundRect(tile, tileRadius, tileRadius, if (top) topPaint else bottomPaint)
        val baseline = tile.centerY() - (digitPaint.descent() + digitPaint.ascent()) / 2
        canvas.drawText(digit.toString(), tile.centerX(), baseline, digitPaint)
        canvas.restore()
    }

    private fun drawFlap(canvas: Canvas, tile: RectF, digit: Char, top: Boolean, angle: Float) {
        val hinge = tile.centerY()
        camera.save()
        camera.rotateX(angle)
        camera.getMatrix(matrix)
        camera.restore()
        matrix.preTranslate(-tile.centerX(), -hinge)
        matrix.postTranslate(tile.centerX(), hinge)
        canvas.save()
        canvas.concat(matrix)
        drawHalf(canvas, tile, digit, top)
        shadePaint.alpha = (kotlin.math.abs(angle) / 90f * 120).toInt()
        if (top) canvas.clipRect(tile.left, tile.top, tile.right, hinge) else canvas.clipRect(tile.left, hinge, tile.right, tile.bottom)
        canvas.drawRoundRect(tile, tileRadius, tileRadius, shadePaint)
        canvas.restore()
    }

    private companion object {
        const val FLIP_MS = 320L
        const val MIN_DIGITS = 2

        fun digitsOf(count: Int): CharArray = count.coerceAtLeast(0).toString().padStart(MIN_DIGITS, '0').toCharArray()

        val FRAME_TOP = Color.rgb(58, 42, 92)
        val FRAME_BOTTOM = Color.rgb(38, 28, 62)
        val FRAME_EDGE = Color.rgb(150, 110, 230)
        val TILE_TOP = Color.rgb(78, 68, 100)
        val TILE_BOTTOM = Color.rgb(66, 57, 88)
        val HINGE = Color.rgb(30, 24, 44)
        val NOTCH = Color.rgb(120, 110, 150)
        val DIGIT = Color.rgb(255, 243, 224)
        val YELLOW = Color.rgb(245, 185, 33)
        val AMBER = Color.rgb(245, 165, 36)
    }
}
