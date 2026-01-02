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
//                         '${ApiConfig.baseUrl}/static/$generatedImagePath',
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




// lib/features/history/presentation/widgets/design_card.dart

import 'package:flutter/material.dart';
import 'package:interior_design/features/history/domain/entities/design_entity.dart';
import 'package:interior_design/core/config/api_config.dart';

class DesignCard extends StatelessWidget {
  final DesignEntity design;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;

  const DesignCard({
    Key? key,
    required this.design,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            // Image section
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: _buildImage(),
              ),
            ),

            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDesignInfo(),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (design.generatedImagePath == null) {
      return _buildPlaceholderImage();
    }

    return Image.network(
      '${ApiConfig.baseUrl}/static/${design.generatedImagePath}',
      fit: BoxFit.cover,
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
        return _buildPlaceholderImage();
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.image,
        size: 50,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildDesignInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          design.roomType ?? 'Room',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          design.style ?? 'Style',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            design.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: design.isFavorite ? Colors.red : Colors.grey,
            size: 20,
          ),
          onPressed: onFavoriteToggle,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 20,
          ),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}