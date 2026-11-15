package com.example.scrollbuddy.store

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONObject
import java.time.LocalDate
import java.util.concurrent.CopyOnWriteArraySet

class CounterStore private constructor(context: Context) :
    SQLiteOpenHelper(context, "scrollbuddy.db", null, 2) {

    fun interface Listener {
        fun onTodayChanged(today: Map<String, Int>)
    }

    private val listeners = CopyOnWriteArraySet<Listener>()

    private data class ServiceSettings(
        val trackedApps: Set<String>,
        val showOverlay: Boolean,
        val overlayAfter: Int = 0,
        val limits: Limits = Limits(),
    )

    @Volatile
    private var cache: ServiceSettings? = null

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE daily_counts (local_date TEXT NOT NULL, app_key TEXT NOT NULL, " +
                "count INTEGER NOT NULL, PRIMARY KEY (local_date, app_key))",
        )
        db.execSQL("CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
        createSecondsTable(db)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) createSecondsTable(db)
    }

    private fun createSecondsTable(db: SQLiteDatabase) = db.execSQL(
        "CREATE TABLE daily_seconds (local_date TEXT NOT NULL, app_key TEXT NOT NULL, " +
            "seconds INTEGER NOT NULL, PRIMARY KEY (local_date, app_key))",
    )

    fun addListener(l: Listener) = listeners.add(l)

    fun removeListener(l: Listener) = listeners.remove(l)

    fun increment(appKey: String, by: Int = 1) {
        addToday("daily_counts", "count", appKey, by)
        notifyListeners()
    }

    fun addSeconds(appKey: String, seconds: Int) {
        addToday("daily_seconds", "seconds", appKey, seconds)
        notifyListeners()
    }

    private fun addToday(table: String, column: String, appKey: String, by: Int) {
        val date = today()
        val db = writableDatabase
        db.beginTransaction()
        try {
            val update = db.compileStatement(
                "UPDATE $table SET $column = $column + ? WHERE local_date = ? AND app_key = ?",
            )
            update.bindLong(1, by.toLong())
            update.bindString(2, date)
            update.bindString(3, appKey)
            if (update.executeUpdateDelete() == 0) {
                db.insert(
                    table,
                    null,
                    ContentValues().apply {
                        put("local_date", date)
                        put("app_key", appKey)
                        put(column, by)
                    },
                )
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    fun countsFor(date: String): Map<String, Int> = perApp("daily_counts", "count", date)

    fun secondsFor(date: String): Map<String, Int> = perApp("daily_seconds", "seconds", date)

    private fun perApp(table: String, column: String, date: String): Map<String, Int> {
        val out = mutableMapOf<String, Int>()
        readableDatabase.rawQuery("SELECT app_key, $column FROM $table WHERE local_date = ?", arrayOf(date)).use { c ->
            while (c.moveToNext()) out[c.getString(0)] = c.getInt(1)
        }
        return out
    }

    fun todayCounts(): Map<String, Int> = countsFor(today())

    fun todayTotal(): Int = todayCounts().values.sum()

    fun history(days: Int): List<Pair<String, Map<String, Int>>> {
        val today = LocalDate.now()
        val from = today.minusDays(days.toLong()).toString()
        val byDate = mutableMapOf<String, MutableMap<String, Int>>()
        readableDatabase.rawQuery(
            "SELECT local_date, app_key, count FROM daily_counts WHERE local_date >= ? AND local_date < ?",
            arrayOf(from, today.toString()),
        ).use { c ->
            while (c.moveToNext()) byDate.getOrPut(c.getString(0)) { mutableMapOf() }[c.getString(1)] = c.getInt(2)
        }
        return (days downTo 1).map { i ->
            val d = today.minusDays(i.toLong()).toString()
            d to (byDate[d] ?: emptyMap())
        }
    }

    fun resetToday() {
        writableDatabase.delete("daily_counts", "local_date = ?", arrayOf(today()))
        writableDatabase.delete("daily_seconds", "local_date = ?", arrayOf(today()))
        notifyListeners()
    }

    fun deleteAll() {
        writableDatabase.delete("daily_counts", null, null)
        writableDatabase.delete("daily_seconds", null, null)
        writableDatabase.delete("settings", null, null)
        cache = null
        notifyListeners()
    }

    fun settingsJson(): String? =
        readableDatabase.rawQuery("SELECT value FROM settings WHERE key = ?", arrayOf(SETTINGS_KEY)).use { c ->
            if (c.moveToFirst()) c.getString(0) else null
        }

    fun saveSettingsJson(json: String) {
        writableDatabase.insertWithOnConflict(
            "settings",
            null,
            ContentValues().apply {
                put("key", SETTINGS_KEY)
                put("value", json)
            },
            SQLiteDatabase.CONFLICT_REPLACE,
        )
        cache = null
    }

    fun overlayPosition(): Pair<Int, Int>? {
        val raw = readableDatabase.rawQuery("SELECT value FROM settings WHERE key = ?", arrayOf(OVERLAY_POS_KEY)).use { c ->
            if (c.moveToFirst()) c.getString(0) else null
        } ?: return null
        val parts = raw.split(",").mapNotNull { it.toIntOrNull() }
        return if (parts.size == 2) parts[0] to parts[1] else null
    }

    fun saveOverlayPosition(x: Int, y: Int) {
        writableDatabase.insertWithOnConflict(
            "settings",
            null,
            ContentValues().apply {
                put("key", OVERLAY_POS_KEY)
                put("value", "$x,$y")
            },
            SQLiteDatabase.CONFLICT_REPLACE,
        )
    }

    fun trackedApps(): Set<String> = serviceSettings().trackedApps

    fun showOverlay(): Boolean = serviceSettings().showOverlay

    fun overlayAfter(): Int = serviceSettings().overlayAfter

    fun limits(): Limits = serviceSettings().limits

    fun bonusToday(): Int =
        readableDatabase.rawQuery("SELECT value FROM settings WHERE key = ?", arrayOf(bonusKey())).use { c ->
            if (c.moveToFirst()) c.getString(0).toIntOrNull() ?: 0 else 0
        }

    fun addBonus(reels: Int) {
        val limit = limits().dailyLimit
        val over = if (limit == null) 0 else todayTotal() - limit
        val next = maxOf(bonusToday(), over) + reels
        writableDatabase.insertWithOnConflict(
            "settings",
            null,
            ContentValues().apply {
                put("key", bonusKey())
                put("value", next.toString())
            },
            SQLiteDatabase.CONFLICT_REPLACE,
        )
    }

    private fun bonusKey() = "bonus_${today()}"

    private fun serviceSettings(): ServiceSettings = cache ?: parse(settingsJson()).also { cache = it }

    private fun parse(json: String?): ServiceSettings {
        val obj = json?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return ServiceSettings(ALL_APPS, true)
        val arr = obj.optJSONArray("trackedApps")
        val tracked = if (arr == null) ALL_APPS else (0 until arr.length()).map { arr.getString(it) }.toSet()
        val limits = Limits(
            dailyLimit = if (obj.isNull("dailyLimit")) null else obj.optInt("dailyLimit"),
        )
        return ServiceSettings(tracked, obj.optBoolean("showOverlay", true), obj.optInt("overlayAfter", 0), limits)
    }

    private fun notifyListeners() {
        if (listeners.isEmpty()) return
        val today = todayCounts()
        listeners.forEach { it.onTodayChanged(today) }
    }

    companion object {
        private const val SETTINGS_KEY = "app_settings"
        private const val OVERLAY_POS_KEY = "overlay_position"
        private val ALL_APPS = setOf("instagram", "youtube", "facebook", "snapchat")

        @Volatile
        private var instance: CounterStore? = null

        fun get(context: Context): CounterStore =
            instance ?: synchronized(this) {
                instance ?: CounterStore(context.applicationContext).also { instance = it }
            }

        fun today(): String = LocalDate.now().toString()
    }
}
