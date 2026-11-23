package com.example.scrollbuddy.store

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager

object LauncherIcon {
    private val aliases = listOf("IconDefault", "IconTired", "IconCracking", "IconFried")

    @Volatile
    private var applied: String? = null

    fun mood(total: Int, limit: Int?): Int =
        if (limit != null && limit > 0) {
            val r = total.toDouble() / limit
            when {
                r >= 1.0 -> 3
                r >= 0.8 -> 2
                r >= 0.5 -> 1
                else -> 0
            }
        } else {
            when {
                total >= 200 -> 3
                total >= 100 -> 2
                total >= 50 -> 1
                else -> 0
            }
        }

    fun sync(context: Context) {
        val store = CounterStore.get(context)
        val wanted =
            if (!store.moodIcon()) "IconDefault"
            else aliases[mood(store.todayTotal(), store.limits().dailyLimit)]
        if (wanted == applied) return
        val pm = context.packageManager
        val pkg = context.packageName
        runCatching {
            pm.setComponentEnabledSetting(
                ComponentName(pkg, "$pkg.$wanted"),
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )
            for (alias in aliases) {
                if (alias == wanted) continue
                pm.setComponentEnabledSetting(
                    ComponentName(pkg, "$pkg.$alias"),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
            }
            applied = wanted
        }
    }
}
