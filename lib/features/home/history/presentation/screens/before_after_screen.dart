// lib/features/history/presentation/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/config/api_config.dart';
import 'package:before_after/before_after.dart';



class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _designs = [];
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final url = _showFavoritesOnly
          ? '${ApiConfig.baseUrl}/history/all?favorites_only=true'
          : '${ApiConfig.baseUrl}/history/all';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _designs = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Erreur lors du chargement de l\'historique');
    }
  }

  Future<void> _toggleFavorite(int designId, bool isFavorite) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/history/$designId/favorite?is_favorite=$isFavorite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar(
          isFavorite ? 'Ajouté aux favoris !' : 'Retiré des favoris',
        );
        await _loadHistory(); // Recharger la liste
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la mise à jour');
    }
  }

  Future<void> _deleteDesign(int designId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce design ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/history/$designId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Design supprimé avec succès');
        await _loadHistory();
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la suppression');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mes Designs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
              _loadHistory();
            },
            tooltip: 'Afficher uniquement les favoris',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _designs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _designs.length,
                    itemBuilder: (context, index) {
                      final design = _designs[index];
                      return _buildDesignCard(design);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showFavoritesOnly ? Icons.favorite_border : Icons.auto_awesome,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            _showFavoritesOnly
                ? 'Aucun favori pour le moment'
                : 'Aucun design créé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _showFavoritesOnly
                ? 'Marquez des designs comme favoris'
                : 'Commencez à créer vos designs !',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignCard(Map<String, dynamic> design) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BeforeAfterScreen(design: design),
          ),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image générée
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.network(
                  '${ApiConfig.baseUrl}/static/${design['generated_image_path']}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            
            // Informations
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          design['room_type'] ?? 'Room',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          design['style'] ?? 'Style',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bouton favori
                        IconButton(
                          icon: Icon(
                            design['is_favorite']
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: design['is_favorite']
                                ? Colors.red
                                : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            _toggleFavorite(
                              design['id'],
                              !design['is_favorite'],
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        
                        // Bouton supprimer
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteDesign(design['id']),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}