import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Profile ---
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _client.from('profiles').update(user.toJson()).eq('id', user.id);
  }

  // --- Friends System ---
  
  // Send Friend Request
  Future<void> sendFriendRequest(String requesterId, String receiverId) async {
    await _client.from('friends').insert({
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': 'pending',
    });
  }

  // Accept Friend Request
  Future<void> acceptFriendRequest(String requestId) async {
    await _client.from('friends').update({'status': 'accepted'}).eq('id', requestId);
  }
  
  // Reject/Delete Friend Request
  Future<void> removeFriend(String requestId) async {
    await _client.from('friends').delete().eq('id', requestId);
  }

  // Get Friend Count
  Future<int> getFriendCount(String userId) async {
    // Count where user is requester OR receiver AND status is accepted
    // Supabase allows OR filters.
    // 'status.eq.accepted,and(requester_id.eq.$userId,receiver_id.eq.$userId)'... tricky with simple syntax.
    // Easier two queries or a function. Let's do two queries for now or RPC if we had it.
    
    final count1 = await _client
        .from('friends')
        .select('id')
        .eq('status', 'accepted')
        .eq('requester_id', userId)
        .count(); // actually we need .count(CountOption.exact) structure usually
        
     final response1 = await _client.from('friends').select('id').eq('status', 'accepted').eq('requester_id', userId);
     final response2 = await _client.from('friends').select('id').eq('status', 'accepted').eq('receiver_id', userId);

     return response1.length + response2.length;
  }

  // Check Friend Status between two users
  Future<String> checkFriendStatus(String currentUserId, String targetUserId) async {
    // Check if I sent request
    final sent = await _client.from('friends')
        .select()
        .eq('requester_id', currentUserId)
        .eq('receiver_id', targetUserId)
        .maybeSingle();
    
    if (sent != null) return sent['status']; // 'pending' or 'accepted'

    // Check if they sent request
    final received = await _client.from('friends')
        .select()
        .eq('requester_id', targetUserId)
        .eq('receiver_id', currentUserId)
        .maybeSingle();
    
    if (received != null) {
      return received['status'] == 'pending' ? 'received_pending' : 'accepted';
    }

    return 'none';
  }

  // --- Posts ---
  Future<int> getPostCount(String userId) async {
    final res = await _client.from('posts').select('id').eq('user_id', userId);
    return res.length;
  }

  // Get Friend List (Top 6 for Grid)
  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    try {
      // Friends where userId is requester
      final sentAccepted = await _client.from('friends')
          .select('receiver_id, profiles!receiver_id(full_name, avatar_url)')
          .eq('requester_id', userId)
          .eq('status', 'accepted')
          .limit(6);
      
      // Friends where userId is receiver
      final receivedAccepted = await _client.from('friends')
          .select('requester_id, profiles!requester_id(full_name, avatar_url)')
          .eq('receiver_id', userId)
          .eq('status', 'accepted')
          .limit(6);

      final friends = <Map<String, dynamic>>[];
      
      for (var f in sentAccepted) {
         if (f['profiles'] != null) {
           friends.add({
             'id': f['receiver_id'],
             'name': f['profiles']['full_name'],
             'img': f['profiles']['avatar_url'] ?? 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
           });
         }
      }
      for (var f in receivedAccepted) {
         if (f['profiles'] != null) {
           friends.add({
             'id': f['requester_id'],
             'name': f['profiles']['full_name'],
             'img': f['profiles']['avatar_url'] ?? 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
           });
         }
      }
      
      return friends.take(6).toList();
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }
}
