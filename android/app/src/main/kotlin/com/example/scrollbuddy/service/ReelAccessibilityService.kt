package com.example.scrollbuddy.service

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.example.scrollbuddy.MainActivity
import com.example.scrollbuddy.detect.AdLabel
import com.example.scrollbuddy.detect.AppSelectors
import com.example.scrollbuddy.detect.EventSnapshot
import com.example.scrollbuddy.detect.ReelDetector
import com.example.scrollbuddy.detect.Selectors
import com.example.scrollbuddy.detect.WatchTimer
import com.example.scrollbuddy.overlay.CountBubble
import com.example.scrollbuddy.store.CounterStore
import com.example.scrollbuddy.store.LauncherIcon

class ReelAccessibilityService : AccessibilityService() {
    private lateinit var store: CounterStore
    private val detectors = mutableMapOf<String, ReelDetector>()

    private var currentPackage: String? = null
    private var inViewer = false
    private var lastViewerCheck = 0L

    private lateinit var bubble: CountBubble
    private val main = Handler(Looper.getMainLooper())

    private val timer = WatchTimer()
    private var watching = false
    private var missedWindows = 0
    private val viewerWatch = object : Runnable {
        override fun run() {
            if (!inViewer) return syncWatch()
            if (!getSystemService(PowerManager::class.java).isInteractive) {
                inViewer = false
                bubble.hide()
                return syncWatch()
            }
            val root = rootInActiveWindow
            val pkg = root?.packageName?.toString()
            val app = if (pkg != null && pkg == currentPackage) Selectors.byPackage[pkg] else null
            missedWindows = if (root == null) missedWindows + 1 else 0
            val stillInViewer = when {
                root == null -> missedWindows < 2
                app == null -> {
                    release(root)
                    false
                }
                else -> isReelsViewer(root, app)
            }
            if (!stillInViewer) {
                if (pkg != currentPackage) currentPackage = null
                inViewer = false
                bubble.hide()
                syncWatch()
            } else {
                currentPackage?.let { key -> Selectors.byPackage[key]?.let { saveTime(timer.tick(it.key, SystemClock.uptimeMillis())) } }
                main.postDelayed(this, LEAVE_CHECK_MS)
            }
        }
    }

    private fun syncWatch(now: Long = SystemClock.uptimeMillis()) {
        val app = currentPackage?.let { Selectors.byPackage[it] }
        if (inViewer && app != null) {
            saveTime(timer.tick(app.key, now))
            if (!watching) {
                watching = true
                main.postDelayed(viewerWatch, LEAVE_CHECK_MS)
            }
        } else {
            detectors.values.forEach { it.leftViewer() }
            saveTime(timer.stop(now))
            LauncherIcon.sync(this)
            watching = false
            main.removeCallbacks(viewerWatch)
        }
    }

    private fun saveTime(entry: Pair<String, Int>?) {
        entry?.let { (key, seconds) -> store.addSeconds(key, seconds) }
    }

    private var debugLog = false

    override fun onServiceConnected() {
        store = CounterStore.get(this)
        debugLog = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        bubble = CountBubble(this, store)
        LauncherIcon.sync(this)
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        inViewer = false
        if (::store.isInitialized) syncWatch()
        if (::bubble.isInitialized) bubble.hide()
        return super.onUnbind(intent)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (!::store.isInitialized) return
        val app = Selectors.byPackage[event.packageName?.toString() ?: return] ?: return
        if (app.key !in store.trackedApps()) {
            bubble.hide()
            return
        }

        val now = SystemClock.uptimeMillis()
        if (app.packageName != currentPackage) {
            currentPackage = app.packageName
            inViewer = false
            lastViewerCheck = 0
        }
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED || now - lastViewerCheck > VIEWER_CHECK_MS) {
            val was = inViewer
            inViewer = rootInActiveWindow?.let { isReelsViewer(it, app) } ?: false
            if (debugLog && was != inViewer) Log.d(TAG, "${app.key} inViewer=$inViewer")
            lastViewerCheck = now
            updateBubble()
            syncWatch(now)
            if (inViewer) maybeBlock(app.key, now)
        }

        if (app.probePagerIndex) {
            onProbeEvent(app, now)
            return
        }

        val isScroll = event.eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED
        val sourceId = if (isScroll) event.source?.let { node -> node.viewIdResourceName.also { release(node) } } else null
        val snapshot = EventSnapshot(
            isScroll = isScroll,
            sourceViewId = sourceId,
            fromIndex = event.fromIndex,
            toIndex = event.toIndex,
            inViewer = inViewer,
            timeMs = now,
            horizontal = isScroll && isHorizontal(event),
        )
        if (debugLog && (isScroll || event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)) {
            Log.d(
                TAG,
                "${app.key} type=${AccessibilityEvent.eventTypeToString(event.eventType)} src=$sourceId " +
                    "class=${event.className} from=${event.fromIndex} to=${event.toIndex} items=${event.itemCount} " +
                    "horizontal=${snapshot.horizontal} " +
                    "inViewer=$inViewer",
            )
        }
        if (detectors.getOrPut(app.key) { ReelDetector(app) }.onEvent(snapshot)) {
            countUnlessAd(app.key)
        }
    }

    private var lastProbe = 0L

    private fun onProbeEvent(app: AppSelectors, now: Long) {
        val detector = detectors.getOrPut(app.key) { ReelDetector(app) }
        if (!inViewer) {
            detector.onEvent(EventSnapshot(false, null, -1, -1, inViewer = false, timeMs = now))
            return
        }
        if (now - lastProbe < PROBE_MS) return
        lastProbe = now
        val index = rootInActiveWindow?.let { root -> centeredRowIndex(root, app).also { release(root) } } ?: -1
        if (debugLog) Log.d(TAG, "${app.key} probe rowIndex=$index")
        if (index < 0) return
        val snapshot = EventSnapshot(
            isScroll = true,
            sourceViewId = app.pagerIds.firstOrNull(),
            fromIndex = index,
            toIndex = index,
            inViewer = true,
            timeMs = now,
        )
        if (detector.onEvent(snapshot)) {
            countUnlessAd(app.key)
        }
    }

    private fun countUnlessAd(appKey: String) {
        main.postDelayed({
            if (inViewer && adOnScreen()) {
                if (debugLog) Log.d(TAG, "$appKey ad skipped")
                return@postDelayed
            }
            store.increment(appKey)
            LauncherIcon.sync(this)
            updateBubble()
            bubble.update(store.todayTotal())
            maybeBlock(appKey, SystemClock.uptimeMillis())
        }, AD_CHECK_DELAY_MS)
    }

    private fun adOnScreen(): Boolean {
        val root = rootInActiveWindow ?: return false
        val height = resources.displayMetrics.heightPixels
        val bounds = android.graphics.Rect()
        var found = false
        for (word in AdLabel.searchWords) {
            for (node in root.findAccessibilityNodeInfosByText(word)) {
                if (!found && node.isVisibleToUser && (AdLabel.matches(node.text) || AdLabel.matches(node.contentDescription))) {
                    node.getBoundsInScreen(bounds)
                    found = bounds.bottom > 0 && bounds.top < height
                }
                release(node)
            }
            if (found) break
        }
        release(root)
        return found
    }

    private fun centeredRowIndex(root: AccessibilityNodeInfo, app: AppSelectors): Int {
        val centerY = resources.displayMetrics.heightPixels / 2
        val centerX = resources.displayMetrics.widthPixels / 2
        val bounds = android.graphics.Rect()
        var result = -1
        for (pagerId in app.pagerIds) {
            val pagers = root.findAccessibilityNodeInfosByViewId("${app.packageName}:id/$pagerId")
            for (pager in pagers) {
                if (result < 0 && pager.isVisibleToUser) {
                    for (i in 0 until pager.childCount) {
                        val child = pager.getChild(i) ?: continue
                        child.getBoundsInScreen(bounds)
                        if (result < 0 && bounds.contains(centerX, centerY)) {
                            result = child.collectionItemInfo?.rowIndex ?: -1
                        }
                        release(child)
                    }
                }
                release(pager)
            }
            if (result >= 0) break
        }
        return result
    }

    private fun isHorizontal(event: AccessibilityEvent): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val dx = kotlin.math.abs(event.scrollDeltaX)
        val dy = kotlin.math.abs(event.scrollDeltaY)
        return dx > 0 && dx > dy
    }

    private var lastBlock = 0L

    private fun maybeBlock(appKey: String, now: Long) {
        if (now - lastBlock < BLOCK_COOLDOWN_MS) return
        if (!store.limits().reached(store.todayCounts(), store.bonusToday())) return
        lastBlock = now
        if (debugLog) Log.d(TAG, "$appKey limit reached, blocking")
        inViewer = false
        bubble.hide()
        syncWatch(now)
        performGlobalAction(GLOBAL_ACTION_BACK)
        main.postDelayed({
            startActivity(
                Intent(this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    .putExtra(MainActivity.EXTRA_BLOCK, true),
            )
        }, 250)
    }

    private fun updateBubble() {
        if (inViewer && store.showOverlay() && store.todayTotal() >= store.overlayAfter()) {
            if (!bubble.isShown) bubble.show(store.todayTotal())
        } else {
            bubble.hide()
        }
    }

    override fun onInterrupt() {
        inViewer = false
        if (::store.isInitialized) syncWatch()
        if (::bubble.isInitialized) bubble.hide()
    }

    private fun isReelsViewer(root: AccessibilityNodeInfo, app: AppSelectors): Boolean {
        val queue = ArrayDeque<AccessibilityNodeInfo>().apply { add(root) }
        var visited = 0
        var found = false
        while (queue.isNotEmpty()) {
            val node = queue.removeFirst()
            if (!found && visited < MAX_NODES && node.isVisibleToUser) {
                visited++
                val id = node.viewIdResourceName
                if (debugLog && id != null) seenIds.add(id.substringAfter(":id/"))
                val desc = node.contentDescription?.toString()
                val matches = (id != null && app.viewerIds.any { id.contains(it) }) ||
                    (desc != null && app.viewerDescriptions.any { desc.contains(it, ignoreCase = true) })
                found = matches && fillsScreen(node)
                if (!found) {
                    for (i in 0 until node.childCount) node.getChild(i)?.let(queue::add)
                }
            }
            release(node)
        }
        if (debugLog && !found) Log.d(TAG, "${app.key} viewer not found, visited=$visited ids=${seenIds.take(80)}")
        seenIds.clear()
        return found
    }

    private val seenIds = linkedSetOf<String>()

    private val viewerBounds = android.graphics.Rect()

    private fun fillsScreen(node: AccessibilityNodeInfo): Boolean {
        node.getBoundsInScreen(viewerBounds)
        return viewerBounds.height() >= resources.displayMetrics.heightPixels * MIN_VIEWER_HEIGHT
    }

    @Suppress("DEPRECATION")
    private fun release(node: AccessibilityNodeInfo) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) node.recycle()
    }

    private companion object {
        const val VIEWER_CHECK_MS = 500L
        const val MAX_NODES = 400
        const val LEAVE_CHECK_MS = 1000L
        const val PROBE_MS = 250L
        const val AD_CHECK_DELAY_MS = 700L
        const val BLOCK_COOLDOWN_MS = 3000L
        const val MIN_VIEWER_HEIGHT = 0.6f
        const val TAG = "ScrollBuddy"
    }
}
