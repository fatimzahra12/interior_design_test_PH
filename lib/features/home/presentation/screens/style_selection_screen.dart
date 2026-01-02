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
    // 🎀 Soft & Girly Styles
    {
      'title': 'Soft Girly',
      'description': 'Pastel colors, blush pink, soft lighting, delicate decor',
      'image': 'https://th.bing.com/th/id/R.993bd0c74f51959597e12fc0c5d539a4?rik=RoV4EjAyqMDJPQ&pid=ImgRaw&r=0',
    },
    {
      'title': 'Coquette Style',
      'description': 'Bows, lace details, vintage mirrors, romantic pink tones',
      'image': 'https://images.squarespace-cdn.com/content/v1/63dde481bbabc6724d988548/8b268845-fd76-4508-b678-584ab97b626e/_d29167c0-7c63-4ad3-ad31-6ce3ef6e22fa.jpg',
    },
    {
      'title': 'Princess Style',
      'description': 'Elegant furniture, canopy bed, gold accents',
      'image': 'https://th.bing.com/th/id/R.22c7e9801c0787512570632c7d293b02?rik=%2buDnzVsmp6hK4w&pid=ImgRaw&r=0',
    },
    {
      'title': 'Korean Girly Minimal',
      'description': 'Pastel beige, low furniture, cozy and clean',
      'image': 'https://th.bing.com/th/id/R.42368189bb773eb7ab5c388b8fe2d170?rik=ffsWB8xKMsKPEg&pid=ImgRaw&r=0',
    },
    {
      'title': 'Barbiecore',
      'description': 'Bold pinks, playful furniture, glossy finishes',
      'image': 'https://tidymalism.com/wp-content/uploads/2023/06/barbie-dreamhouse-barbiecore-aesthetic-by-tidymalism-1024x574.jpeg.webp',
    },
    
    // 🧸 Childish / Playful Styles
    {
      'title': 'Childish ',
      'description': 'Bright colors, cartoon decor, soft textures',
      'image': 'https://www.thespruce.com/thmb/BWd873UxZN4O0eqIX9pR8Mgi7JI=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/54.-Westport-Modern-Farmhouse-by-Chango--Co.---Playroom-f07d90f13aea4f6d94e82e705483cd9e.jpg',
    },
    {
      'title': 'Cute Kawaii Style',
      'description': 'Pastel colors, cute characters, rounded furniture',
      'image': 'https://i.pinimg.com/originals/a9/f8/f5/a9f8f5abf28aafb4b622da3a02a4894f.jpg',
    },
    {
      'title': 'Toyland Theme',
      'description': 'Colorful shelves, toy-inspired decor, fun patterns',
      'image': 'https://dreamvacationinteriors.com/wp-content/uploads/2020/09/2842-Storey-Lake-toy-story-4.jpg',
    },
    {
      'title': 'Nursery Style',
      'description': 'Soft colors, animal illustrations, cozy lighting',
      'image': 'https://cdn.decorilla.com/online-decorating/wp-content/uploads/2019/03/nursery-interior-design-pink.jpg',
    },
    {
      'title': 'Fantasy Kids Room',
      'description': 'Stars, clouds, castles, magical elements',
      'image': 'https://img.freepik.com/premium-photo/kids-treehouse-bedroom-fantasy-interior-design_942407-187.jpg',
    },
    
    // 🌿 Calm & Cozy Styles
    {
      'title': 'Cozy Minimalist',
      'description': 'Neutral colors, warm lights, simple furniture',
      'image': 'https://mir-s3-cdn-cf.behance.net/project_modules/1400/f64356187459249.65897a385bc35.jpg',
    },
    {
      'title': 'Scandinavian',
      'description': 'White tones, wood textures, clean and cozy',
      'image': 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Japandi',
      'description': 'Japanese + Scandinavian, calm, earthy, minimal',
      'image': 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Boho Chic',
      'description': 'Natural materials, plants, warm colors',
      'image': 'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Soft Cottagecore',
      'description': 'Floral patterns, vintage furniture, cozy vibes',
      'image': 'https://images.unsplash.com/photo-1615873968403-89e068629265?w=600&auto=format&fit=crop',
    },
    
    // 🎨 Creative & Aesthetic Styles
    {
      'title': 'Artistic Studio',
      'description': 'Creative decor, paintings, expressive colors',
      'image': 'https://images.unsplash.com/photo-1495433324511-bf8e92934d90?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Modern Aesthetic',
      'description': 'Clean lines, neutral colors, Instagram-style',
      'image': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Vintage Pastel',
      'description': 'Retro furniture, pastel tones, soft lighting',
      'image': 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Dreamcore',
      'description': 'Surreal elements, soft glows, dreamy atmosphere',
      'image': 'https://images.unsplash.com/photo-1631889993959-41b4e9c6e3c5?w=600&auto=format&fit=crop',
    },
    {
      'title': 'Fairycore',
      'description': 'Nature-inspired, fairy lights, magical soft colors',
      'image': 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=600&auto=format&fit=crop',
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