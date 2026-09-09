import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/sync_conflict.dart';
import '../models/sync_metadata.dart';
import '../models/sync_operation.dart';
import 'connectivity_service.dart';
import 'firebase_service.dart';
import 'local_storage_service.dart';

class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  static bool _initialized = false;
  factory SyncQueueService() {
    if (!_initialized) {
      _instance._initialize();
      _initialized = true;
    }
    return _instance;
  }
  SyncQueueService._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  final StreamController<QueueSyncStatus> _syncStatusController =
      StreamController<QueueSyncStatus>.broadcast();

  Timer? _syncTimer;
  bool _isProcessing = false;

  Stream<QueueSyncStatus> get syncStatus => _syncStatusController.stream;

  void _initialize() {
    // Start periodic sync if online (using ConnectivityService as source of truth)
    _checkConnectivityAndStartSync();
  }

  Future<void> _checkConnectivityAndStartSync() async {
    final isOnline = await _connectivityService.checkConnection();

    if (isOnline) {
      _startPeriodicSync();
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    // Sync every 30 seconds when online
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      processSyncQueue();
    });
  }

  // Add operation to sync queue
  Future<void> addOperation({
    required String userId,
    required SyncOperationType type,
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    String? deviceId,
  }) async {
    final operationId = const Uuid().v4();
    final metadata = SyncMetadata(
      deviceId: deviceId ?? 'unknown_device',
      timestamp: DateTime.now(),
      operationId: operationId,
      version: 1,
    );

    final operation = SyncOperation(
      id: operationId,
      userId: userId,
      type: type,
      collection: collection,
      documentId: documentId,
      data: data,
      metadata: metadata,
    );

    await _localStorage.saveSyncOperation(operation);

    // If online, try to process immediately
    if (_connectivityService.isOnline && !_isProcessing) {
      processSyncQueue();
    }
  }

  // Process the sync queue
  Future<void> processSyncQueue({String? userId}) async {
    if (_isProcessing || !_connectivityService.isOnline) return;

    _isProcessing = true;
    _syncStatusController.add(QueueSyncStatus.processing);

    try {
      final operations = userId != null
          ? await _localStorage.getPendingSyncOperations(userId)
          : await _getAllPendingOperations();

      if (operations.isEmpty) {
        _syncStatusController.add(QueueSyncStatus.idle);
        return;
      }

      final results = await Future.wait(operations.map(_processOperation));

      final successCount = results.where((success) => success).length;
      final failureCount = results.length - successCount;

      if (failureCount == 0) {
        _syncStatusController.add(QueueSyncStatus.success);
      } else if (successCount == 0) {
        _syncStatusController.add(QueueSyncStatus.error);
      } else {
        _syncStatusController.add(QueueSyncStatus.partialSuccess);
      }
    } catch (e) {
      debugPrint('Error processing sync queue: $e');
      _syncStatusController.add(QueueSyncStatus.error);
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<SyncOperation>> _getAllPendingOperations() async {
    // This would need to be implemented to get operations for all users
    // For now, we'll return an empty list as we need user-specific operations
    return [];
  }

  Future<bool> _processOperation(SyncOperation operation) async {
    try {
      // Check if operation can still be retried
      if (!operation.canRetry) {
        await _localStorage.updateSyncOperationStatus(
          operation.id,
          SyncStatus.failed,
          errorMessage: 'Max retries exceeded',
        );
        return false;
      }

      final success = await _executeOperation(operation);

      if (success) {
        await _localStorage.updateSyncOperationStatus(
          operation.id,
          SyncStatus.completed,
          completedAt: DateTime.now(),
        );
        return true;
      } else {
        await _localStorage.incrementRetryCount(operation.id);
        return false;
      }
    } catch (e) {
      debugPrint('Error processing operation ${operation.id}: $e');
      await _localStorage.updateSyncOperationStatus(
        operation.id,
        SyncStatus.failed,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> _executeOperation(SyncOperation operation) async {
    final firestore = _firebaseService.firestore;

    try {
      final docRef = firestore
          .collection(operation.collection)
          .doc(operation.documentId);

      switch (operation.type) {
        case SyncOperationType.create:
          await docRef.set({
            ...operation.data,
            'metadata': operation.metadata.toJson(),
            'createdAt': operation.metadata.timestamp.toIso8601String(),
            'updatedAt': operation.metadata.timestamp.toIso8601String(),
          });
          break;

        case SyncOperationType.update:
          await docRef.update({
            ...operation.data,
            'metadata': operation.metadata.toJson(),
            'updatedAt': operation.metadata.timestamp.toIso8601String(),
          });
          break;

        case SyncOperationType.delete:
          await docRef.delete();
          break;
      }

      return true;
    } catch (e) {
      // Check if this is a conflict (document exists with newer timestamp)
      if (operation.type == SyncOperationType.update) {
        final conflict = await _checkForConflict(operation);
        if (conflict != null) {
          await _handleConflict(conflict);
          return false; // Don't retry, conflict needs resolution
        }
      }

      debugPrint('Firebase operation failed: $e');
      return false;
    }
  }

  Future<SyncConflict?> _checkForConflict(SyncOperation operation) async {
    try {
      final docRef = _firebaseService.firestore
          .collection(operation.collection)
          .doc(operation.documentId);

      final doc = await docRef.get();
      if (!doc.exists) return null;

      final remoteData = doc.data();
      if (remoteData == null) return null;

      final metadataData = remoteData['metadata'];
      if (metadataData == null) return null;

      final remoteMetadata = SyncMetadata.fromJson(metadataData);

      // Check if remote is newer
      if (remoteMetadata.timestamp.isAfter(operation.metadata.timestamp)) {
        return SyncConflict(
          conflictId: const Uuid().v4(),
          userId: operation.userId,
          collection: operation.collection,
          documentId: operation.documentId,
          localData: operation.data,
          remoteData: remoteData,
          localMetadata: operation.metadata,
          remoteMetadata: remoteMetadata,
          detectedAt: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error checking for conflict: $e');
      return null;
    }
  }

  Future<void> _handleConflict(SyncConflict conflict) async {
    // For now, use simple timestamp-based resolution
    // Remote wins if it's newer
    if (conflict.remoteMetadata.timestamp.isAfter(
      conflict.localMetadata.timestamp,
    )) {
      await _localStorage.saveSyncConflict(conflict.resolveWithRemote());
    } else {
      await _localStorage.saveSyncConflict(conflict.resolveWithLocal());
      // Re-queue the operation with local data
      await addOperation(
        userId: conflict.userId,
        type: SyncOperationType.update,
        collection: conflict.collection,
        documentId: conflict.documentId,
        data: conflict.localData,
        deviceId: conflict.localMetadata.deviceId,
      );
    }
  }

  // Manual sync trigger
  Future<void> triggerManualSync(String userId) async {
    if (!_connectivityService.isOnline) {
      throw Exception('No internet connection');
    }

    await processSyncQueue(userId: userId);
  }

  // Get sync statistics
  Future<SyncStatistics> getSyncStatistics(String userId) async {
    final operations = await _localStorage.getPendingSyncOperations(userId);
    final conflicts = await _localStorage.getUnresolvedConflicts(userId);

    return SyncStatistics(
      pendingOperations: operations.length,
      unresolvedConflicts: conflicts.length,
      isOnline: _connectivityService.isOnline,
      lastSyncAttempt: DateTime.now(), // This should be tracked properly
    );
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }

  /// Libera la instancia singleton (llamar al cerrar la app)
  static void disposeInstance() {
    _instance.dispose();
  }
}

enum QueueSyncStatus { idle, processing, success, partialSuccess, error }

class SyncStatistics {
  final int pendingOperations;
  final int unresolvedConflicts;
  final bool isOnline;
  final DateTime? lastSyncAttempt;

  const SyncStatistics({
    required this.pendingOperations,
    required this.unresolvedConflicts,
    required this.isOnline,
    this.lastSyncAttempt,
  });
}
