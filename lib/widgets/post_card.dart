import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostWidget({super.key, required this.post});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  String _userName = 'Facebook User';
  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';

  @override
  void initState() {
    super.initState();
    // Prioritize 'profiles' join if available, else fetch
    if (widget.post['profiles'] != null && widget.post['profiles']['full_name'] != null) {
       _userName = widget.post['profiles']['full_name'];
    } else {
      _fetchUserProfile();
    }
    _fetchInteractions();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = widget.post['user_id'];
      if (userId != null && userId is String) { 
        final data = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', userId)
            .maybeSingle(); 
        
        if (data != null && data['full_name'] != null) {
          if (mounted) {
            setState(() {
              _userName = data['full_name'];
            });
          }
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _fetchInteractions() async {
    final dynamic postId = widget.post['id'];
    try {
      final likesList = await Supabase.instance.client.from('likes').select('user_id').eq('post_id', postId);
      final commentsList = await Supabase.instance.client.from('comments').select('id').eq('post_id', postId);

      if (mounted) {
         setState(() {
           _likeCount = likesList.length;
           _commentCount = commentsList.length;
           _isLiked = likesList.any((l) => l['user_id'] == _userId);
         });
      }
    } catch (e) {
      print('Error interactions: $e');
    }
  }

  Future<void> _toggleLike() async {
    final dynamic postId = widget.post['id'];
    
    // Optimistic Update
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await Supabase.instance.client.from('likes').insert({
          'user_id': _userId,
          'post_id': postId,
        });
      } else {
        await Supabase.instance.client.from('likes').delete().match({
          'user_id': _userId,
          'post_id': postId,
        });
      }
    } catch (e) {
      // Revert if error
      if (mounted) {
        setState(() {
           _isLiked = !_isLiked;
           _likeCount += _isLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error liking: $e')));
      }
    }
  }

  void _showCommentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentsSheet(postId: widget.post['id']),
    ).then((_) => _fetchInteractions()); 
  }

  void _sharePost() {
    final content = widget.post['content'] ?? 'Check out this post!';
    Share.share(content);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20.0,
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            widget.post['created_at'] != null 
                                ? widget.post['created_at'].toString().substring(0, 10) 
                                : 'Just now', 
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12.0,
                            ),
                          ),
                          const Icon(Icons.public, size: 12.0, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
            child: Text(
              widget.post['content'] ?? '',
            ),
          ),
          if (widget.post['image_url'] != null)
             AspectRatio(
              aspectRatio: 1.0,
              child: Image.network(
                widget.post['image_url'], 
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Center(child: Icon(Icons.error)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                     Container(
                       padding: const EdgeInsets.all(4.0),
                       decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
                       child: const Icon(Icons.thumb_up, size: 10.0, color: Colors.white),
                     ),
                     const SizedBox(width: 4.0),
                     Text('$_likeCount'),
                  ],
                ),
                Text('$_commentCount Comments'),
              ],
            ),
          ),
          const Divider(height: 10.0, thickness: 0.5),
           SizedBox(
            height: 40.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ActionItem(
                  icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: 'Like',
                  color: _isLiked ? const Color(0xFF1877F2) : Colors.grey,
                  onTap: _toggleLike,
                ),
                ActionItem(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  color: Colors.grey,
                  onTap: _showCommentsModal,
                ),
                ActionItem(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: Colors.grey,
                  onTap: _sharePost,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const ActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.0),
          const SizedBox(width: 4.0),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  final dynamic postId;
  const CommentsSheet({super.key, required this.postId});
  
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();

  Future<void> _postComment() async {
     final text = _commentController.text.trim();
     if(text.isEmpty) return;
     
     final userId = Supabase.instance.client.auth.currentUser!.id;
     await Supabase.instance.client.from('comments').insert({
       'content': text,
       'post_id': widget.postId,
       'user_id': userId,
     });
     _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>> (
              stream: Supabase.instance.client.from('comments').stream(primaryKey: ['id']).eq('post_id', widget.postId).order('created_at'),
              builder: (context, snapshot) {
                 if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                 final comments = snapshot.data!;
                 if(comments.isEmpty) return const Center(child: Text("No comments yet."));
                 
                 return ListView.builder(
                   itemCount: comments.length,
                   itemBuilder: (context, index) {
                     final c = comments[index];
                     return ListTile(
                       leading: const CircleAvatar(child: Icon(Icons.person)),
                       title: Text(c['content']), 
                     );
                   },
                 );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _postComment,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
