import '../services/dio_client.dart';

class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int totalChallenges;
  final int officialChallenges;
  final int openSupportTickets;
  final int inProgressTickets;

  AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalChallenges,
    required this.officialChallenges,
    required this.openSupportTickets,
    required this.inProgressTickets,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      totalChallenges: json['total_challenges'] ?? 0,
      officialChallenges: json['official_challenges'] ?? 0,
      openSupportTickets: json['open_support_tickets'] ?? 0,
      inProgressTickets: json['in_progress_tickets'] ?? 0,
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

  Future<Map<String, dynamic>> getUsers({int page = 1, String search = ''}) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/users/', queryParameters: {
      'page': page,
      if (search.isNotEmpty) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getChallenges({int page = 1}) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/challenges/', queryParameters: {
      'page': page,
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
    List<String> tasks = const [],
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

  Future<Map<String, dynamic>> getSupportTickets({int page = 1, String? status}) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/admin/support-tickets/', queryParameters: {
      'page': page,
      if (status != null && status.isNotEmpty) 'status': status,
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
