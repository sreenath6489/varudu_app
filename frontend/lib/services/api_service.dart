import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    // Expose backend publicly via ngrok for testing on physical devices and emulator
    return 'https://rocklike-cylinder-countless.ngrok-free.dev';
  }

  String? _token;
  String? get token => _token;

  // Initialize and load token from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token to memory and local storage
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token from memory and local storage
  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Request OTP
  Future<Map<String, dynamic>> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to send OTP');
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final token = data['token'];
      if (token != null) {
        await setToken(token);
      }
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to verify OTP');
    }
  }

  // Submit / Create / Update profile with complete fields
  Future<Map<String, dynamic>> createProfile({
    required String name,
    required String city,
    required int age,
    required DateTime dob,
    required String gender,
    required String interestedIn,
    String? tob,
    String? pob,
    String? subCaste,
    String? gothram,
    String? rasi,
    String? star,
    String? education,
    String? occupation,
    Map<String, dynamic>? familyDetails,
    List<File>? photos,
  }) async {
    final uri = Uri.parse('$baseUrl/api/profile');
    final request = http.MultipartRequest('POST', uri);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // Standard fields
    request.fields['name'] = name;
    request.fields['city'] = city;
    request.fields['age'] = age.toString();
    request.fields['dob'] = "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";
    request.fields['gender'] = gender;
    request.fields['interestedIn'] = interestedIn;

    // Advanced onboarding fields
    if (tob != null) request.fields['tob'] = tob;
    if (pob != null) request.fields['pob'] = pob;
    if (subCaste != null) request.fields['subCaste'] = subCaste;
    if (gothram != null) request.fields['gothram'] = gothram;
    if (rasi != null) request.fields['rasi'] = rasi;
    if (star != null) request.fields['star'] = star;
    if (education != null) request.fields['education'] = education;
    if (occupation != null) request.fields['occupation'] = occupation;
    if (familyDetails != null) {
      request.fields['familyDetails'] = jsonEncode(familyDetails);
    }

    // Add multiple photo files if present
    if (photos != null && photos.isNotEmpty) {
      for (final file in photos) {
        final multipartFile = await http.MultipartFile.fromPath(
          'photos',
          file.path,
        );
        request.files.add(multipartFile);
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to save profile');
    }
  }

  // Fetch current profile
  Future<Map<String, dynamic>> getProfile() async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/profile'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch profile');
    }
  }

  // Search profiles
  Future<List<dynamic>> searchProfiles(String query) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/api/search').replace(
      queryParameters: {'query': query},
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to search profiles');
    }
  }

  // Express interest (like profile - legacy)
  Future<Map<String, dynamic>> expressInterest(String profileId) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/interests'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'interestedProfileId': profileId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to express interest');
    }
  }

  // Get profiles that current user expressed interest in
  Future<List<dynamic>> getInterests() async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/interests'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to fetch interests');
    }
  }

  // Swipe Action (standard vs rose)
  Future<Map<String, dynamic>> swipeProfile({
    required String receiverId,
    required String status,
    String interactionType = 'standard',
    String? attachedMessage,
  }) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/interests/swipe'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'receiver_id': receiverId,
        'status': status,
        'interaction_type': interactionType,
        if (attachedMessage != null) 'attached_message': attachedMessage,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to record swipe');
    }
  }

  // Get Requests (received & sent lists)
  Future<Map<String, dynamic>> getRequests() async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/interests/requests'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to fetch requests');
    }
  }

  // Accept a received interest
  Future<Map<String, dynamic>> acceptInterest(String interestId) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/interests/accept'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'interestId': interestId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to accept interest');
    }
  }

  // Decline a received interest
  Future<Map<String, dynamic>> declineInterest(String interestId) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/interests/decline'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'interestId': interestId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to decline interest');
    }
  }

  // Withdraw a sent interest
  Future<Map<String, dynamic>> withdrawInterest(String interestId) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/interests/withdraw'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'interestId': interestId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to withdraw interest');
    }
  }

  // Get all matched connections with unlock metadata
  Future<List<dynamic>> getMatches() async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/interests/matches'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data as List<dynamic>;
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch matches');
    }
  }

  // Unlock chat by spending 1 rose
  Future<Map<String, dynamic>> unlockChat(String interestId) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/interests/unlock'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'interestId': interestId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to unlock chat');
    }
  }

  // Face verification upload
  Future<Map<String, dynamic>> verifyFace(File selfie) async {
    if (_token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$baseUrl/api/profile/verify-face');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $_token';

    request.files.add(
      await http.MultipartFile.fromPath('selfie', selfie.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Face verification failed');
    }
  }

  // Aadhaar verification
  Future<Map<String, dynamic>> verifyAadhaar(String aadhaarNumber) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/profile/verify-aadhaar'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'aadhaarNumber': aadhaarNumber}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Aadhaar verification failed');
    }
  }

  // Update Settings
  Future<Map<String, dynamic>> updateSettings(bool phoneVisible) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/profile/settings'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'phone_visible': phoneVisible}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to update settings');
    }
  }

  // Roses Balance
  Future<Map<String, dynamic>> getRosesBalance() async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/roses/balance'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch rose balance');
    }
  }

  // Claim Free Rose
  Future<Map<String, dynamic>> claimFreeRose() async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/roses/claim-free'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to claim daily rose');
    }
  }

  // Watch Ad
  Future<Map<String, dynamic>> watchAd() async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/roses/watch-ad'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to reward rose from ad');
    }
  }

  // Create Rose Order
  Future<Map<String, dynamic>> buyRosesOrder(int rosesAmount, double amountInRupees) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/roses/buy-order'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'roses_amount': rosesAmount,
        'amount_in_rupees': amountInRupees,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to create rose order');
    }
  }

  // Verify Rose Order
  Future<Map<String, dynamic>> verifyBuyRoses(String orderId, String paymentId, int rosesAmount) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/roses/buy-verify'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'roses_amount': rosesAmount,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to verify payments');
    }
  }

  // Roses Transaction History
  Future<List<dynamic>> getRosesHistory() async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/roses/history'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to fetch transaction logs');
    }
  }

  // Astrology Match Compatibility details
  Future<Map<String, dynamic>> getAstroMatch(String targetUserId) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/astro/match-details?targetUserId=$targetUserId'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to calculate horoscope compatibility');
    }
  }

  // Unlock Astrology details
  Future<Map<String, dynamic>> unlockAstroMatch(String targetUserId) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/astro/unlock-match'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'targetUserId': targetUserId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to unlock astrological report');
    }
  }

  // Chat message history
  Future<List<dynamic>> getChats(String partnerId) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/chats/$partnerId'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to fetch messages');
    }
  }

  // Send chatbot prompt
  Future<Map<String, dynamic>> sendChatbotMessage(String message) async {
    if (_token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/chatbot/message'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to converse with chatbot');
    }
  }
}
