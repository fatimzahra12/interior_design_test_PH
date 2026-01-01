import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  dynamic _imageFile;
  Uint8List? _webImage;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  // Classification results
  String? _roomType;
  double? _confidence;

  // API URL
  static const String baseUrl = kIsWeb 
      ? 'http://localhost:8000'
      : 'http://192.168.11.107:8000'; // CHANGE THIS IP!

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
        _roomType = null;
        _confidence = null;
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
                  const Text('Image selected ! Classifying...'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppTheme.accentCream),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.errorRed.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _classifyRoom() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: AppTheme.accentCream),
              const SizedBox(width: 12),
              const Text('Please select an image first'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );

      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _webImage!,
            filename: 'image.jpg',
          ),
        );
      } else if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            (_imageFile as File).path,
          ),
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.accentCream),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Classification completed: ${_roomType!.toUpperCase()}'
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successGreen.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppTheme.accentCream),
                const SizedBox(width: 12),
                Expanded(child: Text('Classification error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.errorRed.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
      setState(() {
        _roomType = null;
        _confidence = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_isLoading && _imageFile == null) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: AppTheme.secondaryDark.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 2),
          boxShadow: AppTheme.glowShadow(),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.accentGold),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_webImage != null) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: AppTheme.secondaryDark.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 2),
          boxShadow: AppTheme.glowShadow(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            _webImage!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      );
    } else if (_imageFile != null && !kIsWeb) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: AppTheme.secondaryDark.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 2),
          boxShadow: AppTheme.glowShadow(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _imageFile as File,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      );
    }

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowShadow(),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Image Selected',
              style: TextStyle(
                color: AppTheme.textLight.withOpacity(0.9),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'PlayfairDisplay',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload a room photo to classify',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_roomType == null || _confidence == null) {
      return const SizedBox.shrink();
    }

    final confidencePercent = (_confidence! * 100).toStringAsFixed(1);
    final isHighConfidence = _confidence! >= 0.8;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withOpacity(0.2),
            AppTheme.accentWarm.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighConfidence ? AppTheme.accentGold : AppTheme.accentWarm,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isHighConfidence ? AppTheme.accentGold : AppTheme.accentWarm).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.glowShadow(),
                ),
                child: const Icon(
                  Icons.meeting_room_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classification Result',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textLight.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _roomType!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textLight,
                        fontFamily: 'PlayfairDisplay',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.secondaryDark.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isHighConfidence ? AppTheme.accentGold : AppTheme.accentWarm).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHighConfidence 
                        ? AppTheme.accentGold.withOpacity(0.2) 
                        : AppTheme.accentWarm.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isHighConfidence ? Icons.verified : Icons.info_outline,
                    color: isHighConfidence ? AppTheme.accentGold : AppTheme.accentWarm,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confidence Level',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLight.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '$confidencePercent%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isHighConfidence ? AppTheme.accentGold : AppTheme.accentWarm,
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (isHighConfidence 
                                  ? AppTheme.accentGold 
                                  : AppTheme.accentWarm).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (isHighConfidence 
                                    ? AppTheme.accentGold 
                                    : AppTheme.accentWarm).withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              isHighConfidence ? 'HIGH' : 'MEDIUM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isHighConfidence ? AppTheme.accentGold : AppTheme.accentWarm,
                                fontFamily: 'Inter',
                                letterSpacing: 1,
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
          ),
        ],
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
          'Room Classification',
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
                
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.accentGold.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Room Image',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentCream,
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload a photo of any room and our AI will classify it',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 3,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Image Preview
                _buildImagePreview(),
                
                const SizedBox(height: 32),
                
                // Camera Button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryDark.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.accentGold.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : () => _pickImage(ImageSource.camera),
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: AppTheme.accentGold,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Take Photo',
                                style: TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Gallery Button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.glowShadow(),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Choose from Gallery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Result Card
                _buildResultCard(),
                
                const SizedBox(height: 32),
                
                // Classify Button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: (_imageFile != null && !_isLoading)
                          ? AppTheme.glowShadow()
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: (_isLoading || _imageFile == null) 
                          ? null 
                          : _classifyRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_imageFile == null || _isLoading)
                            ? AppTheme.secondaryDark
                            : AppTheme.accentGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.psychology_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Generate Design',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Tips Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.accentGold.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.glowShadow(),
                            ),
                            child: const Icon(
                              Icons.tips_and_updates_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Tips for Best Results',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentCream,
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTipItem(Icons.wb_sunny_outlined, 'Take photos in good lighting'),
                      _buildTipItem(Icons.crop_free_rounded, 'Capture the entire room clearly'),
                      _buildTipItem(Icons.door_front_door_outlined, 'Include doors and windows'),
                      _buildTipItem(Icons.weekend_outlined, 'Keep furniture visible but not cluttered'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentGold.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.textLight.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}