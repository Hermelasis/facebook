import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'story_viewer.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _addStory(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw 'Not logged in';

      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = '$userId/$fileName';

      await Supabase.instance.client.storage
          .from('story-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('story-images')
          .getPublicUrl(filePath);

      await Supabase.instance.client.from('stories').insert({
        'user_id': userId,
        'image_url': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding story: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openStory(List<Map<String, dynamic>> stories, int index) {
     Navigator.push(
       context,
       MaterialPageRoute(builder: (_) => StoryViewer(stories: stories, initialIndex: index)),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.0,
      color: Colors.white,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        // Fetch stories from last 24 hours
        stream: Supabase.instance.client
            .from('stories')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
            // Note: Filter > 24h ideally should be done on query if .stream supports check, 
            // but stream uses simple equality or requires specific filter syntax support depending on package version.
            // We'll filter client side for stream simplicity if needed, but 'order' works.
            // Supabase Stream filters are limited. Let's filter in the builder.
            
        builder: (context, snapshot) {
          // Filter 24h client side
          final allStories = snapshot.data ?? [];
          final stories = allStories.where((s) {
            final createdAt = DateTime.tryParse(s['created_at'].toString());
            if (createdAt == null) return false;
            return DateTime.now().difference(createdAt).inHours < 24;
          }).toList();
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 1 + stories.length, // +1 for "Add Story" card
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: _isUploading ? null : () => _addStory(context),
                  child: Stack(
                    children: [
                      const StoryCard(isAddStory: true),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black45,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return GestureDetector(
                onTap: () => _openStory(stories, index - 1),
                child: StoryCard(story: stories[index - 1]),
              );
            },
          );
        },
      ),
    );
  }
}

class StoryCard extends StatelessWidget {
  final bool isAddStory;
  final Map<String, dynamic>? story;

  const StoryCard({super.key, this.isAddStory = false, this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      width: 110.0,
      decoration: BoxDecoration(
        color: isAddStory ? Colors.white : Colors.grey[300],
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
           BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: isAddStory
            ? _buildAddStoryCard() 
            : _buildStoryCard(), 
      ),
    );
  }

  Widget _buildAddStoryCard() {
    return Column(
      children: [
        Expanded(
          flex: 3, 
          child: Image.network(
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        Expanded(
          flex: 2, 
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 20),
                alignment: Alignment.center,
                child: const Text(
                  'Create story',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -16), 
                child: Container(
                  padding: const EdgeInsets.all(2), 
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Container(
                     width: 32,
                     height: 32,
                     decoration: const BoxDecoration(
                       color: Color(0xFF1877F2),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCard() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(story!['image_url'] ?? ''),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // [TODO] To make this real, we should fetch the user avatar using user_id
        // For now, let's just use a placeholder or if we joined tables.
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1877F2), width: 3.0),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Text(
            'Friend',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
