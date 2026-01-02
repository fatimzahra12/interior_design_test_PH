// // lib/features/history/presentation/screens/history_screen.dart

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:interior_design/core/config/api_config.dart';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../../core/config/api_config.dart';
// import 'design_detail_screen.dart'; // You need to create this file

// class HistoryScreen extends StatefulWidget {
//   const HistoryScreen({Key? key}) : super(key: key);

//   @override
//   State<HistoryScreen> createState() => _HistoryScreenState();
// }

// class _HistoryScreenState extends State<HistoryScreen> {
//   bool _isLoading = true;
//   List<dynamic> _designs = [];
//   bool _showFavoritesOnly = false;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _loadHistory();
//   }

//   Future<void> _loadHistory() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');

//       if (token == null || token.isEmpty) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
//         });
//         return;
//       }

//       final url = _showFavoritesOnly
//           ? '${ApiConfig.baseUrl}/history/all?favorites_only=true'
//           : '${ApiConfig.baseUrl}/history/all';

//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       ).timeout(
//         const Duration(seconds: 15),
//         onTimeout: () {
//           throw Exception('La requête a expiré. Vérifiez votre connexion.');
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _designs = data is List ? data : [];
//           _isLoading = false;
//         });
//       } else if (response.statusCode == 401) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
//         });
//         _handleUnauthorized();
//       } else {
//         throw Exception('Erreur serveur: ${response.statusCode}');
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = 'Erreur: ${e.toString()}';
//       });
//       _showErrorSnackbar('Erreur lors du chargement de l\'historique');
//     }
//   }

//   void _handleUnauthorized() {
//     // Navigate to login screen
//     // Navigator.of(context).pushReplacementNamed('/login');
//   }

//   String _getImageUrl(String imagePath) {
//     // Normalize path separators (Windows uses backslashes, URLs need forward slashes)
//     String normalizedPath = imagePath.replaceAll('\\', '/');
    
//     // Extract relative path from stored path
//     // Path format in DB could be: "uploads/designs/image.jpg" or "uploads\designs\image.jpg" (Windows)
//     // Static mount: "/static" -> "uploads" directory
//     // So we need: "/static/designs/image.jpg" (strip "uploads/")
    
//     // Remove "uploads/" prefix if present
//     if (normalizedPath.startsWith('uploads/')) {
//       normalizedPath = normalizedPath.substring(8); // Remove "uploads/"
//     }
    
//     // Also handle absolute paths that might include "uploads" somewhere
//     // e.g., "C:/project/uploads/designs/image.jpg" -> "designs/image.jpg"
//     final uploadsIndex = normalizedPath.indexOf('uploads/');
//     if (uploadsIndex != -1) {
//       normalizedPath = normalizedPath.substring(uploadsIndex + 8);
//     }
    
//     return '${ApiConfig.baseUrl}/static/$normalizedPath';
//   }

//   Future<void> _toggleFavorite(int designId, bool isFavorite) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');

//       if (token == null) {
//         _showErrorSnackbar('Session expirée');
//         return;
//       }

//       final response = await http.put(
//         Uri.parse('${ApiConfig.baseUrl}/history/$designId/favorite?is_favorite=$isFavorite'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       ).timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         _showSuccessSnackbar(
//           isFavorite ? 'Ajouté aux favoris !' : 'Retiré des favoris',
//         );
//         await _loadHistory();
//       } else {
//         throw Exception('Erreur ${response.statusCode}');
//       }
//     } catch (e) {
//       _showErrorSnackbar('Erreur lors de la mise à jour');
//     }
//   }

//   Future<void> _deleteDesign(int designId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirmer la suppression'),
//         content: const Text('Voulez-vous vraiment supprimer ce design ?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Annuler'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Supprimer'),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');

//       if (token == null) {
//         _showErrorSnackbar('Session expirée');
//         return;
//       }

//       final response = await http.delete(
//         Uri.parse('${ApiConfig.baseUrl}/history/$designId'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       ).timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         _showSuccessSnackbar('Design supprimé avec succès');
//         await _loadHistory();
//       } else {
//         throw Exception('Erreur ${response.statusCode}');
//       }
//     } catch (e) {
//       _showErrorSnackbar('Erreur lors de la suppression');
//     }
//   }

//   void _showSuccessSnackbar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _showErrorSnackbar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: AppBar(
//         title: const Text(
//           'Mes Designs',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 22,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Icon(
//               _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
//               color: _showFavoritesOnly ? Colors.red : Colors.grey,
//             ),
//             onPressed: () {
//               setState(() => _showFavoritesOnly = !_showFavoritesOnly);
//               _loadHistory();
//             },
//             tooltip: 'Afficher uniquement les favoris',
//           ),
//         ],
//       ),
//       body: _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_errorMessage != null) {
//       return _buildErrorState();
//     }

//     if (_designs.isEmpty) {
//       return _buildEmptyState();
//     }

//     return RefreshIndicator(
//       onRefresh: _loadHistory,
//       child: GridView.builder(
//         padding: const EdgeInsets.all(16),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 16,
//           mainAxisSpacing: 16,
//           childAspectRatio: 0.75,
//         ),
//         itemCount: _designs.length,
//         itemBuilder: (context, index) {
//           final design = _designs[index];
//           return _buildDesignCard(design);
//         },
//       ),
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.error_outline,
//             size: 100,
//             color: Colors.red[300],
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Erreur de chargement',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey[600],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Text(
//               _errorMessage ?? 'Une erreur est survenue',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[500],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton.icon(
//             onPressed: _loadHistory,
//             icon: const Icon(Icons.refresh),
//             label: const Text('Réessayer'),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             _showFavoritesOnly ? Icons.favorite_border : Icons.auto_awesome,
//             size: 100,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 20),
//           Text(
//             _showFavoritesOnly
//                 ? 'Aucun favori pour le moment'
//                 : 'Aucun design créé',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey[600],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             _showFavoritesOnly
//                 ? 'Marquez des designs comme favoris'
//                 : 'Commencez à créer vos designs !',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDesignCard(Map<String, dynamic> design) {
//     final generatedImagePath = design['generated_image_path'] as String?;
    
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DesignDetailScreen(design: design),
//           ),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Image générée
//             Expanded(
//               flex: 3,
//               child: ClipRRect(
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(15),
//                 ),
//                 child: generatedImagePath != null
//                     ? Image.network(
//                         _getImageUrl(generatedImagePath),
//                         fit: BoxFit.cover,
//                         loadingBuilder: (context, child, loadingProgress) {
//                           if (loadingProgress == null) return child;
//                           return Center(
//                             child: CircularProgressIndicator(
//                               value: loadingProgress.expectedTotalBytes != null
//                                   ? loadingProgress.cumulativeBytesLoaded /
//                                       loadingProgress.expectedTotalBytes!
//                                   : null,
//                             ),
//                           );
//                         },
//                         errorBuilder: (context, error, stackTrace) {
//                           // Debug: print the URL that failed
//                           print('Image load error for: ${_getImageUrl(generatedImagePath)}');
//                           print('Error: $error');
//                           return Container(
//                             color: Colors.grey[200],
//                             child: const Icon(
//                               Icons.image_not_supported,
//                               size: 50,
//                               color: Colors.grey,
//                             ),
//                           );
//                         },
//                       )
//                     : Container(
//                         color: Colors.grey[200],
//                         child: const Icon(
//                           Icons.image,
//                           size: 50,
//                           color: Colors.grey,
//                         ),
//                       ),
//               ),
//             ),

//             // Informations
//             Expanded(
//               flex: 2,
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           design['room_type']?.toString() ?? 'Room',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           design['style']?.toString() ?? 'Style',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),

//                     // Actions
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         // Bouton favori
//                         IconButton(
//                           icon: Icon(
//                             design['is_favorite'] == true
//                                 ? Icons.favorite
//                                 : Icons.favorite_border,
//                             color: design['is_favorite'] == true
//                                 ? Colors.red
//                                 : Colors.grey,
//                             size: 20,
//                           ),
//                           onPressed: () {
//                             final designId = design['id'] as int?;
//                             if (designId != null) {
//                               _toggleFavorite(
//                                 designId,
//                                 !(design['is_favorite'] == true),
//                               );
//                             }
//                           },
//                           padding: EdgeInsets.zero,
//                           constraints: const BoxConstraints(),
//                         ),

//                         // Bouton supprimer
//                         IconButton(
//                           icon: const Icon(
//                             Icons.delete_outline,
//                             color: Colors.red,
//                             size: 20,
//                           ),
//                           onPressed: () {
//                             final designId = design['id'] as int?;
//                             if (designId != null) {
//                               _deleteDesign(designId);
//                             }
//                           },
//                           padding: EdgeInsets.zero,
//                           constraints: const BoxConstraints(),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




// lib/features/history/presentation/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interior_design/core/config/api_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import 'package:interior_design/core/theme/app_theme.dart'; // Import theme
import 'design_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _designs = [];
  bool _showFavoritesOnly = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        });
        return;
      }

      final url = _showFavoritesOnly
          ? '${ApiConfig.baseUrl}/history/all?favorites_only=true'
          : '${ApiConfig.baseUrl}/history/all';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('La requête a expiré. Vérifiez votre connexion.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _designs = data is List ? data : [];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        });
        _handleUnauthorized();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: ${e.toString()}';
      });
      _showErrorSnackbar('Erreur lors du chargement de l\'historique');
    }
  }

  void _handleUnauthorized() {
    // Navigate to login screen
    // Navigator.of(context).pushReplacementNamed('/login');
  }

  String _getImageUrl(String imagePath) {
    // Normalize path separators (Windows uses backslashes, URLs need forward slashes)
    String normalizedPath = imagePath.replaceAll('\\', '/');
    
    // Remove "uploads/" prefix if present
    if (normalizedPath.startsWith('uploads/')) {
      normalizedPath = normalizedPath.substring(8);
    }
    
    // Also handle absolute paths that might include "uploads" somewhere
    final uploadsIndex = normalizedPath.indexOf('uploads/');
    if (uploadsIndex != -1) {
      normalizedPath = normalizedPath.substring(uploadsIndex + 8);
    }
    
    return '${ApiConfig.baseUrl}/static/$normalizedPath';
  }

  Future<void> _toggleFavorite(int designId, bool isFavorite) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar('Session expirée');
        return;
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/history/$designId/favorite?is_favorite=$isFavorite'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _showSuccessSnackbar(
          isFavorite ? 'Ajouté aux favoris !' : 'Retiré des favoris',
        );
        await _loadHistory();
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la mise à jour');
    }
  }

  Future<void> _deleteDesign(int designId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmer la suppression',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: AppTheme.secondaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.accentGold.withOpacity(0.3)),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer ce design ?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppTheme.accentCream.withOpacity(0.8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showErrorSnackbar('Session expirée');
        return;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/history/$designId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Design supprimé avec succès');
        await _loadHistory();
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la suppression');
    }
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar with gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Mes Designs',
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryDark.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Filter button
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryDark.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _showFavoritesOnly 
                      ? Icons.favorite 
                      : Icons.favorite_border_outlined,
                    color: _showFavoritesOnly 
                      ? Colors.red 
                      : AppTheme.accentCream,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() => _showFavoritesOnly = !_showFavoritesOnly);
                    _loadHistory();
                  },
                  tooltip: _showFavoritesOnly
                      ? 'Afficher tous les designs'
                      : 'Afficher uniquement les favoris',
                ),
              ),
            ],
          ),

          // Main content
          SliverToBoxAdapter(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.accentGold,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Chargement de vos designs...',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_designs.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: RefreshIndicator(
        backgroundColor: AppTheme.secondaryDark,
        color: AppTheme.accentGold,
        onRefresh: _loadHistory,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
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

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.secondaryDark.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                color: AppTheme.accentCream,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'Une erreur est survenue',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppTheme.accentGold.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowShadow(color: AppTheme.accentGold),
              ),
              child: Icon(
                _showFavoritesOnly 
                  ? Icons.favorite_outline_rounded 
                  : Icons.auto_awesome_mosaic_rounded,
                size: 60,
                color: _showFavoritesOnly
                  ? Colors.red.withOpacity(0.8)
                  : AppTheme.accentGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _showFavoritesOnly
                  ? 'Aucun favori pour le moment'
                  : 'Aucun design créé',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                color: AppTheme.accentCream,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _showFavoritesOnly
                  ? 'Marquez vos designs préférés avec le cœur'
                  : 'Commencez à créer votre premier design !',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignCard(Map<String, dynamic> design) {
    final generatedImagePath = design['generated_image_path'] as String?;
    final isFavorite = design['is_favorite'] == true;
    
    return Container(
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image avec bordure élégante
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DesignDetailScreen(design: design),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accentGold.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: generatedImagePath != null
                          ? Image.network(
                              _getImageUrl(generatedImagePath),
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: AppTheme.accentGold,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.secondaryDark.withOpacity(0.5),
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      size: 40,
                                      color: AppTheme.accentWarm.withOpacity(0.5),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppTheme.secondaryDark.withOpacity(0.5),
                              child: Center(
                                child: Icon(
                                  Icons.photo_size_select_actual_rounded,
                                  size: 40,
                                  color: AppTheme.accentWarm.withOpacity(0.5),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // Informations
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        design['room_type']?.toString().toUpperCase() ?? 'SALON',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppTheme.primaryDark,
                          fontSize: 12,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        design['style']?.toString() ?? 'Style Moderne',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryDark.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Boutons d'action (positionnés en absolu)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton favori
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.red : AppTheme.accentCream,
                      size: 20,
                    ),
                    onPressed: () {
                      final designId = design['id'] as int?;
                      if (designId != null) {
                        _toggleFavorite(designId, !isFavorite);
                      }
                    },
                    padding: const EdgeInsets.all(6),
                    splashRadius: 16,
                  ),
                ],
              ),
            ),
          ),

          // Bouton supprimer (en bas à droite)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.errorRed,
                  size: 20,
                ),
                onPressed: () {
                  final designId = design['id'] as int?;
                  if (designId != null) {
                    _deleteDesign(designId);
                  }
                },
                padding: const EdgeInsets.all(6),
                splashRadius: 16,
              ),
            ),
          ),

          // Badge favori sur l'image (si favori)
          if (isFavorite) ...[
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Favori',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}