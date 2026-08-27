import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.businessId,
    required this.displayName,
    required this.emailVerified,
    required this.role,
    required this.status,
    required this.createdAt,
    this.photoUrl,
    this.lastLogin,
  });

  final String uid;
  final String email;
  final String businessId;
  final String displayName;
  final String? photoUrl;
  final bool emailVerified;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime? lastLogin;

  bool get hasBusiness => businessId.isNotEmpty;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      emailVerified: map['emailVerified'] as bool? ?? false,
      role: map['role'] as String? ?? 'owner',
      status: map['status'] as String? ?? 'active',
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      lastLogin: _readDate(map['lastLogin']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'businessId': businessId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'role': role,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin == null ? null : Timestamp.fromDate(lastLogin!),
    };
  }

  UserProfile copyWith({
    String? businessId,
    String? displayName,
    bool? emailVerified,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      businessId: businessId ?? this.businessId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      role: role,
      status: status,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
