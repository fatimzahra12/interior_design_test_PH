import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIAPIService {
  // 🔹 Backend local / serveur principal (classification)
  // Android emulator → 10.0.2.2
  final String classificationBaseUrl = "http://10.0.2.2:8000";

  // 🔹 Colab + ngrok (generation)
  // ⚠️ Change this URL each time ngrok gives a new one
  final String generationBaseUrl =
      "https://affirmingly-bibliotic-yadiel.ngrok-free.dev";

  // ============================================================
  // 1️⃣ ROOM CLASSIFICATION
  // ============================================================
  Future<String> classifyRoom(File image) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$classificationBaseUrl/predict"),
    );

    request.files.add(
      await http.MultipartFile.fromPath("file", image.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["prediction"]; // ex: "bedroom", "kitchen"
    } else {
      throw Exception(
        "Room classification failed: ${response.body}",
      );
    }
  }

  // ============================================================
  // 2️⃣ DESIGN GENERATION (COLAB GPU)
  // ============================================================
  Future<Uint8List> generateDesign({
    required File image,
    required String roomType,
    required String style,
  }) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$generationBaseUrl/transform-room"),
    );

    // Image
    request.files.add(
      await http.MultipartFile.fromPath("image", image.path),
    );

    // Form fields
    request.fields["room_type"] = roomType;
    request.fields["style"] = style;

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      return await streamedResponse.stream.toBytes();
    } else {
      final error =
          await streamedResponse.stream.bytesToString();
      throw Exception("Design generation failed: $error");
    }
  }

  // ============================================================
  // 3️⃣ FULL PIPELINE (ONE BUTTON → ONE FUNCTION)
  // ============================================================
  Future<Uint8List> generateFromImage({
    required File image,
    required String style,
  }) async {
    // Step 1: classify room
    final roomType = await classifyRoom(image);

    // Step 2: generate design
    return await generateDesign(
      image: image,
      roomType: roomType,
      style: style,
    );
  }
}
