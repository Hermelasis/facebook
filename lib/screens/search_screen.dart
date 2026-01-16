import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    // Debounce could be added here, but for now direct call
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, username, avatar_url')
          .or('full_name.ilike.%$query%,username.ilike.%$query%')
          .limit(20);

      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search Facebook...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _searchResults.isEmpty 
              ? const Center(child: Text('Type to search for people')) 
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          user['avatar_url'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'
                        ),
                      ),
                      title: Text(user['full_name'] ?? 'Unknown'),
                      subtitle: user['username'] != null ? Text('@${user['username']}') : null,
                      onTap: () {
                        // Navigate to their profile
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => ProfileScreen(userId: user['id']))
                        );
                      },
                    );
                  },
                ),
    );
  }
}
