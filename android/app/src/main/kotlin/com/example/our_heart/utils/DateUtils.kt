// android/app/src/main/kotlin/com/example/our_heart/utils/DateUtils.kt

package com.example.our_heart.utils

import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit

object DateUtils {

    /**
     * Returns the number of full calendar days between the given [startMillis]
     * (milliseconds since epoch) and today, using the device's local time zone.
     *
     * The result is always non‑negative.  The calculation uses `java.time` and
     * therefore aligns with the Dart implementation (UTC‑normalised day count).
     */
    fun daysSince(startMillis: Long): Int {
        val startDate = java.time.Instant.ofEpochMilli(startMillis)
            .atZone(ZoneId.systemDefault())
            .toLocalDate()
        val today = LocalDate.now(ZoneId.systemDefault())
        return ChronoUnit.DAYS.between(startDate, today).toInt()
    }

    /**
     * Formats a number of days into a human‑readable string like
     * "2 years, 3 months, 5 days".
     */
    fun formatDays(days: Int): String {
        val years = days / 365
        val months = (days % 365) / 30
        val remainingDays = (days % 365) % 30

        val parts = mutableListOf<String>()
        if (years > 0) parts.add("$years year${if (years != 1) "s" else ""}")
        if (months > 0) parts.add("$months month${if (months != 1) "s" else ""}")
        if (remainingDays > 0 || parts.isEmpty()) {
            parts.add("$remainingDays day${if (remainingDays != 1) "s" else ""}")
        }
        return parts.joinToString(", ")
    }
}