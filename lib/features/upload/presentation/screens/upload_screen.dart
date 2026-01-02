import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:interior_design/core/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import 'package:interior_design/features/home/presentation/providers/style_providers.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  dynamic _imageFile;
  Uint8List? _webImage;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Classification results
  String? _roomType;
  double? _confidence;

  // Generated design
  Uint8List? _generatedDesign;

  // API URL
  static const String baseUrl = kIsWeb
      ? 'http://localhost:8000'
      : 'http://192.168.1.167:8000';

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
        _roomType = null;
        _confidence = null;
        _generatedDesign = null;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = pickedFile;
            _imagePath = pickedFile.path;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _imagePath = pickedFile.path;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.accentCream),
                  const SizedBox(width: 12),
                  const Text('Image selected! Classifying...'),
                ],
              ),
              backgroundColor: AppTheme.accentGold.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          await _classifyRoom();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _classifyRoom() async {
    if (_imageFile == null) {
      _showWarningSnackBar('Please select an image first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict'));

      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', _webImage!, filename: 'image.jpg'),
        );
      } else if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', (_imageFile as File).path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          _roomType = result['class'];
          _confidence = result['confidence'];
        });
        _showSuccessSnackBar('Classification completed: ${_roomType!.toUpperCase()}');
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Classification error: ${e.toString()}');
      setState(() {
        _roomType = null;
        _confidence = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Future<void> _generateDesign() async {
  //   final selectedStyle = ref.read(selectedStyleProvider);
  //   if (_imageFile == null) {
  //     _showWarningSnackBar('Please select an image first');
  //     return;
  //   }
  //   if (selectedStyle == null) {
  //     _showWarningSnackBar('Please select a style first');
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //     _generatedDesign = null;
  //   });

  //   try {
  //     var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/transform-room'));
  //     request.fields['style'] = selectedStyle; // send style
  //     if (kIsWeb && _webImage != null) {
  //       request.files.add(
  //         http.MultipartFile.fromBytes('file', _webImage!, filename: 'image.jpg'),
  //       );
  //     } else if (_imageFile != null) {
  //       request.files.add(
  //         await http.MultipartFile.fromPath('file', (_imageFile as File).path),
  //       );
  //     }

  //     final streamedResponse = await request.send();
  //     final response = await http.Response.fromStream(streamedResponse);

  //     if (response.statusCode == 200) {
  //       final result = json.decode(response.body);
  //       final base64Image = result['generated_image'] as String;
  //       setState(() {
  //         _generatedDesign = base64Decode(base64Image);
  //       });
  //       _showSuccessSnackBar('Design generated successfully!');
  //     } else {
  //       throw Exception('API Error: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     _showErrorSnackBar('Design generation error: ${e.toString()}');
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _generateDesign() async {
  final selectedStyle = ref.read(selectedStyleProvider);

  if (_imageFile == null || _roomType == null) {
    _showWarningSnackBar('Please classify the room first');
    return;
  }

  if (selectedStyle == null) {
    _showWarningSnackBar('Please select a style first');
    return;
  }

  setState(() {
    _isLoading = true;
    _generatedDesign = null;
  });

  try {
    final request = http.MultipartRequest(
      'POST',
      // Uri.parse('$baseUrl/transform-room'),
      Uri.parse('https://affirmingly-bibliotic-yadiel.ngrok-free.dev/transform-room')
    );

    // REQUIRED fields for Colab API
    request.fields['room_type'] = _roomType!;
    request.fields['style'] = selectedStyle;

    if (kIsWeb && _webImage != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _webImage!,
          filename: 'room.jpg',
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          (_imageFile as File).path,
        ),
      );
    }

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      final bytes = await streamedResponse.stream.toBytes();
      setState(() {
        _generatedDesign = bytes;
      });
      _showSuccessSnackBar('Design generated successfully!');
      
      // Save to history after successful generation
      await _saveDesign();
    } else {
      throw Exception('API Error: ${streamedResponse.statusCode}');
    }
  } catch (e) {
    _showErrorSnackBar('Design generation error: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _saveDesign() async {
    if (_imageFile == null || _generatedDesign == null || _roomType == null) {
      return; // Can't save without required data
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final selectedStyle = ref.read(selectedStyleProvider);

    if (token == null) {
      _showErrorSnackBar('Please login to save designs');
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/history/save'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['room_type'] = _roomType!;
      if (selectedStyle != null) {
        request.fields['style'] = selectedStyle;
      }
      if (_confidence != null) {
        request.fields['confidence'] = _confidence!.toString();
      }

      // Add original image file
      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'original_image',
            _webImage!,
            filename: 'original.jpg',
          ),
        );
      } else if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'original_image',
            (_imageFile as File).path,
          ),
        );
      }

      // Add generated image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'generated_image',
          _generatedDesign!,
          filename: 'generated.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Design saved successfully (message shown in success snackbar above)
      } else {
        throw Exception('Failed to save design: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Don't show error snackbar for save failures, just log
      print('Error saving design to history: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: AppTheme.accentCream),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorRed.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.accentCream),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successGreen.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.accentCream),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Room Classification & Design',
          style: TextStyle(
            color: AppTheme.accentCream,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.accentCream),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.secondaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),
                _buildImagePreview(),
                const SizedBox(height: 32),

                // Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGradient.colors.first,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildResultCard(),

                // Generate Design Button
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: (_imageFile != null && !_isLoading) ? _generateDesign : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_imageFile != null && !_isLoading)
                        ? AppTheme.accentGold
                        : AppTheme.secondaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Generate Design',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 32),

                // Generated Design Result
                if (_generatedDesign != null)
                  _buildGeneratedDesign(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_isLoading && _imageFile == null) {
      return Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
    }

    if (_webImage != null) {
      return Image.memory(_webImage!, height: 320, fit: BoxFit.cover);
    } else if (_imageFile != null && !kIsWeb) {
      return Image.file(_imageFile as File, height: 320, fit: BoxFit.cover);
    }

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 2),
      ),
      child: const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 64, color: Colors.white)),
    );
  }

  Widget _buildResultCard() {
    if (_roomType == null || _confidence == null) return const SizedBox.shrink();

    final confidencePercent = (_confidence! * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentGold.withOpacity(0.2), AppTheme.accentWarm.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentGold, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Room Type: $_roomType'),
          Text('Confidence: $confidencePercent%'),
        ],
      ),
    );
  }

  Widget _buildGeneratedDesign() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentGold.withOpacity(0.3), AppTheme.accentWarm.withOpacity(0.2)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.accentCream, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Generated Design',
                  style: TextStyle(
                    color: AppTheme.accentCream,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'PlayfairDisplay',
                  ),
                ),
              ],
            ),
          ),

          // Generated Image
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _generatedDesign!,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
