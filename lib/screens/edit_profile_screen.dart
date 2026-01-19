import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';

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
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _bioController =
        TextEditingController(text: widget.initialData['bio'] ?? '');
    _locationController =
        TextEditingController(text: widget.initialData['location'] ?? '');
    _workController =
        TextEditingController(text: widget.initialData['work'] ?? '');
    _relationshipController = TextEditingController(
        text: widget.initialData['relationship_status'] ?? '');
    _usernameController = TextEditingController(
        text: widget.initialData['username'] ?? ''); // [NEW]
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
      final fileName =
          '$userId/$type-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await Supabase.instance.client.storage.from('story-images').uploadBinary(
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

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')));
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sign-out failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use stored values only; no hard-coded fallbacks
    final String? currentAvatarUrl =
        widget.initialData['avatar_url'] as String?;
    final String? currentCoverUrl = widget.initialData['cover_url'] as String?;
    final String nameSource = (widget.initialData['full_name'] ??
            widget.initialData['username'] ??
            '')
        .toString()
        .trim();
    final List<String> initialsParts =
        nameSource.split(' ').where((part) => part.isNotEmpty).toList();
    String fallbackInitial =
        initialsParts.map((part) => part[0].toUpperCase()).join();
    if (fallbackInitial.length > 2) {
      fallbackInitial = fallbackInitial.substring(0, 2);
    }

    // Resolve avatar and cover images to keep backgroundImage types consistent
    ImageProvider<Object>? avatarImage;
    if (_avatarFile != null) {
      avatarImage = FileImage(File(_avatarFile!.path));
    } else if (currentAvatarUrl != null) {
      avatarImage = NetworkImage(currentAvatarUrl);
    }

    DecorationImage? coverDecoration;
    if (_coverFile != null) {
      coverDecoration = DecorationImage(
        image: FileImage(File(_coverFile!.path)),
        fit: BoxFit.cover,
      );
    } else if (currentCoverUrl != null) {
      coverDecoration = DecorationImage(
        image: NetworkImage(currentCoverUrl),
        fit: BoxFit.cover,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SAVE',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold)),
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
              const Text("Profile Picture",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(false), // false = avatar
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: avatarImage,
                        child: (_avatarFile == null && currentAvatarUrl == null)
                            ? Text(
                                fallbackInitial.isNotEmpty
                                    ? fallbackInitial
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                        backgroundColor: Colors.blueGrey.shade300,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: Colors.grey, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Center(
                  child: Text("Edit", style: TextStyle(color: Colors.blue))),

              const Divider(height: 30),

              // Cover Section
              const Text("Cover Photo",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage(true), // true = cover
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    image: coverDecoration,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Edit",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 30),

              const Text("Bio",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextField(
                controller: _bioController,
                decoration:
                    const InputDecoration(hintText: "Describe yourself..."),
                maxLines: 2,
              ),

              const SizedBox(height: 20),
              const Text("Details",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

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

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isSaving || _isSigningOut) ? null : _onSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout),
                  label: Text(
                    _isSigningOut ? 'Signing out...' : 'Sign Out',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
