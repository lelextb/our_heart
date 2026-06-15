package com.example.our_heart

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.our_heart.services.RelationshipCounterService
import com.example.our_heart.utils.NotificationHelper

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.our_heart/counter"
    private val PERMISSION_REQUEST_CODE = 1001
    private var pendingStartDate: Long? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val startDateMillis = call.argument<Long>("startDate")
                        if (startDateMillis == null) {
                            result.error("INVALID_ARG", "startDate required", null)
                            return@setMethodCallHandler
                        }
                        pendingStartDate = startDateMillis
                        if (hasAllPermissions()) {
                            startServiceSafely(startDateMillis)
                            result.success(true)
                        } else {
                            requestRequiredPermissions()
                            result.success(false) // will retry
                        }
                    }
                    "stopService" -> {
                        RelationshipCounterService.stop(this)
                        pendingStartDate = null
                        result.success(true)
                    }
                    "updateDate" -> {
                        val newDateMillis = call.argument<Long>("startDate")
                        if (newDateMillis == null) {
                            result.error("INVALID_ARG", "startDate required", null)
                            return@setMethodCallHandler
                        }
                        if (hasAllPermissions()) {
                            RelationshipCounterService.updateDate(this, newDateMillis)
                            result.success(true)
                        } else {
                            pendingStartDate = newDateMillis
                            requestRequiredPermissions()
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        NotificationHelper.requestNotificationPermissionIfNeeded(this)
        requestRequiredPermissions()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                // Permissions granted – start the service if pending
                pendingStartDate?.let { startServiceSafely(it) }
                pendingStartDate = null
            }
        }
    }

    private fun hasAllPermissions(): Boolean {
        val notificationGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else true

        val dataSyncGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.FOREGROUND_SERVICE_DATA_SYNC
            ) == PackageManager.PERMISSION_GRANTED
        } else true

        return notificationGranted && dataSyncGranted
    }

    private fun requestRequiredPermissions() {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.FOREGROUND_SERVICE_DATA_SYNC
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissions.add(Manifest.permission.FOREGROUND_SERVICE_DATA_SYNC)
        }
        if (permissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }

    private fun startServiceSafely(startDateMillis: Long) {
        if (hasAllPermissions()) {
            RelationshipCounterService.start(this, startDateMillis)
        }
    }
}