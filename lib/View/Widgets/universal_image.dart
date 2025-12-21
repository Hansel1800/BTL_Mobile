import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UniversalImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    // Checking for Base64 (simple check)
    // Most base64 strings from pickers don't have the header, but some do.
    // Length check is a basic heuristic; URL usually starts with http.
    bool isUrl = imageUrl.startsWith('http');

    if (!isUrl) {
      try {
        // Attempt to decode base64
        // If image comes with "data:image/png;base64,..." prefix, standard decoder might fail if not stripped
        // But usually in flutter apps, we store raw base64 or path.
        // Let's try decoding.
        
        String cleanBase64 = imageUrl;
        if (imageUrl.contains(',')) {
            cleanBase64 = imageUrl.split(',').last.trim();
        } else {
            // Check if it's a local file path? No, user said Base64 context.
        }

        return Container(
          width: width,
          height: height,
          color: Colors.white,
          child: Image.memory(
            base64Decode(cleanBase64),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildError(),
          ),
        );
      } catch (e) {
        return _buildError();
      }
    }

    return Container(
      width: width,
      height: height,
      color: Colors.white,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) => _buildError(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
