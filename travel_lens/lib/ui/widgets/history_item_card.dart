import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_lens/data/models/detection_result.dart';

class HistoryItemCard extends StatelessWidget {
  final DetectionResult item;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const HistoryItemCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildImage(),
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.detectedObject ?? 'Unknown object',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(item.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),

                  // Location if available
                  // if (item.placeName != null)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 4.0),
                  //     child: Row(
                  //       children: [
                  //         Icon(
                  //           Icons.location_on_outlined,
                  //           size: 16,
                  //           color: Colors.grey[600],
                  //         ),
                  //         const SizedBox(width: 4),
                  //         Expanded(
                  //           child: Text(
                  //             item.placeName!,
                  //             style: TextStyle(
                  //               color: Colors.grey[600],
                  //               fontSize: 12,
                  //             ),
                  //             maxLines: 1,
                  //             overflow: TextOverflow.ellipsis,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),

                  // Extracted text preview if available
                  if (item.extractedText != null &&
                      item.extractedText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        item.extractedText!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Bottom action row
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tags/indicators
                        Row(
                          children: [
                            if (item.detectedObject != null)
                              _buildChip('Object'),
                            if (item.extractedText != null) _buildChip('Text'),
                            if (item.translatedText != null)
                              _buildChip('Translation'),
                          ],
                        ),

                        // Delete button if provided
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: onDelete,
                            color: Colors.red[400],
                            tooltip: 'Delete',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: item.imagePath,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 180,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        height: 180,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.error)),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: -2.0),
      ),
    );
  }
}
