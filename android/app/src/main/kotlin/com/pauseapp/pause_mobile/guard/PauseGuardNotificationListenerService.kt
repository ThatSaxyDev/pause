package com.pauseapp.pause_mobile.guard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat
import com.pauseapp.pause_mobile.MainActivity
import com.pauseapp.pause_mobile.R
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * Android's process may create this service while the Dart runtime is not
 * running. It reads only notification fields exposed by Android, redacts them
 * before the optional backend analysis, and never opens a notification's
 * links.
 */
class PauseGuardNotificationListenerService : NotificationListenerService() {
    override fun onListenerConnected() {
        super.onListenerConnected()
        preferences()?.edit()
            ?.putLong(LISTENER_CONNECTED_AT, System.currentTimeMillis())
            ?.putString(NOTIFICATION_ACCESS_GRANTED, "true")
            ?.apply()
    }

    override fun onListenerDisconnected() {
        // Keep the app UI honest when the user revokes Notification access in
        // Android Settings while Pause is not in the foreground.
        preferences()?.edit()
            ?.remove(LISTENER_CONNECTED_AT)
            ?.putString(NOTIFICATION_ACCESS_GRANTED, "false")
            ?.apply()
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)
        if (sbn.packageName == packageName) return

        val preferences = preferences() ?: return
        if (preferences.getString(MODE, MODE_OFF) != MODE_LOCAL_ONLY) return
        val sourceApps = (preferences.getString(SOURCES, "") ?: "")
            .split(',')
            .filter { it.isNotBlank() }
            .toSet()
        if (sbn.packageName !in sourceApps) return

        val text = notificationText(sbn.notification).take(MAX_SOURCE_CHARS)
        if (text.isBlank()) return
        val redacted = redact(text)
        if (wasRecentlyProcessed(preferences, sbn.packageName, redacted)) return

        val localFinding = inspect(redacted)
        if (localFinding != null) {
            // This is bounded, deterministic work. Commit the user-visible
            // record before Android can defer the service process.
            recordActivity(preferences, sbn.packageName, localFinding)
            postWarning(localFinding, redacted)
            analysisExecutor.execute { analyseWithPauseApi(redacted) }
            return
        }

        // Notification callbacks must return promptly. The network request
        // reaches the same hosted analysis pipeline used by Check, including
        // TypeSafe/Jev enrichment, with only the redacted preview.
        analysisExecutor.execute {
            val remoteFinding = analyseWithPauseApi(redacted)
            val finding = remoteFinding ?: return@execute
            recordActivity(preferences, sbn.packageName, finding)
            postWarning(finding, redacted)
        }
    }

    private fun notificationText(notification: Notification): String {
        val extras = notification.extras ?: return ""
        val values = buildList {
            extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.let(::add)
            extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.let(::add)
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.let(::add)
            extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
                ?.map(CharSequence::toString)?.forEach(::add)
        }
        return values.distinct().joinToString("\n")
    }

    private fun redact(value: String): String = value
        .replace(OTP_PATTERN, "[one-time code removed]")
        .replace(ACCOUNT_PATTERN, "[account number removed]")
        .replace(CARD_PATTERN, "[card number removed]")

    /** Intentionally high threshold for the first local-only beta. */
    private fun inspect(value: String): Finding? {
        val urls = URL_PATTERN.findAll(value).map { trimUrl(it.value) }.filter { it.isNotEmpty() }.toList()
        if (urls.isEmpty()) return null
        for (url in urls) {
            val host = hostOf(url) ?: continue
            if (host.startsWith("xn--") || host.contains(".xn--")) {
                return Finding("idn", "This link uses an internationalised address. Check the official website independently.")
            }
            if (IP_HOST_PATTERN.matches(host)) {
                return Finding("ip-host", "This link uses a numeric address instead of a normal website name. Do not open it from the message.")
            }
            if (host.contains("frsc", ignoreCase = true) && !host.endsWith("frsc.gov.ng")) {
                return Finding("frsc-domain", "This link appears to mention FRSC but does not use frsc.gov.ng. Verify through the official site.")
            }
        }
        return null
    }

    private fun hostOf(value: String): String? = try {
        val normalised = if (value.contains("://")) value else "https://$value"
        URI(normalised).host?.lowercase()?.trimEnd('.')
    } catch (_: Exception) {
        null
    }

    private fun trimUrl(value: String): String = value.trimEnd('.', ',', ';', ':', '!', '?', ')', ']', '}', '\'', '"')

    private fun wasRecentlyProcessed(
        preferences: SharedPreferences,
        sourcePackage: String,
        text: String,
    ): Boolean {
        val digest = MessageDigest.getInstance("SHA-256")
            .digest("$sourcePackage|$text".toByteArray())
            .joinToString("") { "%02x".format(it) }
        val key = "$FINGERPRINT_PREFIX$digest"
        val now = System.currentTimeMillis()
        clearExpiredFingerprints(preferences, now)
        val previous = preferences.getLong(key, 0L)
        preferences.edit().putLong(key, now).apply()
        return previous > 0L && now - previous < DEDUPE_WINDOW_MS
    }

    private fun clearExpiredFingerprints(preferences: SharedPreferences, now: Long) {
        val editor = preferences.edit()
        var hasExpired = false
        preferences.all.forEach { (key, value) ->
            if (key.startsWith(FINGERPRINT_PREFIX) && value is Long && now - value >= DEDUPE_WINDOW_MS) {
                editor.remove(key)
                hasExpired = true
            }
        }
        if (hasExpired) editor.apply()
    }

    private fun analyseWithPauseApi(value: String): Finding? {
        var connection: HttpURLConnection? = null
        return try {
            connection = (URL(ANALYSIS_ENDPOINT).openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = CONNECT_TIMEOUT_MS
                readTimeout = READ_TIMEOUT_MS
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Accept", "application/json")
            }
            val payload = JSONObject()
                .put("input", JSONObject().put("type", "text").put("value", value))
                // The deployed API currently accepts this existing source
                // value. The payload is otherwise identical to Check.
                .put("context", JSONObject().put("source", "paste").put("locale", "en-NG"))
            connection.outputStream.bufferedWriter().use { it.write(payload.toString()) }
            if (connection.responseCode != HttpURLConnection.HTTP_OK) return null

            val response = connection.inputStream.bufferedReader().use { it.readText() }
            val risk = JSONObject(response).getJSONObject("risk")
            val level = risk.optString("level")
            if (level != "high" && level != "caution") return null
            Finding(
                key = "api-$level",
                message = risk.optString(
                    "guidance",
                    "A Pause check found warning signs. Review the result before you act.",
                ),
            )
        } catch (_: Exception) {
            // A deterministic local finding still produces a useful warning
            // when the device is offline or the API is temporarily unavailable.
            null
        } finally {
            connection?.disconnect()
        }
    }

    private fun postWarning(finding: Finding, redactedIntake: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    WARNING_CHANNEL,
                    "Pause Guard warnings",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Private safety warnings from Pause Guard"
                    setShowBadge(false)
                },
            )
        }
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("pause.guard.warning", finding.key)
            putExtra(MainActivity.GUARD_INTAKE_EXTRA, redactedIntake)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            finding.key.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, WARNING_CHANNEL)
            .setSmallIcon(R.drawable.notification_icon)
            .setColor(getColor(R.color.notification_color))
            .setContentTitle("Pause before you tap")
            .setContentText(finding.message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(finding.message))
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .build()
        manager.notify((finding.key + System.currentTimeMillis() / DEDUPE_WINDOW_MS).hashCode(), notification)
    }

    /** Keeps a small audit trail without storing notification contents. */
    private fun recordActivity(
        preferences: SharedPreferences,
        sourcePackage: String,
        finding: Finding,
    ) {
        val existing = try {
            JSONArray(preferences.getString(ACTIVITY, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        val records = JSONArray()
        records.put(
            JSONObject()
                .put("timestamp", System.currentTimeMillis())
                .put("source", sourceLabel(sourcePackage))
                .put("outcome", if (finding.key == "api-caution") "Caution" else "Warning")
                .put("signal", signalLabel(finding.key)),
        )
        for (index in 0 until minOf(existing.length(), MAX_ACTIVITY - 1)) {
            records.put(existing.getJSONObject(index))
        }
        preferences.edit().putString(ACTIVITY, records.toString()).apply()
    }

    private fun sourceLabel(packageName: String): String = when (packageName) {
        "com.google.android.apps.messaging" -> "Messages"
        "com.android.mms" -> "SMS messages"
        "com.whatsapp" -> "WhatsApp"
        "com.google.android.gm" -> "Gmail"
        else -> "An app"
    }

    private fun signalLabel(key: String): String = when (key) {
        "frsc-domain" -> "FRSC lookalike"
        "ip-host" -> "Numeric web address"
        "idn" -> "Unusual web address"
        else -> "Suspicious link"
    }

    /**
     * DartNative's preference implementation is platform-owned. Resolve the
     * store that contains the Guard mode rather than hard-coding its filename.
     */
    private fun preferences(): SharedPreferences? {
        val directory = File(applicationInfo.dataDir, "shared_prefs")
        val names = directory.listFiles()
            ?.mapNotNull { it.name.removeSuffix(".xml").takeIf(String::isNotBlank) }
            .orEmpty()
        return names.asSequence()
            .map { getSharedPreferences(it, Context.MODE_PRIVATE) }
            .firstOrNull { it.contains(MODE) }
    }

    private data class Finding(val key: String, val message: String)

    private companion object {
        const val MODE = "pause.guard.mode"
        const val SOURCES = "pause.guard.sources"
        const val LISTENER_CONNECTED_AT = "pause.guard.listener_connected_at"
        const val NOTIFICATION_ACCESS_GRANTED = "pause.guard.notification_access_granted"
        const val MODE_OFF = "off"
        const val MODE_LOCAL_ONLY = "local_only"
        const val WARNING_CHANNEL = "pause_guard_warnings"
        const val ACTIVITY = "pause.guard.activity"
        const val FINGERPRINT_PREFIX = "pause.guard.fingerprint."
        const val DEDUPE_WINDOW_MS = 5 * 60 * 1000L
        const val ANALYSIS_ENDPOINT = "https://pause-api.kiishi.space/v1/analyses"
        const val CONNECT_TIMEOUT_MS = 8_000
        const val READ_TIMEOUT_MS = 12_000
        const val MAX_SOURCE_CHARS = 1200
        const val MAX_ACTIVITY = 20
        val analysisExecutor = Executors.newSingleThreadExecutor()
        val URL_PATTERN = Regex("(?i)(?:https?://|www\\.)[^\\s<>()]+|(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,63}(?:/[^\\s<>()]*)?")
        val OTP_PATTERN = Regex("(?i)\\b(?:otp|one[- ]?time(?:[ -]?pass(?:word|code))?|verification[ -]?code|security[ -]?code|pin)\\s*(?:is|:|=|-)?\\s*\\d{4,8}\\b")
        val ACCOUNT_PATTERN = Regex("(?i)\\b(?:account(?:\\s+number)?|acct)\\s*(?:is|:|=|-)?\\s*\\d{8,18}\\b")
        val CARD_PATTERN = Regex("\\b(?:\\d[ -]?){13,19}\\b")
        val IP_HOST_PATTERN = Regex("(?:\\d{1,3}\\.){3}\\d{1,3}")
    }
}
