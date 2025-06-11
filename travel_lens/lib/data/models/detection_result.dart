import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class DetectionResult extends Equatable {
  final String id;
  final String? userId;
  final DateTime timestamp;
  final String imagePath;
  final String? detectedObject;
  final String? extractedText;
  final String? translatedText;
  final String? summary;
  final bool isFavorite;
  final GeoPoint? location;
  final String? originalLanguage;
  final String? targetLanguage;

  const DetectionResult({
    required this.id,
    this.userId,
    required this.timestamp,
    required this.imagePath,
    this.detectedObject,
    this.extractedText,
    this.translatedText,
    this.summary,
    this.isFavorite = false,
    this.location,
    this.originalLanguage,
    this.targetLanguage,
  });

  // Create a new instance
  factory DetectionResult.create({
    String? userId,
    required File image,
    GeoPoint? location,
  }) {
    return DetectionResult(
      id: const Uuid().v4(),
      userId: userId,
      timestamp: DateTime.now(),
      imagePath: image.path,
      location: location,
    );
  }

  // Copy with method
  DetectionResult copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    String? imagePath,
    String? detectedObject,
    String? extractedText,
    String? translatedText,
    String? summary,
    bool? isFavorite,
    GeoPoint? location,
    String? originalLanguage,
    String? targetLanguage,
  }) {
    return DetectionResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      detectedObject: detectedObject ?? this.detectedObject,
      extractedText: extractedText ?? this.extractedText,
      translatedText: translatedText ?? this.translatedText,
      summary: summary ?? this.summary,
      isFavorite: isFavorite ?? this.isFavorite,
      location: location ?? this.location,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }

  // To Map method for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp,
      'imagePath': imagePath,
      'detectedObject': detectedObject,
      'extractedText': extractedText,
      'translatedText': translatedText,
      'summary': summary,
      'isFavorite': isFavorite,
      'location': location,
      'originalLanguage': originalLanguage,
      'targetLanguage': targetLanguage,
    };
  }

  // From Map method for Firestore
  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      id: map['id'],
      userId: map['userId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      imagePath: map['imagePath'],
      detectedObject: map['detectedObject'],
      extractedText: map['extractedText'],
      translatedText: map['translatedText'],
      summary: map['summary'],
      isFavorite: map['isFavorite'] ?? false,
      location: map['location'],
      originalLanguage: map['originalLanguage'],
      targetLanguage: map['targetLanguage'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        timestamp,
        imagePath,
        detectedObject,
        extractedText,
        translatedText,
        summary,
        isFavorite,
        location,
        originalLanguage,
        targetLanguage,
      ];
}
