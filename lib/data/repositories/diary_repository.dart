import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../local/database/app_database.dart' as db;
import '../../core/utils/logger.dart';

/// Repository for Farm Diary operations
/// Manages diary entries with image uploads
class DiaryRepository {
  final db.AppDatabase _database;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DiaryRepository({
    required db.AppDatabase database,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _database = database,
        _firestore = firestore,
        _storage = storage;

  /// Watch diary entries by user ID (real-time)
  Stream<Either<Failure, List<db.DiaryEntry>>> watchDiaryEntriesByUserId(String userId) {
    try {
      return _database.watchDiaryEntriesByUserId(userId).map((entries) => Right(entries));
    } catch (e) {
      AppLogger.error('Error watching diary entries', e);
      return Stream.value(Left(DatabaseFailure(message: e.toString())));
    }
  }

  /// Get diary entries for a specific date range
  Future<Either<Failure, List<db.DiaryEntry>>> getDiaryEntriesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final entries = await _database.getDiaryEntriesByDateRange(userId, startDate, endDate);
      return Right(entries);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting diary entries by date range', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting diary entries', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get diary entries by category
  Future<Either<Failure, List<db.DiaryEntry>>> getDiaryEntriesByCategory({
    required String userId,
    required String category,
  }) async {
    try {
      final entries = await _database.getDiaryEntriesByCategory(userId, category);
      return Right(entries);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting diary entries by category', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting diary entries', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Create diary entry with images
  Future<Either<Failure, String>> createDiaryEntry({
    required String userId,
    String? fieldId,
    required String title,
    required String content,
    required String category, // observation, expense, income, note
    double? amount,
    List<File>? images,
    DateTime? entryDate,
  }) async {
    try {
      final entryId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      final actualEntryDate = entryDate ?? now;

      // Upload images if provided
      List<String> imagePaths = [];
      if (images != null && images.isNotEmpty) {
        final uploadResult = await _uploadImages(userId, entryId, images);
        uploadResult.fold(
          (failure) => AppLogger.warning('Failed to upload some images: ${failure.message}'),
          (paths) => imagePaths = paths,
        );
      }

      final entry = db.DiaryEntriesCompanion(
        id: drift.Value(entryId),
        userId: drift.Value(userId),
        fieldId: drift.Value(fieldId),
        title: drift.Value(title),
        content: drift.Value(content),
        imagePaths: drift.Value(imagePaths.isNotEmpty ? jsonEncode(imagePaths) : null),
        category: drift.Value(category),
        amount: drift.Value(amount),
        entryDate: drift.Value(actualEntryDate),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
        isDeleted: const drift.Value(false),
      );

      await _database.insertDiaryEntry(entry);
      AppLogger.info('Diary entry created: $entryId');

      // Trigger background sync
      _syncEntryToCloud(entryId);

      return Right(entryId);
    } on DatabaseException catch (e) {
      AppLogger.error('Error creating diary entry', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error creating diary entry', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Update diary entry
  Future<Either<Failure, bool>> updateDiaryEntry({
    required String entryId,
    String? title,
    String? content,
    String? category,
    double? amount,
    List<File>? newImages,
  }) async {
    try {
      final now = DateTime.now();
      String? imagePathsJson;

      // Handle new images
      if (newImages != null && newImages.isNotEmpty) {
        final entry = await _database.getDiaryEntryById(entryId);
        if (entry != null) {
          final uploadResult = await _uploadImages(entry.userId, entryId, newImages);
          uploadResult.fold(
            (failure) => AppLogger.warning('Failed to upload images: ${failure.message}'),
            (newPaths) {
              // Merge with existing paths
              List<String> existingPaths = [];
              if (entry.imagePaths != null) {
                existingPaths = (jsonDecode(entry.imagePaths!) as List)
                    .map((e) => e.toString())
                    .toList();
              }
              existingPaths.addAll(newPaths);
              imagePathsJson = jsonEncode(existingPaths);
            },
          );
        }
      }

      final entryUpdate = db.DiaryEntriesCompanion(
        id: drift.Value(entryId),
        title: title != null ? drift.Value(title) : const drift.Value.absent(),
        content: content != null ? drift.Value(content) : const drift.Value.absent(),
        category: category != null ? drift.Value(category) : const drift.Value.absent(),
        amount: amount != null ? drift.Value(amount) : const drift.Value.absent(),
        imagePaths: imagePathsJson != null 
            ? drift.Value(imagePathsJson) 
            : const drift.Value.absent(),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      );

      final result = await _database.updateDiaryEntry(entryUpdate);
      AppLogger.info('Diary entry updated: $entryId');

      // Trigger background sync
      _syncEntryToCloud(entryId);

      return Right(result);
    } on DatabaseException catch (e) {
      AppLogger.error('Error updating diary entry', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error updating diary entry', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Delete diary entry (soft delete)
  Future<Either<Failure, bool>> deleteDiaryEntry(String entryId) async {
    try {
      final result = await _database.deleteDiaryEntry(entryId);
      AppLogger.info('Diary entry deleted: $entryId');

      // Trigger background sync
      _syncEntryToCloud(entryId);

      return Right(result > 0);
    } on DatabaseException catch (e) {
      AppLogger.error('Error deleting diary entry', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error deleting diary entry', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get financial summary (income vs expenses)
  Future<Either<Failure, Map<String, double>>> getFinancialSummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final entries = await _database.getDiaryEntriesByDateRange(userId, startDate, endDate);
      
      double totalIncome = 0;
      double totalExpense = 0;

      for (final entry in entries) {
        if (entry.amount != null) {
          if (entry.category == 'income') {
            totalIncome += entry.amount!;
          } else if (entry.category == 'expense') {
            totalExpense += entry.amount!;
          }
        }
      }

      return Right({
        'income': totalIncome,
        'expense': totalExpense,
        'profit': totalIncome - totalExpense,
      });
    } catch (e) {
      AppLogger.error('Error calculating financial summary', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Upload images to Firebase Storage
  Future<Either<Failure, List<String>>> _uploadImages(
    String userId,
    String entryId,
    List<File> images,
  ) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child('diary/$userId/$entryId/$fileName');

        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      AppLogger.info('Uploaded ${downloadUrls.length} images');
      return Right(downloadUrls);
    } on FirebaseException catch (e) {
      AppLogger.error('Error uploading images', e);
      return Left(StorageFailure(message: e.message ?? 'Upload failed'));
    } catch (e) {
      AppLogger.error('Unexpected error uploading images', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Sync entry to Firestore
  void _syncEntryToCloud(String entryId) async {
    try {
      final entry = await _database.getDiaryEntryById(entryId);
      if (entry == null) return;

      await _firestore.collection('diary').doc(entryId).set({
        'userId': entry.userId,
        'fieldId': entry.fieldId,
        'title': entry.title,
        'content': entry.content,
        'imagePaths': entry.imagePaths,
        'category': entry.category,
        'amount': entry.amount,
        'entryDate': entry.entryDate,
        'createdAt': entry.createdAt,
        'updatedAt': entry.updatedAt,
        'isDeleted': entry.isDeleted,
      });

      await _database.updateDiaryEntry(
        db.DiaryEntriesCompanion(
          id: drift.Value(entryId),
          isSynced: const drift.Value(true),
        ),
      );

      AppLogger.info('Diary entry synced to cloud: $entryId');
    } catch (e) {
      AppLogger.error('Error syncing entry to cloud', e);
    }
  }
}
