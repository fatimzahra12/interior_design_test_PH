// // lib/features/profile/presentation/screens/profile_screen.dart

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../../../core/config/api_config.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   bool _isLoading = true;
//   Map<String, dynamic>? _profileData;
//   File? _profileImage;
//   final ImagePicker _picker = ImagePicker();

//   // Controllers pour les champs de texte
//   final TextEditingController _bioController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _oldPasswordController = TextEditingController();
//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }

//   // Charger le profil depuis l'API
//   Future<void> _loadProfile() async {
//     setState(() => _isLoading = true);

//     try {
//       // Récupérer le token depuis le stockage local
//       // (Assurez-vous d'avoir sauvegardé le token lors du login)
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');

//       final response = await http.get(
//         Uri.parse('${ApiConfig.baseUrl}/profile/me'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _profileData = data;
//           _bioController.text = data['bio'] ?? '';
//           _phoneController.text = data['phone'] ?? '';
//           _isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load profile');
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//       _showErrorSnackbar('Erreur lors du chargement du profil');
//     }
//   }

//   // Choisir une photo de profil
//   Future<void> _pickProfileImage() async {
//     final XFile? image = await _picker.pickImage(
//       source: ImageSource.gallery,
//       maxWidth: 512,
//       maxHeight: 512,
//       imageQuality: 85,
//     );

//     if (image != null) {
//       setState(() => _profileImage = File(image.path));
//       await _uploadProfilePicture();
//     }
//   }

//   // Upload la photo de profil
//   Future<void> _uploadProfilePicture() async {
//     if (_profileImage == null) return;

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');

//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('${ApiConfig.baseUrl}/profile/upload-picture'),
//       );

//       request.headers['Authorization'] = 'Bearer $token';
//       request.files.add(
//         await http.MultipartFile.fromPath('file', _profileImage!.path),
//       );

//       final response = await request.send();

//       if (response.statusCode == 200) {
//         _showSuccessSnackbar('Photo de profil mise à jour !');
//         await _loadProfile(); // Recharger le profil
//       } else {
//         throw Exception('Upload failed');
//       }
//     } catch (e) {
//       _showErrorSnackbar('Erreur lors de l\'upload de la photo');
//     }
//   }

//   // Mettre à jour le profil
//   Future<void> _updateProfile() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');

//       final response = await http.put(
//         Uri.parse('${ApiConfig.baseUrl}/profile/update'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode({
//           'bio': _bioController.text,
//           'phone': _phoneController.text,
//           'favorite_style': _profileData?['favorite_style'],
//         }),
//       );

//       if (response.statusCode == 200) {
//         _showSuccessSnackbar('Profil mis à jour avec succès !');
//         await _loadProfile();
//       } else {
//         throw Exception('Update failed');
//       }
//     } catch (e) {
//       _showErrorSnackbar('Erreur lors de la mise à jour');
//     }
//   }

//   // Changer le mot de passe
//   Future<void> _changePassword() async {
//     if (_newPasswordController.text != _confirmPasswordController.text) {
//       _showErrorSnackbar('Les mots de passe ne correspondent pas');
//       return;
//     }

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');

//       final response = await http.put(
//         Uri.parse('${ApiConfig.baseUrl}/profile/change-password'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode({
//           'old_password': _oldPasswordController.text,
//           'new_password': _newPasswordController.text,
//         }),
//       );

//       if (response.statusCode == 200) {
//         _showSuccessSnackbar('Mot de passe changé avec succès !');
//         _oldPasswordController.clear();
//         _newPasswordController.clear();
//         _confirmPasswordController.clear();
//       } else {
//         throw Exception('Password change failed');
//       }
//     } catch (e) {
//       _showErrorSnackbar('Mot de passe actuel incorrect');
//     }
//   }

//   void _showSuccessSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.green),
//     );
//   }

//   void _showErrorSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Mon Profil')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         title: const Text(
//           'Mon Profil',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 22,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             // Photo de profil
//             _buildProfilePicture(),
//             const SizedBox(height: 30),

//             // Statistiques
//             _buildStatsCard(),
//             const SizedBox(height: 20),

//             // Informations personnelles
//             _buildInfoSection(),
//             const SizedBox(height: 20),

//             // Changer le mot de passe
//             _buildPasswordSection(),
//             const SizedBox(height: 30),

//             // Bouton de déconnexion
//             _buildLogoutButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProfilePicture() {
//     return Stack(
//       children: [
//         CircleAvatar(
//           radius: 60,
//           backgroundColor: Colors.grey[300],
//           backgroundImage: _profileImage != null
//               ? FileImage(_profileImage!)
//               : (_profileData?['profile_picture'] != null
//                   ? NetworkImage(_profileData!['profile_picture'])
//                   : null) as ImageProvider?,
//           child: _profileImage == null && _profileData?['profile_picture'] == null
//               ? const Icon(Icons.person, size: 60, color: Colors.white)
//               : null,
//         ),
//         Positioned(
//           bottom: 0,
//           right: 0,
//           child: GestureDetector(
//             onTap: _pickProfileImage,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF6C63FF),
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white, width: 3),
//               ),
//               child: const Icon(
//                 Icons.camera_alt,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatsCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildStatItem(
//             Icons.auto_awesome,
//             '${_profileData?['total_designs'] ?? 0}',
//             'Designs',
//           ),
//           Container(width: 1, height: 40, color: Colors.grey[300]),
//           _buildStatItem(
//             Icons.favorite,
//             '0', // TODO: Ajouter les favoris
//             'Favoris',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(IconData icon, String value, String label) {
//     return Column(
//       children: [
//         Icon(icon, color: const Color(0xFF6C63FF), size: 30),
//         const SizedBox(height: 5),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             color: Colors.grey[600],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Informations personnelles',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 20),
//           _buildInfoField('Nom d\'utilisateur', _profileData?['username'] ?? ''),
//           _buildInfoField('Email', _profileData?['email'] ?? ''),
//           TextField(
//             controller: _bioController,
//             decoration: const InputDecoration(
//               labelText: 'Bio',
//               hintText: 'Parlez-nous de vous...',
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 3,
//           ),
//           const SizedBox(height: 15),
//           TextField(
//             controller: _phoneController,
//             decoration: const InputDecoration(
//               labelText: 'Téléphone',
//               hintText: '+212 6XX XXX XXX',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _updateProfile,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6C63FF),
//                 padding: const EdgeInsets.symmetric(vertical: 15),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               child: const Text(
//                 'Mettre à jour',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoField(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPasswordSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Changer le mot de passe',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 20),
//           TextField(
//             controller: _oldPasswordController,
//             obscureText: true,
//             decoration: const InputDecoration(
//               labelText: 'Mot de passe actuel',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.lock_outline),
//             ),
//           ),
//           const SizedBox(height: 15),
//           TextField(
//             controller: _newPasswordController,
//             obscureText: true,
//             decoration: const InputDecoration(
//               labelText: 'Nouveau mot de passe',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.lock),
//             ),
//           ),
//           const SizedBox(height: 15),
//           TextField(
//             controller: _confirmPasswordController,
//             obscureText: true,
//             decoration: const InputDecoration(
//               labelText: 'Confirmer le mot de passe',
//               border: OutlineInputBorder(),
//               prefixIcon: Icon(Icons.lock),
//             ),
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _changePassword,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6C63FF),
//                 padding: const EdgeInsets.symmetric(vertical: 15),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               child: const Text(
//                 'Changer le mot de passe',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLogoutButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: OutlinedButton(
//         onPressed: () async {
//           final prefs = await SharedPreferences.getInstance();
//           await prefs.remove('auth_token');
//           Navigator.pushReplacementNamed(context, '/login');
//         },
//         style: OutlinedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 15),
//           side: const BorderSide(color: Colors.red, width: 2),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//         child: const Text(
//           'Se déconnecter',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.red,
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _bioController.dispose();
//     _phoneController.dispose();
//     _oldPasswordController.dispose();
//     _newPasswordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
// }





// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Text field controllers
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Load profile from API
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _profileData = data;
          _bioController.text = data['bio'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error loading profile');
    }
  }

  // Pick profile picture
  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _profileImage = File(image.path));
      await _uploadProfilePicture();
    }
  }

  // Upload profile picture
  Future<void> _uploadProfilePicture() async {
    if (_profileImage == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/profile/upload-picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', _profileImage!.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Profile picture updated!');
        await _loadProfile(); // Reload profile
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      _showErrorSnackbar('Error uploading picture');
    }
  }

  // Update profile
  Future<void> _updateProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profile/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bio': _bioController.text,
          'phone': _phoneController.text,
          'favorite_style': _profileData?['favorite_style'],
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Profile updated successfully!');
        await _loadProfile();
      } else {
        throw Exception('Update failed');
      }
    } catch (e) {
      _showErrorSnackbar('Update error');
    }
  }

  // Change password
  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Passwords do not match');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profile/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'old_password': _oldPasswordController.text,
          'new_password': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Password changed successfully!');
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        throw Exception('Password change failed');
      }
    } catch (e) {
      _showErrorSnackbar('Current password incorrect');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'My Profile',
            style: TextStyle(
              color: AppTheme.textLight,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.textLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentGold,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppTheme.accentCream,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.accentCream,
          ),
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
              children: [
                // Profile Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.accentGold.withOpacity(0.2),
                    ),
                    boxShadow: AppTheme.glowShadow(),
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.glowShadow(),
                            ),
                            child: CircleAvatar(
                              radius: 58,
                              backgroundColor: AppTheme.secondaryDark,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (_profileData?['profile_picture'] != null
                                      ? NetworkImage(_profileData!['profile_picture'])
                                      : null) as ImageProvider?,
                              child: _profileImage == null && 
                                     _profileData?['profile_picture'] == null
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppTheme.accentCream,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickProfileImage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.secondaryDark.withOpacity(0.8),
                                    width: 3,
                                  ),
                                  boxShadow: AppTheme.glowShadow(),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _profileData?['username'] ?? 'User',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentCream,
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _profileData?['email'] ?? 'user@example.com',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textMuted,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 3,
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Section
                _buildStatsCard(),
                const SizedBox(height: 24),

                // Personal Information
                _buildInfoSection(),
                const SizedBox(height: 24),

                // Change Password
                _buildPasswordSection(),
                const SizedBox(height: 24),

                // Logout Button
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.2),
        ),
        boxShadow: AppTheme.glowShadow(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.auto_awesome_rounded,
            '${_profileData?['total_designs'] ?? 0}',
            'Designs',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.accentGold.withOpacity(0.3),
          ),
          _buildStatItem(
            Icons.favorite_rounded,
            '0', // TODO: Add favorites count
            'Favorites',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.accentGold.withOpacity(0.3),
          ),
          _buildStatItem(
            Icons.style_rounded,
            _profileData?['favorite_style'] ?? 'Minimalist',
            'Style',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.accentGold.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.accentGold,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.accentCream,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.2),
        ),
        boxShadow: AppTheme.glowShadow(),
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
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Personal Information',
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
          _buildInfoField(
            'Username',
            _profileData?['username'] ?? 'Not set',
            Icons.person,
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            'Email',
            _profileData?['email'] ?? 'Not set',
            Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bio',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.secondaryDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentGold.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _bioController,
                  style: TextStyle(
                    color: AppTheme.accentCream,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell us about yourself...',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.description_outlined,
                      color: AppTheme.accentGold.withOpacity(0.7),
                    ),
                  ),
                  maxLines: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.secondaryDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentGold.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _phoneController,
                  style: TextStyle(
                    color: AppTheme.accentCream,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    hintText: '+212 6XX XXX XXX',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppTheme.accentGold.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
                shadowColor: AppTheme.accentGold.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Update Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.accentGold.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.accentCream,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.2),
        ),
        boxShadow: AppTheme.glowShadow(),
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
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Change Password',
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
          _buildPasswordField(
            'Current Password',
            _oldPasswordController,
            Icons.lock_outline,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            'New Password',
            _newPasswordController,
            Icons.lock_reset,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            'Confirm Password',
            _confirmPasswordController,
            Icons.lock_clock_outlined,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
                shadowColor: AppTheme.accentGold.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.key_rounded, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withOpacity(0.2),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: true,
            style: TextStyle(
              color: AppTheme.accentCream,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(
                icon,
                color: AppTheme.accentGold.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          backgroundColor: Colors.red.withOpacity(0.1),
          side: const BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          minimumSize: const Size(double.infinity, 56),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 22),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}