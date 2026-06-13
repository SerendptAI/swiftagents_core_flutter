class InitSessionResponse {
  final String sessionToken;
  final Company? company;
  final User? user;

  InitSessionResponse({
    required this.sessionToken,
    required this.company,
    required this.user,
  });

  factory InitSessionResponse.fromJson(Map<String, dynamic> json) {
    return InitSessionResponse(
      sessionToken: json['session_token'] ?? '',
      company: Company.fromJson(json['company'] ?? {}),
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_token': sessionToken,
      'company': company?.toJson(),
      'user': user?.toJson(),
    };
  }
}

class Company {
  final String? name;
  final String? logoUrl;
  final List<String>? suggestedAIPrompts;

  Company({
    required this.name,
    required this.logoUrl,
    required this.suggestedAIPrompts,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'],
      logoUrl: json['logo_url'],
      suggestedAIPrompts: (json['suggested_ai_prompts'] as List<dynamic>?)
          ?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logo_url': logoUrl,
      'suggested_ai_prompts': suggestedAIPrompts,
    };
  }
}

class User {
  final String email;
  final bool isNew;

  User({
    required this.email,
    required this.isNew,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      isNew: json['is_new'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'is_new': isNew,
    };
  }
}