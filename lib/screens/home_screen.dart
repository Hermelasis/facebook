import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import '../widgets/stories_section.dart';
import '../widgets/post_card.dart';

class FacebookHomeScreen extends StatefulWidget {
  const FacebookHomeScreen({super.key});

  @override
  State<FacebookHomeScreen> createState() => _FacebookHomeScreenState();
}

class _FacebookHomeScreenState extends State<FacebookHomeScreen> {
  @override
  Widget build(BuildContext context) {
    const facebookBlue = Color(0xFF1877F2);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: Colors.white,
                title: const Text(
                  'facebook',
                  style: TextStyle(
                    color: facebookBlue,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.2,
                  ),
                ),
                centerTitle: false,
                floating: true,
                snap: true,
                actions: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey[200], shape: BoxShape.circle),
                    child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SearchScreen()));
                        }),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey[200], shape: BoxShape.circle),
                    child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: () {}),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50.0),
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavIcon(Icons.home, true, badge: '15+'),
                        _buildNavIcon(Icons.people_outline, false),
                        _buildNavIcon(Icons.chat_bubble_outline, false,
                            badge: '15+'), // Messenger
                        _buildNavIcon(Icons.ondemand_video, false,
                            badge: '15+'),
                        _buildNavIcon(Icons.notifications_none, false,
                            badge: '15+'),
                        _buildNavIcon(Icons.storefront_outlined, false,
                            badge: '1'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const CreatePostBar(),
              const SizedBox(height: 10),
              const StoriesBar(),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: Supabase.instance.client
                    .from('posts')
                    .select()
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No posts yet. Be the first to post!"),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return PostWidget(post: posts[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, bool isActive, {String? badge}) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon,
              color: isActive ? const Color(0xFF1877F2) : Colors.grey[600],
              size: 28),
          onPressed: () {},
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }
}

class CreatePostBar extends StatelessWidget {
  const CreatePostBar({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: userId == null
                ? const CircleAvatar(
                    radius: 20.0,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  )
                : FutureBuilder<Map<String, dynamic>?>(
                    future: Supabase.instance.client
                        .from('profiles')
                        .select('avatar_url')
                        .eq('id', userId)
                        .maybeSingle(),
                    builder: (context, snapshot) {
                      final avatarUrl = snapshot.data?['avatar_url'];
                      return CircleAvatar(
                        radius: 20.0,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: (avatarUrl != null &&
                                avatarUrl.toString().isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null ||
                                avatarUrl.toString().isEmpty)
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      );
                    },
                  ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text('What\'s on your mind?',
                    style: TextStyle(color: Colors.black54)),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.photo, color: Colors.green, size: 28),
              Text("Photo",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
            ],
          ),
        ],
      ),
    );
  }
}
