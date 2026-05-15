import '../services/dio_client.dart';

class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int totalChallenges;
  final int officialChallenges;
  final int openSupportTickets;
  final int inProgressTickets;
  final int pendingPrizes;
  final int pendingReports;

  AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalChallenges,
    required this.officialChallenges,
    required this.openSupportTickets,
    required this.inProgressTickets,
    this.pendingPrizes = 0,
    this.pendingReports = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      totalChallenges: json['total_challenges'] ?? 0,
      officialChallenges: json['official_challenges'] ?? 0,
      openSupportTickets: json['open_support_tickets'] ?? 0,
      inProgressTickets: json['in_progress_tickets'] ?? 0,
      pendingPrizes: json['pending_prizes'] ?? 0,
      pendingReports: json['pending_reports'] ?? 0,
    );
  }
}

class AdminService {
  final _dioClient = DioClient();

  Future<AdminStats> getDashboardStats() async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/dashboard/');
    return AdminStats.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getUsers({int page = 1, String search = '', String statusFilter = ''}) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/users/', queryParameters: {
      'page': page,
      if (search.isNotEmpty) 'search': search,
      if (statusFilter.isNotEmpty) 'status': statusFilter,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getChallenges({int page = 1, String search = ''}) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/challenges/', queryParameters: {
      'page': page,
      if (search.isNotEmpty) 'search': search,
    });
    return response.data;
  }

  Future<void> updateChallenge(String challengeId, {bool? isOfficial, bool? isActive, bool? isPaid, double? price, String? currency, String? prizeDescription}) async {
    final dio = _dioClient.dio;
    await dio.put('/admin/challenges/$challengeId/', data: {
      if (isOfficial != null) 'is_official': isOfficial,
      if (isActive != null) 'is_active': isActive,
      if (isPaid != null) 'is_paid': isPaid,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (prizeDescription != null) 'prize_description': prizeDescription,
    });
  }

  Future<void> editChallenge(String challengeId, {
    String? name,
    String? description,
    String? challengeType,
    double? goalValue,
    String? unit,
    String? startDate,
    String? endDate,
    bool? isOfficial,
    bool? isActive,
    bool? isPaid,
    double? price,
    String? currency,
    String? prizeDescription,
    List<Map<String, String>>? tasks,
  }) async {
    final dio = _dioClient.dio;
    await dio.put('/admin/challenges/$challengeId/', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (challengeType != null) 'challenge_type': challengeType,
      if (goalValue != null) 'goal_value': goalValue,
      if (unit != null) 'unit': unit,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (isOfficial != null) 'is_official': isOfficial,
      if (isActive != null) 'is_active': isActive,
      if (isPaid != null) 'is_paid': isPaid,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (prizeDescription != null) 'prize_description': prizeDescription,
      if (tasks != null) 'tasks': tasks,
    });
  }

  Future<void> deleteChallenge(String challengeId) async {
    final dio = _dioClient.dio;
    await dio.delete('/admin/challenges/$challengeId/');
  }

  Future<void> createChallenge({
    required String name,
    required String description,
    required String challengeType,
    required double goalValue,
    required String unit,
    required String startDate,
    required String endDate,
    bool isOfficial = true,
    bool isPaid = false,
    double price = 0,
    String currency = 'NPR',
    String prizeDescription = '',
    List<Map<String, String>> tasks = const [],
  }) async {
    final dio = _dioClient.dio;
    await dio.post('/admin/challenges/create/', data: {
      'name': name,
      'description': description,
      'challenge_type': challengeType,
      'goal_value': goalValue,
      'unit': unit,
      'start_date': startDate,
      'end_date': endDate,
      'is_official': isOfficial,
      'is_paid': isPaid,
      'price': price,
      'currency': currency,
      'prize_description': prizeDescription,
      'tasks': tasks,
    });
  }

  Future<Map<String, dynamic>> getSupportTickets({int page = 1, String? status, String search = ''}) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/support-tickets/', queryParameters: {
      'page': page,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search.isNotEmpty) 'search': search,
    });
    return response.data;
  }

  Future<void> updateSupportTicket(String ticketId, {String? status, String? adminNotes}) async {
    final dio = _dioClient.dio;
    await dio.put('/admin/support-tickets/$ticketId/', data: {
      if (status != null) 'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
    });
  }

  Future<void> updateUser(String userId, {bool? isActive, bool? isStaff}) async {
    final dio = _dioClient.dio;
    await dio.put('/admin/users/$userId/', data: {
      if (isActive != null) 'is_active': isActive,
      if (isStaff != null) 'is_staff': isStaff,
    });
  }

  Future<Map<String, dynamic>> getReportedPosts({int page = 1}) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/reported-posts/', queryParameters: {'page': page});
    return response.data as Map<String, dynamic>;
  }

  Future<void> removePost(String postId) async {
    final dio = _dioClient.dio;
    await dio.post('/admin/reported-posts/$postId/remove/');
  }

  Future<void> dismissReports(String postId) async {
    final dio = _dioClient.dio;
    await dio.post('/admin/reported-posts/$postId/dismiss/');
  }

  Future<Map<String, dynamic>> getAdminChallengeLeaderboard(String challengeId) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/challenges/$challengeId/leaderboard/');
    return response.data;
  }

  Future<Map<String, dynamic>> awardPrize(String challengeId, String participantId) async {
    final dio = _dioClient.dio;
    final response = await dio.post('/admin/challenges/$challengeId/award-prize/', data: {
      'participant_id': participantId,
    });
    return response.data;
  }

  Future<void> disqualifyParticipant(String challengeId, String participantId) async {
    final dio = _dioClient.dio;
    await dio.delete('/admin/challenges/$challengeId/participants/$participantId/');
  }
}


class FAQ {
  final String id;
  final String category;
  final String question;
  final String answer;
  final int order;
  final bool isActive;

  FAQ({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.order,
    required this.isActive,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'],
      category: json['category'],
      question: json['question'],
      answer: json['answer'],
      order: json['order'],
      isActive: json['is_active'] ?? true,
    );
  }
}

extension AdminServiceFAQ on AdminService {
  Future<List<FAQ>> getFAQs({String? category}) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/faqs/', queryParameters: {
      if (category != null && category.isNotEmpty) 'category': category,
    });
    final List<dynamic> data = response.data;
    return data.map((json) => FAQ.fromJson(json)).toList();
  }

  Future<void> createFAQ({
    required String category,
    required String question,
    required String answer,
    required int order,
    required bool isActive,
  }) async {
    final dio = _dioClient.dio;
    await dio.post('/admin/faqs/', data: {
      'category': category,
      'question': question,
      'answer': answer,
      'order': order,
      'is_active': isActive,
    });
  }

  Future<void> updateFAQ(
    String faqId, {
    String? category,
    String? question,
    String? answer,
    int? order,
    bool? isActive,
  }) async {
    final dio = _dioClient.dio;
    await dio.put('/admin/faqs/$faqId/', data: {
      if (category != null) 'category': category,
      if (question != null) 'question': question,
      if (answer != null) 'answer': answer,
      if (order != null) 'order': order,
      if (isActive != null) 'is_active': isActive,
    });
  }

  Future<void> deleteFAQ(String faqId) async {
    final dio = _dioClient.dio;
    await dio.delete('/admin/faqs/$faqId/');
  }
}

// ── Exercise model ────────────────────────────────────────────────────────────

class AdminExercise {
  final int id;
  final String name;
  final String description;
  final String category;
  final String muscleGroup;
  final String equipment;
  final String difficulty;
  final String instructions;
  final String? imageUrl;
  final String? videoUrl;
  final double caloriesPerMinute;
  final bool isCustom;

  AdminExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.instructions,
    this.imageUrl,
    this.videoUrl,
    required this.caloriesPerMinute,
    required this.isCustom,
  });

  factory AdminExercise.fromJson(Map<String, dynamic> json) => AdminExercise(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String,
        muscleGroup: json['muscle_group'] as String,
        equipment: json['equipment'] as String,
        difficulty: json['difficulty'] as String,
        instructions: json['instructions'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
        videoUrl: json['video_url'] as String?,
        caloriesPerMinute: (json['calories_per_minute'] as num?)?.toDouble() ?? 5.0,
        isCustom: json['is_custom'] as bool? ?? false,
      );
}

extension AdminServiceExercises on AdminService {
  Future<List<AdminExercise>> getExercises({String search = '', String category = ''}) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/exercises/', queryParameters: {
      if (search.isNotEmpty) 'search': search,
      if (category.isNotEmpty) 'category': category,
    });
    final List<dynamic> data = response.data is List
        ? response.data
        : (response.data['results'] ?? response.data['data'] ?? []);
    return data.map((e) => AdminExercise.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminExercise> createExercise({
    required String name,
    required String description,
    required String category,
    required String muscleGroup,
    required String equipment,
    required String difficulty,
    required String instructions,
    String? imageUrl,
    String? videoUrl,
    double caloriesPerMinute = 5.0,
  }) async {
    final dio = _dioClient.dio;
    final response = await dio.post('/exercises/', data: {
      'name': name,
      'description': description,
      'category': category,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'difficulty': difficulty,
      'instructions': instructions,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
      'calories_per_minute': caloriesPerMinute,
    });
    return AdminExercise.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminExercise> updateExercise(int id, {
    required String name,
    required String description,
    required String category,
    required String muscleGroup,
    required String equipment,
    required String difficulty,
    required String instructions,
    String? imageUrl,
    String? videoUrl,
    double caloriesPerMinute = 5.0,
  }) async {
    final dio = _dioClient.dio;
    final response = await dio.put('/exercises/$id/', data: {
      'name': name,
      'description': description,
      'category': category,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'difficulty': difficulty,
      'instructions': instructions,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
      'calories_per_minute': caloriesPerMinute,
    });
    return AdminExercise.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteExercise(int id) async {
    final dio = _dioClient.dio;
    await dio.delete('/exercises/$id/');
  }
}
