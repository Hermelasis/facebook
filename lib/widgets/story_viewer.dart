import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const StoryViewer({
    super.key, 
    required this.stories, 
    this.initialIndex = 0
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _controller;
  String? _userName;
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 5)
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _loadStoryDetails();
    _controller.forward();
  }

  void _loadStoryDetails() async {
    final story = widget.stories[_currentIndex];
    final userId = story['user_id'];
    
    // Reset details
    setState(() {
      _userName = null;
      _userAvatar = null;
    });

    // Fetch user details for the header
    final data = await Supabase.instance.client
        .from('profiles')
        .select('full_name, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    if (mounted && data != null) {
      setState(() {
        _userName = data['full_name'];
        _userAvatar = data['avatar_url'];
      });
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
         _currentIndex++;
         _controller.reset();
         _loadStoryDetails();
         _controller.forward();
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
             // Prev
             if (_currentIndex > 0) {
                setState(() {
                  _currentIndex--;
                  _controller.reset();
                  _loadStoryDetails();
                  _controller.forward();
                });
             }
          } else {
             // Next
             _nextStory();
          }
        },
        child: Stack(
          children: [
            // Image
            Center(
              child: Image.network(
                story['image_url'],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                   if (loadingProgress == null) return child;
                   return const CircularProgressIndicator(color: Colors.white);
                },
                errorBuilder: (c, e, s) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
            
            // Progress Bar
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Row(
                children: widget.stories.asMap().entries.map((entry) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: LinearProgressIndicator(
                        value: entry.key < _currentIndex 
                             ? 1.0 
                             : (entry.key == _currentIndex ? _controller.value : 0.0),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 2,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Header
            Positioned(
              top: 55,
              left: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _userAvatar != null ? NetworkImage(_userAvatar!) : null,
                    backgroundColor: Colors.grey,
                    radius: 20,
                    child: _userAvatar == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _userName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
            
            // Close Button
            Positioned(
              top: 55,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
