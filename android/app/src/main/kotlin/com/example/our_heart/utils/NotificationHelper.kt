// android/app/src/main/kotlin/com/example/ourheart/utils/NotificationHelper.kt

package com.example.our_heart.utils

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.example.our_heart.MainActivity
import com.example.our_heart.R

/**
 * Creates the silent, non‑dismissible notification channel for the
 * relationship counter foreground service, and builds the persistent
 * notification that displays the current day count.
 */
object NotificationHelper {

    const val CHANNEL_ID = "relationship_counter_channel"
    const val NOTIFICATION_ID = 1001
    private const val CHANNEL_NAME = "Relationship Counter"
    private const val CHANNEL_DESC = "Persistent counter showing days together"

    /**
     * Creates the notification channel on Android 8.0+ (API 26).
     * Must be called early (e.g., in Application.onCreate or service start).
     */
    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW   // silent, no sound/vibration
            ).apply {
                description = CHANNEL_DESC
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * Builds the persistent notification with the current [days] count.
     *
     * Tapping the notification opens the main activity.
     */
    fun buildNotification(context: Context, days: Int): NotificationCompat.Builder {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val dayLabel = if (days == 1) "day" else "days"
        val title = "$days $dayLabel together"
        val subtitle = "Our Heart • Together since"

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification) // will be generated in drawable
            .setContentTitle(title)
            .setContentText(subtitle)
            .setOngoing(true)                     // non‑dismissible
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setSilent(true)
            .setAutoCancel(false)
    }

    /**
     * Requests POST_NOTIFICATIONS permission on Android 13+ (API 33).
     */
    fun requestNotificationPermissionIfNeeded(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    activity,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                activity.requestPermissions(
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    100
                )
            }
        }
    }
}