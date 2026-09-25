package com.pauseapp.pause_mobile

import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.os.Bundle
import java.io.File
import com.dartnative.runtime.DartNativeActivity
import com.pauseapp.pause_mobile.guard.PauseGuardNotificationListenerService

class MainActivity : DartNativeActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // The native status bridge can be queried while Flutter/Dart is
        // building its first frame, before onResume is reached.
        activeInstance = this
        super.onCreate(savedInstanceState)
        receiveGuardHandoff(intent)
    }

    override fun onResume() {
        super.onResume()
        activeInstance = this
        refreshPauseGuardAccessStatus()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receiveGuardHandoff(intent)
    }

    override fun onDestroy() {
        if (activeInstance === this) activeInstance = null
        super.onDestroy()
    }

    private fun receiveGuardHandoff(intent: Intent?) {
        val intake = intent?.getStringExtra(GUARD_INTAKE_EXTRA)?.trim()
        if (intake.isNullOrEmpty()) return
        guardPreferences()?.edit()?.putString(GUARD_PENDING_INTAKE, intake)?.apply()
        intent.removeExtra(GUARD_INTAKE_EXTRA)
    }

    private fun guardPreferences() = File(applicationInfo.dataDir, "shared_prefs")
        .listFiles()
        ?.asSequence()
        ?.mapNotNull { it.name.removeSuffix(".xml").takeIf(String::isNotBlank) }
        ?.map { getSharedPreferences(it, Context.MODE_PRIVATE) }
        ?.firstOrNull { it.contains(GUARD_MODE) }

    companion object {
        const val GUARD_INTAKE_EXTRA = "pause.guard.intake"
        const val GUARD_MODE = "pause.guard.mode"
        const val GUARD_PENDING_INTAKE = "pause.guard.pending_intake"
        @Volatile private var activeInstance: MainActivity? = null

        /** Called through the small FFI bridge from the Dart Guard screen. */
        @JvmStatic
        fun openPauseGuardNotificationAccess(): Boolean {
            val activity = activeInstance ?: return false
            activity.runOnUiThread {
                val component = ComponentName(
                    activity,
                    PauseGuardNotificationListenerService::class.java,
                )
                val detailIntent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
                    .putExtra(
                        Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                        component.flattenToString(),
                    )
                val fallbackIntent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                try {
                    // The detail page exists from API 30. Older versions go to
                    // the system's listener list, where Pause is visible.
                    activity.startActivity(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            detailIntent
                        } else {
                            fallbackIntent
                        },
                    )
                } catch (_: ActivityNotFoundException) {
                    try {
                        activity.startActivity(fallbackIntent)
                    } catch (_: ActivityNotFoundException) {
                        return@runOnUiThread
                    }
                }
            }
            return true
        }

        @JvmStatic
        fun isPauseGuardNotificationAccessGranted(): Boolean {
            val activity = activeInstance ?: return false
            val listener = ComponentName(
                activity,
                PauseGuardNotificationListenerService::class.java,
            )
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                activity.getSystemService(NotificationManager::class.java)
                    .isNotificationListenerAccessGranted(listener)
            } else {
                Settings.Secure.getString(
                    activity.contentResolver,
                    "enabled_notification_listeners",
                )?.contains(listener.flattenToString()) == true
            }
        }

        private fun MainActivity.refreshPauseGuardAccessStatus() {
            val directory = File(applicationInfo.dataDir, "shared_prefs")
            val preferences = directory.listFiles()
                ?.asSequence()
                ?.mapNotNull { it.name.removeSuffix(".xml").takeIf(String::isNotBlank) }
                ?.map { getSharedPreferences(it, Context.MODE_PRIVATE) }
                ?.firstOrNull { it.contains("pause.guard.mode") }
                ?: return
            preferences.edit()
                .putString(
                    "pause.guard.notification_access_granted",
                    isPauseGuardNotificationAccessGranted().toString(),
                )
                .apply()
        }
    }
}
