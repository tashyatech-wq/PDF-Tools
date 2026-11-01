package `in`.tashyalabs.pdf_toolkit

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val cameraPermissionRequestCode = 4207
    private var pendingCameraPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pdf_tools/permissions"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestCamera" -> requestCameraPermission(result)
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        if (pendingCameraPermission != null) {
            result.error("permission_pending", "Camera permission request is already open.", null)
            return
        }

        pendingCameraPermission = result
        requestPermissions(arrayOf(Manifest.permission.CAMERA), cameraPermissionRequestCode)
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == cameraPermissionRequestCode) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingCameraPermission?.success(granted)
            pendingCameraPermission = null
        }
    }
}
