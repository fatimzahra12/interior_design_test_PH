// lib/features/history/presentation/screens/design_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:interior_design/core/config/api_config.dart';
import '../../../../core/config/api_config.dart';

class DesignDetailScreen extends StatefulWidget {
  final Map<String, dynamic> design;

  const DesignDetailScreen({
    Key? key,
    required this.design,
  }) : super(key: key);

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  double _sliderPosition = 0.5;
  bool _showOriginal = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.design['room_type']?.toString() ?? 'Design',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareDesign,
          ),
        ],
      ),
      body: Column(
        children: [
          // Before/After Comparison
          Expanded(
            child: Stack(
              children: [
                // Before/After Images
                Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      children: [
                        // Original Image (Before)
                        Positioned.fill(
                          child: _buildImage(
                            widget.design['original_image_path'],
                            'Image originale',
                          ),
                        ),
                        // Generated Image (After) - with clip
                        Positioned.fill(
                          child: ClipRect(
                            clipper: _ImageClipper(_sliderPosition),
                            child: _buildImage(
                              widget.design['generated_image_path'],
                              'Image générée',
                            ),
                          ),
                        ),
                        // Divider Line
                        Positioned(
                          left: MediaQuery.of(context).size.width * _sliderPosition - 2,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 4,
                            color: Colors.white,
                          ),
                        ),
                        // Slider Handle
                        Positioned(
                          left: MediaQuery.of(context).size.width * _sliderPosition - 20,
                          top: MediaQuery.of(context).size.height * 0.4,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _sliderPosition += details.delta.dx / MediaQuery.of(context).size.width;
                                _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.compare,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Before/After Labels
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'AVANT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'APRÈS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Design Information
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.design['room_type']?.toString() ?? 'Room',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Style: ${widget.design['style']?.toString() ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.design['is_favorite'] == true
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.design['is_favorite'] == true
                            ? Colors.red
                            : Colors.grey,
                        size: 32,
                      ),
                      onPressed: () {
                        // Toggle favorite - you can implement this
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.design['created_at'] != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Créé le: ${_formatDate(widget.design['created_at'])}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadImage,
                        icon: const Icon(Icons.download),
                        label: const Text('Télécharger'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareDesign,
                        icon: const Icon(Icons.share),
                        label: const Text('Partager'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(dynamic imagePath, String errorText) {
    final path = imagePath?.toString();
    
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_not_supported, size: 60, color: Colors.white54),
              const SizedBox(height: 8),
              Text(
                errorText,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      '${ApiConfig.baseUrl}/static/$path',
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: Colors.white,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.white54),
                const SizedBox(height: 8),
                Text(
                  'Erreur de chargement',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  void _downloadImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de téléchargement en cours de développement'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement download functionality
  }

  void _shareDesign() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage en cours de développement'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement share functionality
  }
}

// Custom clipper for the before/after effect
class _ImageClipper extends CustomClipper<Rect> {
  final double position;

  _ImageClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      size.width * position,
      0,
      size.width,
      size.height,
    );
  }

  @override
  bool shouldReclip(_ImageClipper oldClipper) {
    return oldClipper.position != position;
  }
}