import 'dart:io';
import 'dart:typed_data';
import 'package:interior_design/features/upload/data/services/ai_api_service.dart';

class AIRepository {
  final AIAPIService _apiService = AIAPIService();

  /// Full pipeline:
  /// 1. classify room
  /// 2. generate interior design
  Future<Uint8List> generateDesign({
    required File image,
    required String style,
  }) async {
    // 1️⃣ Classification
    final classification = await _apiService.classifyRoom(image);

    final String roomType = classification['class'];
    // confidence exists but not needed for generation

    // 2️⃣ Generation (Colab API)
    final Uint8List generatedImage = await _apiService.generateRoom(
      image: image,
      roomType: roomType,
      style: style,
    );

    return generatedImage;
  }
}
