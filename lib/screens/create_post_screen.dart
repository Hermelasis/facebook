import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  bool _isPosting = false;

  Future<void> _submitPost() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('posts').insert({
        'content': content,
        'user_id': userId,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost, 
            child: _isPosting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('POST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             TextField(
               controller: _textController,
               decoration: const InputDecoration(
                 hintText: "What's on your mind?",
                 border: InputBorder.none,
               ),
               maxLines: 10,
               autofocus: true,
             )
          ],
        ),
      ),
    );
  }
}
