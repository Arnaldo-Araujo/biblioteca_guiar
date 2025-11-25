import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isCircular;
  final IconData fallbackIcon;
  final double fallbackIconSize;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isCircular = false,
    this.fallbackIcon = Icons.image,
    this.fallbackIconSize = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    if (isCircular) {
      return CircleAvatar(
        radius: (width ?? height ?? 50) / 2,
        backgroundColor: Colors.grey[300],
        child: ClipOval(
          child: Image.network(
            imageUrl!,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                fallbackIcon,
                size: fallbackIconSize,
                color: Colors.grey[600],
              );
            },
          ),
        ),
      );
    }

    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildFallback();
      },
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          fallbackIcon,
          size: fallbackIconSize,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
