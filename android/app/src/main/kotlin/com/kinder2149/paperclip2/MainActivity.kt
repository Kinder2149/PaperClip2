package com.kinder2149.paperclip2

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.games.PlayGames
import com.google.android.gms.games.SnapshotsClient
import com.google.android.gms.games.snapshot.Snapshot
import com.google.android.gms.games.snapshot.SnapshotMetadataChange
import com.google.android.gms.games.snapshot.SnapshotMetadata

class MainActivity: FlutterActivity() {
    private val CHANNEL = "paperclip2/gpg_snapshots"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveCompressed" -> {
                    val slot: String = call.argument<String>("slot") ?: "paperclip2_main_save"
                    val bytes: ByteArray? = call.argument("bytes")
                    if (bytes == null) {
                        result.error("ARG_ERROR", "bytes manquant", null)
                        return@setMethodCallHandler
                    }
                    val client = PlayGames.getSnapshotsClient(this)
                    val policy = SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED
                    client.open(slot, true, policy)
                        .addOnSuccessListener { dorc ->
                            val snapshot: Snapshot? = dorc.data
                            if (snapshot == null) {
                                result.error("OPEN_FAIL", "Snapshot null", null)
                                return@addOnSuccessListener
                            }
                            try {
                                snapshot.snapshotContents.writeBytes(bytes)
                                val change = SnapshotMetadataChange.Builder()
                                    .setDescription("PaperClip2 save (gzip JSON)")
                                    .build()
                                client.commitAndClose(snapshot, change)
                                    .addOnSuccessListener { result.success(null) }
                                    .addOnFailureListener { e -> result.error("COMMIT_FAIL", e.message, null) }
                            } catch (e: Exception) {
                                result.error("WRITE_FAIL", e.message, null)
                            }
                        }
                        .addOnFailureListener { e -> result.error("OPEN_FAIL", e.message, null) }
                }
                "loadCompressed" -> {
                    val slot: String = call.argument<String>("slot") ?: "paperclip2_main_save"
                    val client = PlayGames.getSnapshotsClient(this)
                    val policy = SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED
                    client.open(slot, false, policy)
                        .addOnSuccessListener { dorc ->
                            val snapshot: Snapshot? = dorc.data
                            if (snapshot == null) {
                                result.success(null)
                                return@addOnSuccessListener
                            }
                            try {
                                val bytes = snapshot.snapshotContents.readFully()
                                result.success(bytes)
                            } catch (e: Exception) {
                                result.error("READ_FAIL", e.message, null)
                            } finally {
                                try { client.discardAndClose(snapshot) } catch (_: Exception) {}
                            }
                        }
                        .addOnFailureListener { e -> result.error("OPEN_FAIL", e.message, null) }
                }                "deleteSlot" -> {
                    val slot: String = call.argument<String>("slot") ?: "paperclip2_main_save"
                    val client = PlayGames.getSnapshotsClient(this)
                    val policy = SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED
                    client.open(slot, false, policy)
                        .addOnSuccessListener { dorc ->
                            val snapshot: Snapshot? = dorc.data
                            if (snapshot == null) {
                                result.success(null)
                                return@addOnSuccessListener
                            }
                            try {
                                val meta: SnapshotMetadata = snapshot.metadata
                                try { client.discardAndClose(snapshot) } catch (_: Exception) {}
                                client.delete(meta)
                                    .addOnSuccessListener { result.success(null) }
                                    .addOnFailureListener { e -> result.error("DELETE_FAIL", e.message, null) }
                            } catch (e: Exception) {
                                result.error("DELETE_FAIL", e.message, null)
                            }
                        }
                        .addOnFailureListener { e -> result.error("OPEN_FAIL", e.message, null) }
                }

                else -> result.notImplemented()
            }
        }
    }
}
