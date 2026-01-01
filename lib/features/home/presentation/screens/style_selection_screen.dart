import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/style_card.dart';
import '../providers/style_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../upload/presentation/screens/upload_screen.dart';

class StyleSelectionScreen extends ConsumerStatefulWidget {
  const StyleSelectionScreen({super.key});

  @override
  ConsumerState<StyleSelectionScreen> createState() =>
      _StyleSelectionScreenState();
}

class _StyleSelectionScreenState extends ConsumerState<StyleSelectionScreen> {
  // List of interior design styles with descriptions
  final List<Map<String, String>> styles = [
    {
      'title': 'Minimalist',
      'description':
          'Clean, simple, clutter-free spaces with focus on essentials',
      'image':
          'https://plus.unsplash.com/premium_photo-1670358808227-590942cd18cb?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8bWluaW1hbGlzdCUyMHJvb218ZW58MHx8MHx8fDA%3D',
    },
    {
      'title': 'Cozy',
      'description':
          'Warm, comfortable, and inviting spaces with soft textures',
      'image':
          'https://images.unsplash.com/photo-1615873968403-89e068629265?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Modern',
      'description': 'Sleek, contemporary design with geometric shapes',
      'image':
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w-600&auto=format&fit=crop',
    },
    {
      'title': 'Industrial',
      'description': 'Raw, edgy aesthetic with exposed elements and urban vibe',
      'image':
          'https://images.unsplash.com/photo-1495433324511-bf8e92934d90?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Scandinavian',
      'description': 'Light, natural, and functional with minimalist touch',
      'image':
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Bohemian',
      'description': 'Colorful, eclectic, and artistic with global influences',
      'image':
          'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=600&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedStyle = ref.watch(selectedStyleProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Choose Your Style',
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
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.secondaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Select an interior design style',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentCream,
                              fontFamily: 'PlayfairDisplay',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your AI will transform your room based on this style',
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

                    // Grid of Style Cards
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: styles.length,
                      itemBuilder: (context, index) {
                        final style = styles[index];
                        return StyleCard(
                          title: style['title']!,
                          description: style['description']!,
                          imageUrl: style['image']!,
                          isSelected: selectedStyle == style['title'],
                          onTap: () {
                            ref.read(selectedStyleProvider.notifier).setStyle(
                                style['title']);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Next Button (sticky at bottom)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.accentGold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(
                        selectedStyle != null ? 0.4 : 0.2,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: selectedStyle != null
                      ? () {
                          // Navigate to upload screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UploadScreen(),
                            ),
                            
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedStyle != null
                        ? AppTheme.accentGold
                        : AppTheme.secondaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Upload',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: selectedStyle != null
                            ? Colors.white
                            : AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}