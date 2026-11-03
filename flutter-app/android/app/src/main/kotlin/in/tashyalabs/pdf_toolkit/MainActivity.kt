package `in`.tashyalabs.pdf_toolkit

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val cameraPermissionRequestCode = 4207
    private var pendingCameraPermission: MethodChannel.Result? = null

    private val saveAsRequestCode = 4208
    private var pendingSaveAsResult: MethodChannel.Result? = null
    private var pendingSaveAsBytes: ByteArray? = null

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

        // `file_picker`'s own Save As flow only ever hands Dart back the
        // chosen Uri's bare path (e.g. "/document/249"), not its scheme and
        // authority -- that's done on its native side before Flutter ever
        // sees it, so there's no way to reconstruct a working content://
        // reference from the Dart side afterwards. `saveAs` below runs the
        // same ACTION_CREATE_DOCUMENT flow ourselves instead, specifically
        // so we can hand back the *whole* Uri and actually delete that
        // exported copy again later, including after the app restarts
        // (hence persisting the grant on it immediately).
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pdf_tools/files"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveAs" -> saveAs(
                    call.argument<String>("fileName"),
                    call.argument<String>("mimeType"),
                    call.argument<ByteArray>("bytes"),
                    result
                )
                "persistUri" -> result.success(
                    call.argument<String>("uri")?.let(Uri::parse)?.let(::persistUri) ?: false
                )
                "deleteUri" -> result.success(deleteUri(call.argument<String>("uri")))
                else -> result.notImplemented()
            }
        }
    }

    private fun saveAs(
        fileName: String?,
        mimeType: String?,
        bytes: ByteArray?,
        result: MethodChannel.Result
    ) {
        if (fileName == null || bytes == null) {
            result.error("bad_args", "fileName and bytes are required.", null)
            return
        }
        if (pendingSaveAsResult != null) {
            result.error("save_pending", "A Save As dialog is already open.", null)
            return
        }

        pendingSaveAsResult = result
        pendingSaveAsBytes = bytes
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType ?: "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        try {
            startActivityForResult(intent, saveAsRequestCode)
        } catch (e: Exception) {
            pendingSaveAsResult = null
            pendingSaveAsBytes = null
            result.error("no_picker", "Couldn't open the Save As dialog.", e.message)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveAsRequestCode) return

        val pending = pendingSaveAsResult
        val bytes = pendingSaveAsBytes
        pendingSaveAsResult = null
        pendingSaveAsBytes = null

        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null || bytes == null) {
            pending?.success(null)
            return
        }

        try {
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IOException("No output stream for $uri")
            persistUri(uri)
            pending?.success(uri.toString())
        } catch (e: Exception) {
            pending?.error("write_failed", "Could not save to the chosen location.", e.message)
        }
    }

    private fun persistUri(uri: Uri): Boolean {
        return try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
            true
        } catch (e: SecurityException) {
            false
        }
    }

    private fun deleteUri(uriString: String?): Boolean {
        val uri = uriString?.let(Uri::parse) ?: return false
        return try {
            DocumentsContract.deleteDocument(contentResolver, uri)
        } catch (e: Exception) {
            // Already gone, or the permission grant didn't survive -- either
            // way there's nothing more this app can do about that copy.
            false
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
