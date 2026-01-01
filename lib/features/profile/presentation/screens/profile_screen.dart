// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Controllers pour les champs de texte
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

  // Charger le profil depuis l'API
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer le token depuis le stockage local
      // (Assurez-vous d'avoir sauvegardé le token lors du login)
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
      _showErrorSnackbar('Erreur lors du chargement du profil');
    }
  }

  // Choisir une photo de profil
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

  // Upload la photo de profil
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
        _showSuccessSnackbar('Photo de profil mise à jour !');
        await _loadProfile(); // Recharger le profil
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'upload de la photo');
    }
  }

  // Mettre à jour le profil
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
        _showSuccessSnackbar('Profil mis à jour avec succès !');
        await _loadProfile();
      } else {
        throw Exception('Update failed');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la mise à jour');
    }
  }

  // Changer le mot de passe
  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Les mots de passe ne correspondent pas');
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
        _showSuccessSnackbar('Mot de passe changé avec succès !');
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        throw Exception('Password change failed');
      }
    } catch (e) {
      _showErrorSnackbar('Mot de passe actuel incorrect');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Photo de profil
            _buildProfilePicture(),
            const SizedBox(height: 30),

            // Statistiques
            _buildStatsCard(),
            const SizedBox(height: 20),

            // Informations personnelles
            _buildInfoSection(),
            const SizedBox(height: 20),

            // Changer le mot de passe
            _buildPasswordSection(),
            const SizedBox(height: 30),

            // Bouton de déconnexion
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          backgroundImage: _profileImage != null
              ? FileImage(_profileImage!)
              : (_profileData?['profile_picture'] != null
                  ? NetworkImage(_profileData!['profile_picture'])
                  : null) as ImageProvider?,
          child: _profileImage == null && _profileData?['profile_picture'] == null
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.auto_awesome,
            '${_profileData?['total_designs'] ?? 0}',
            'Designs',
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            Icons.favorite,
            '0', // TODO: Ajouter les favoris
            'Favoris',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 30),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoField('Nom d\'utilisateur', _profileData?['username'] ?? ''),
          _buildInfoField('Email', _profileData?['email'] ?? ''),
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Parlez-nous de vous...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              hintText: '+212 6XX XXX XXX',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Mettre à jour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Changer le mot de passe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _oldPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe actuel',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Changer le mot de passe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Se déconnecter',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
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