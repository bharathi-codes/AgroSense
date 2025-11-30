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

/// Repository for Community operations
/// Manages posts, comments, and social interactions
class CommunityRepository {
  final db.AppDatabase _database;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CommunityRepository({
    required db.AppDatabase database,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _database = database,
        _firestore = firestore,
        _storage = storage;

  /// Watch all posts (real-time feed)
  Stream<Either<Failure, List<db.Post>>> watchPosts({int limit = 20}) {
    try {
      return _database.watchAllPosts(limit).map((posts) => Right(posts));
    } catch (e) {
      AppLogger.error('Error watching posts', e);
      return Stream.value(Left(DatabaseFailure(message: e.toString())));
    }
  }

  /// Get posts by user ID
  Future<Either<Failure, List<db.Post>>> getPostsByUserId(String userId) async {
    try {
      final posts = await _database.getPostsByUserId(userId);
      return Right(posts);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting posts by user', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting posts', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Create new post with images
  Future<Either<Failure, String>> createPost({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String title,
    required String content,
    List<File>? images,
    List<String>? tags,
  }) async {
    try {
      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      // Upload images if provided
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        final uploadResult = await _uploadPostImages(userId, postId, images);
        uploadResult.fold(
          (failure) => AppLogger.warning('Failed to upload images: ${failure.message}'),
          (urls) => imageUrls = urls,
        );
      }

      final post = db.PostsCompanion(
        id: drift.Value(postId),
        userId: drift.Value(userId),
        userName: drift.Value(userName),
        userPhotoUrl: drift.Value(userPhotoUrl),
        title: drift.Value(title),
        content: drift.Value(content),
        imageUrls: drift.Value(imageUrls.isNotEmpty ? jsonEncode(imageUrls) : null),
        tags: drift.Value(tags != null ? jsonEncode(tags) : null),
        upvotes: const drift.Value(0),
        commentsCount: const drift.Value(0),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
        isDeleted: const drift.Value(false),
      );

      await _database.insertPost(post);
      AppLogger.info('Post created: $postId');

      // Sync to Firestore in background
      _syncPostToCloud(postId);

      return Right(postId);
    } on DatabaseException catch (e) {
      AppLogger.error('Error creating post', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error creating post', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Update post
  Future<Either<Failure, bool>> updatePost({
    required String postId,
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    try {
      final now = DateTime.now();

      final postUpdate = db.PostsCompanion(
        id: drift.Value(postId),
        title: title != null ? drift.Value(title) : const drift.Value.absent(),
        content: content != null ? drift.Value(content) : const drift.Value.absent(),
        tags: tags != null ? drift.Value(jsonEncode(tags)) : const drift.Value.absent(),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
      );

      final result = await _database.updatePost(postUpdate);
      AppLogger.info('Post updated: $postId');

      _syncPostToCloud(postId);
      return Right(result);
    } on DatabaseException catch (e) {
      AppLogger.error('Error updating post', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error updating post', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Delete post (soft delete)
  Future<Either<Failure, bool>> deletePost(String postId) async {
    try {
      final result = await _database.deletePost(postId);
      AppLogger.info('Post deleted: $postId');

      _syncPostToCloud(postId);
      return Right(result > 0);
    } on DatabaseException catch (e) {
      AppLogger.error('Error deleting post', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error deleting post', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Upvote post
  Future<Either<Failure, bool>> upvotePost(String postId) async {
    try {
      final result = await _database.incrementPostUpvotes(postId);
      AppLogger.info('Post upvoted: $postId');

      _syncPostToCloud(postId);
      return Right(result > 0);
    } on DatabaseException catch (e) {
      AppLogger.error('Error upvoting post', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error upvoting post', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Get comments for a post
  Future<Either<Failure, List<db.Comment>>> getCommentsByPostId(String postId) async {
    try {
      final comments = await _database.getCommentsByPostId(postId);
      return Right(comments);
    } on DatabaseException catch (e) {
      AppLogger.error('Error getting comments', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error getting comments', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Add comment to post
  Future<Either<Failure, String>> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
  }) async {
    try {
      final commentId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      final comment = db.CommentsCompanion(
        id: drift.Value(commentId),
        postId: drift.Value(postId),
        userId: drift.Value(userId),
        userName: drift.Value(userName),
        userPhotoUrl: drift.Value(userPhotoUrl),
        content: drift.Value(content),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        isSynced: const drift.Value(false),
        isDeleted: const drift.Value(false),
      );

      await _database.insertComment(comment);
      
      // Increment comment count on post
      await _database.incrementPostCommentsCount(postId);
      
      AppLogger.info('Comment added: $commentId');

      // Sync to Firestore
      _syncCommentToCloud(commentId);

      return Right(commentId);
    } on DatabaseException catch (e) {
      AppLogger.error('Error adding comment', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error adding comment', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Delete comment (soft delete)
  Future<Either<Failure, bool>> deleteComment(String commentId, String postId) async {
    try {
      final result = await _database.deleteComment(commentId);
      
      // Decrement comment count on post
      await _database.decrementPostCommentsCount(postId);
      
      AppLogger.info('Comment deleted: $commentId');

      _syncCommentToCloud(commentId);
      return Right(result > 0);
    } on DatabaseException catch (e) {
      AppLogger.error('Error deleting comment', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error deleting comment', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Upload post images to Firebase Storage
  Future<Either<Failure, List<String>>> _uploadPostImages(
    String userId,
    String postId,
    List<File> images,
  ) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child('posts/$userId/$postId/$fileName');

        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      AppLogger.info('Uploaded ${downloadUrls.length} post images');
      return Right(downloadUrls);
    } on FirebaseException catch (e) {
      AppLogger.error('Error uploading post images', e);
      return Left(StorageFailure(message: e.message ?? 'Upload failed'));
    } catch (e) {
      AppLogger.error('Unexpected error uploading images', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }

  /// Sync post to Firestore
  void _syncPostToCloud(String postId) async {
    try {
      final post = await _database.getPostById(postId);
      if (post == null) return;

      await _firestore.collection('posts').doc(postId).set({
        'userId': post.userId,
        'userName': post.userName,
        'userPhotoUrl': post.userPhotoUrl,
        'title': post.title,
        'content': post.content,
        'imageUrls': post.imageUrls,
        'tags': post.tags,
        'upvotes': post.upvotes,
        'commentsCount': post.commentsCount,
        'createdAt': post.createdAt,
        'updatedAt': post.updatedAt,
        'isDeleted': post.isDeleted,
      });

      await _database.updatePost(
        db.PostsCompanion(
          id: drift.Value(postId),
          isSynced: const drift.Value(true),
        ),
      );

      AppLogger.info('Post synced to cloud: $postId');
    } catch (e) {
      AppLogger.error('Error syncing post to cloud', e);
    }
  }

  /// Sync comment to Firestore
  void _syncCommentToCloud(String commentId) async {
    try {
      final comment = await _database.getCommentById(commentId);
      if (comment == null) return;

      await _firestore.collection('comments').doc(commentId).set({
        'postId': comment.postId,
        'userId': comment.userId,
        'userName': comment.userName,
        'userPhotoUrl': comment.userPhotoUrl,
        'content': comment.content,
        'createdAt': comment.createdAt,
        'updatedAt': comment.updatedAt,
        'isDeleted': comment.isDeleted,
      });

      await _database.updateComment(
        db.CommentsCompanion(
          id: drift.Value(commentId),
          isSynced: const drift.Value(true),
        ),
      );

      AppLogger.info('Comment synced to cloud: $commentId');
    } catch (e) {
      AppLogger.error('Error syncing comment to cloud', e);
    }
  }

  /// Search posts by tags or keywords
  Future<Either<Failure, List<db.Post>>> searchPosts(String query) async {
    try {
      final posts = await _database.searchPosts(query);
      return Right(posts);
    } on DatabaseException catch (e) {
      AppLogger.error('Error searching posts', e);
      return Left(DatabaseFailure(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error searching posts', e);
      return Left(GenericFailure(message: e.toString()));
    }
  }
}
