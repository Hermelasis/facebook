import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditProfileScreen({super.key, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _workController;
  late TextEditingController _relationshipController;
  late TextEditingController _usernameController; // [NEW]
  
  final ImagePicker _picker = ImagePicker();
  XFile? _avatarFile;
  XFile? _coverFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.initialData['bio'] ?? '');
    _locationController = TextEditingController(text: widget.initialData['location'] ?? '');
    _workController = TextEditingController(text: widget.initialData['work'] ?? '');
    _relationshipController = TextEditingController(text: widget.initialData['relationship_status'] ?? '');
    _usernameController = TextEditingController(text: widget.initialData['username'] ?? ''); // [NEW]
  }

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    _workController.dispose();
    _relationshipController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // ... (Image Picking logic remains same - omitting for brevity if not changing, but replace_file requires full context block usually or careful constraints)
  // To avoid huge replacement, I'll assume _pickImage and _uploadImage are unchanged.
  // Wait, I can only replace CONTIGUOUS blocks.
  // I need to be careful. I will replace the build method primarily and the top part.
  
  // Re-implementing helper methods to be safe in a big replacement or I can use multiple chunks if I trust context.
  // Let's replace the whole class content to be safe and clean.
  
  Future<void> _pickImage(bool isCover) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() {
        if (isCover) {
          _coverFile = image;
        } else {
          _avatarFile = image;
        }
      });
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage(XFile file, String userId, String type) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '$userId/$type-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      await Supabase.instance.client.storage
          .from('story-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return Supabase.instance.client.storage
          .from('story-images')
          .getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading $type: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return; // Validate

    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final updates = {
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'work': _workController.text.trim(),
        'relationship_status': _relationshipController.text.trim(),
        'username': _usernameController.text.trim(), // [NEW]
      };

      // Upload and add Avatar if changed
      if (_avatarFile != null) {
        final avatarUrl = await _uploadImage(_avatarFile!, userId, 'avatar');
        if (avatarUrl != null) {
          updates['avatar_url'] = avatarUrl;
        }
      }

      // Upload and add Cover if changed
      if (_coverFile != null) {
        final coverUrl = await _uploadImage(_coverFile!, userId, 'cover');
        if (coverUrl != null) {
          updates['cover_url'] = coverUrl;
        }
      }

      await Supabase.instance.client.from('profiles').update(updates).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current display images
    final currentAvatarUrl = widget.initialData['avatar_url'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80';
    final currentCoverUrl = widget.initialData['cover_url'] ?? 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('SAVE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              const Text("Profile Picture", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(false), // false = avatar
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _avatarFile != null 
                            ? FileImage(File(_avatarFile!.path)) 
                            : NetworkImage(currentAvatarUrl) as ImageProvider,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Center(child: Text("Edit", style: TextStyle(color: Colors.blue))),
              
              const Divider(height: 30),
               
              // Cover Section
              const Text("Cover Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(true), // true = cover
                child: Container(
                   height: 150,
                   width: double.infinity,
                   decoration: BoxDecoration(
                     color: Colors.grey[300],
                     borderRadius: BorderRadius.circular(8),
                     image: DecorationImage(
                       image: _coverFile != null 
                           ? FileImage(File(_coverFile!.path))
                           : NetworkImage(currentCoverUrl) as ImageProvider,
                       fit: BoxFit.cover,
                     )
                   ),
                   alignment: Alignment.center,
                   child: Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                     child: const Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(Icons.camera_alt, color: Colors.white),
                         SizedBox(width: 8),
                         Text("Edit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                ),
              ),
              
              const Divider(height: 30),

              const Text("Bio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(hintText: "Describe yourself..."),
                maxLines: 2,
              ),

              const SizedBox(height: 20),
              const Text("Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              
              const SizedBox(height: 10),
              // [NEW] Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value)) {
                    return 'Only letters, numbers, underscores and dots';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Current Town/City",
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
              ),
               const SizedBox(height: 10),
              TextField(
                controller: _workController,
                decoration: const InputDecoration(
                  labelText: "Workplace",
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
              ),
               const SizedBox(height: 10),
              TextField(
                controller: _relationshipController,
                decoration: const InputDecoration(
                  labelText: "Relationship Status",
                  prefixIcon: Icon(Icons.favorite),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
