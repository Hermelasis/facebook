import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart'; 
import 'edit_profile_screen.dart';
import 'search_screen.dart';
import '../widgets/post_card.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Optional: If null, show current user
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  late String _targetUserId;
  
  UserModel? _userModel;
  bool _isLoading = true;
  
  // Friends System State
  String _friendStatus = 'none'; // 'none', 'pending', 'received_pending', 'accepted'
  int _friendCount = 0;
  List<Map<String, dynamic>> _friends = [];

  // Navigation
  final int _selectedIndex = 0; // 0 = Profile (Current), but we want a global nav? 
  // If we want nav to work, we usually wrap everything in a Scaffold with BottomNavBar.
  // But since we are navigating TO this page, we can just add a BottomNavBar that pushes to Home.
  // Alternatively, we treat this as a tab in a main shell.
  // Given the "First Page is Profile" requirement, let's keep it simple:
  // Add Bottom Nav. Tapping "Home" pushes Replacement to HomeScreen.

  @override
  void initState() {
    super.initState();
    _targetUserId = widget.userId ?? _currentUserId;
    _fetchProfile();
    _checkFriendship();
    _fetchStats();
  }

  Future<void> _fetchProfile() async {
    final user = await _dbService.getUserProfile(_targetUserId);
    if (mounted) {
      setState(() {
        _userModel = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStats() async {
    final count = await _dbService.getFriendCount(_targetUserId);
    final friends = await _dbService.getFriends(_targetUserId);
    if(mounted) {
      setState(() {
      _friendCount = count;
      _friends = friends;
    });
    }
  }

  Future<void> _checkFriendship() async {
    if (_targetUserId == _currentUserId) return;
    final status = await _dbService.checkFriendStatus(_currentUserId, _targetUserId);
    if(mounted) setState(() => _friendStatus = status);
  }

  Future<void> _handleFriendAction() async {
    if (_friendStatus == 'none') {
      await _dbService.sendFriendRequest(_currentUserId, _targetUserId);
      setState(() => _friendStatus = 'pending');
    } else if (_friendStatus == 'received_pending') {
      // We need criteria to accept. Ideally we fetch the request ID.
      // Simplify: DatabaseService could accept IDs, but let's stick to simple logic for now or update Service to find ID.
      // Update: I defined `acceptFriendRequest` taking `requestId`. 
      // I need to fetch that ID first.
       final res = await Supabase.instance.client.from('friends').select('id').eq('requester_id', _targetUserId).eq('receiver_id', _currentUserId).single();
       await _dbService.acceptFriendRequest(res['id']);
       setState(() => _friendStatus = 'accepted');
       _fetchStats(); // Update count
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(initialData: _userModel?.toJson() ?? {})),
    );
    if (result == true) {
      _fetchProfile(); 
    }
  }
  
  void _onBottomNavTapped(int index) {
      // 0 = Home, 1 = Friends (Profile), ...
      // Just a simple switcher for demo
      if (index == 0) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FacebookHomeScreen()));
      }
      // If index 4 (Profile), we are here.
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Defaults
    final String fullName = _userModel?.fullName ?? 'Facebook User';
    final String coverUrl = _userModel?.coverUrl ?? 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80';
    final String? avatarUrl = _userModel?.avatarUrl;
    
    final bio = _userModel?.bio ?? '';
    final location = _userModel?.location;
    final work = _userModel?.work;
    final relationship = _userModel?.relationshipStatus;

    final isMe = _targetUserId == _currentUserId;

    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(fullName, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            // If we are root (userId == null), maybe no back button? Or assume we can pop to login (which we prevented).
            onPressed: () {
               if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
              }
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Header (Cover + Avatar - Left Aligned) ---
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomLeft,
                children: [
                   Container(
                     height: 200,
                     width: double.infinity,
                     decoration: BoxDecoration(
                       image: DecorationImage(
                         image: NetworkImage(coverUrl),
                         fit: BoxFit.cover,
                       ),
                     ),
                   ),
                   Positioned(
                     bottom: -40,
                     left: 15,
                     child: Container(
                       padding: const EdgeInsets.all(4.0),
                       decoration: const BoxDecoration(
                         color: Colors.white,
                         shape: BoxShape.circle,
                       ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                        ),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 50),
              
              // --- 2. Name & Action Buttons ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text("$_friendCount friends", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (isMe) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {}, 
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text("Add to story"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1877F2), 
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _navigateToEditProfile,
                              icon: const Icon(Icons.edit, size: 20, color: Colors.black),
                              label: const Text("Edit profile", style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                        ] else ...[
                           // Friend Actions
                           Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _handleFriendAction,
                              icon: Icon(
                                _friendStatus == 'accepted' ? Icons.people : Icons.person_add, 
                                size: 20,
                              ),
                              label: Text(
                                _friendStatus == 'none' ? "Add Friend" :
                                _friendStatus == 'pending' ? "Requested" :
                                _friendStatus == 'received_pending' ? "Respond" : "Friends"
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1877F2), 
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                         Container(
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                          child: IconButton(
                            icon: const Icon(Icons.more_horiz, color: Colors.black),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // --- 3. Tabs ---
              const TabBar(
                labelColor: Color(0xFF1877F2),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF1877F2),
                tabs: [
                  Tab(text: "Posts"),
                  Tab(text: "Photos"),
                  Tab(text: "Reels"),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Details
                    if (bio.isNotEmpty) ...[
                       Text(bio, style: const TextStyle(fontSize: 16)),
                       const Divider(),
                    ],
                    if (location != null && location.isNotEmpty) _buildDetailRow(Icons.location_on, "From ", location),
                    if (work != null && work.isNotEmpty) _buildDetailRow(Icons.work, "Works at ", work),
                    if (relationship != null && relationship.isNotEmpty) _buildDetailRow(Icons.favorite, "", relationship),
                    _buildDetailRow(Icons.more_horiz, "See more about yourself", ""),
                    
                    const SizedBox(height: 20),
                    
                    // Friends Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Friends", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("See all", style: TextStyle(color: Colors.blue[700])),
                      ],
                    ),
                    Text("$_friendCount friends", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    _buildFriendsGrid(),
                    
                    const SizedBox(height: 20),
                     // Posts Header
                    const Text("Posts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    
                    // Create Post Area
                     Container(
                       margin: const EdgeInsets.symmetric(vertical: 10),
                       child: Row(
                         children: [
                             CircleAvatar(
                               radius: 20,
                               backgroundColor: Colors.grey[300],
                               backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                               child: (avatarUrl == null || avatarUrl.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
                             ),
                            const SizedBox(width: 10),
                            Expanded(child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                              child: const Text("Post a status update"),
                            )),
                            IconButton(onPressed: (){}, icon: const Icon(Icons.photo_library, color: Colors.green)),
                         ],
                       ),
                     ),
                  ],
                ),
              ),

               // --- 5. User Feed ---
              FutureBuilder<List<Map<String, dynamic>>>(
                future: Supabase.instance.client
                    .from('posts')
                    .select()
                    .eq('user_id', _targetUserId)
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final posts = snapshot.data!;
                  if (posts.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No posts yet.")));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) => PostWidget(post: posts[index]),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
           items: const [
             BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
             BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
           ],
           currentIndex: 1, // Profile selected
           onTap: _onBottomNavTapped,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String prefix, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 10),
           RichText(
             text: TextSpan(
               style: const TextStyle(color: Colors.black, fontSize: 16),
               children: [
                 TextSpan(text: prefix, style: const TextStyle(color: Colors.black)), // Regular
                 TextSpan(text: text, style: const TextStyle(fontWeight: FontWeight.bold)), // Bold Value
               ]
             )
           )
        ],
      ),
    );
  }

  Widget _buildFriendsGrid() {
    if (_friends.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text("No friends to show yet.", style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (_friends[index]['img'] != null && _friends[index]['img'].toString().isNotEmpty && !_friends[index]['img'].toString().contains('unsplash'))
                      ? Image.network(_friends[index]['img'], fit: BoxFit.cover, width: double.infinity)
                      : const Center(child: Icon(Icons.person, color: Colors.white, size: 40)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _friends[index]['name'], 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), 
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        );
      },
    );
  }
}
