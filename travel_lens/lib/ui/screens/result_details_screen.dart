import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:travel_lens/data/models/detection_result.dart';
import 'package:travel_lens/data/providers/history_provider.dart';

class ResultDetailsScreen extends StatefulWidget {
  final DetectionResult result;

  const ResultDetailsScreen({super.key, required this.result});

  @override
  State<ResultDetailsScreen> createState() => _ResultDetailsScreenState();
}

class _ResultDetailsScreenState extends State<ResultDetailsScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(widget.result.targetLanguage ?? 'en-US');
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  Future<void> _speak(String text) async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      await _flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.result.detectedObject ?? 'Details'),
        actions: [
          IconButton(
            icon: Icon(
              widget.result.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.result.isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              final historyProvider =
                  Provider.of<HistoryProvider>(context, listen: false);
              historyProvider.toggleFavorite(widget.result.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Image.file(
                File(widget.result.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 60),
                    ),
                  );
                },
              ),
            ),

            // Date and time
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                dateFormat.format(widget.result.timestamp),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),

            // Content sections
            if (widget.result.detectedObject != null)
              _buildSection(
                context,
                'Detected Object',
                widget.result.detectedObject!,
                Icons.visibility,
              ),

            if (widget.result.extractedText != null)
              _buildSection(
                context,
                'Extracted Text',
                widget.result.extractedText!,
                Icons.text_fields,
                canSpeak: true,
              ),

            if (widget.result.translatedText != null)
              _buildSection(
                context,
                'Translation',
                widget.result.translatedText!,
                Icons.translate,
                canSpeak: true,
              ),

            if (widget.result.summary != null)
              _buildSection(
                context,
                'Summary',
                widget.result.summary!,
                Icons.summarize,
                canSpeak: true,
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, String content, IconData icon,
      {bool canSpeak = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  if (canSpeak)
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.stop : Icons.volume_up,
                      ),
                      onPressed: () => _speak(content),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
