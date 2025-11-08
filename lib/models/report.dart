import 'package:supabase_flutter/supabase_flutter.dart';

enum ReportReason {
  scam,
  inappropriate,
  spam,
  fakeItem,
  harassment,
  other,
}

enum ReportStatus {
  pending,
  reviewed,
  resolved,
}

class Report {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? itemId;
  final ReportReason reason;
  final String description;
  final DateTime createdAt;
  final ReportStatus status;

  const Report({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.itemId,
    required this.reason,
    required this.description,
    required this.createdAt,
    this.status = ReportStatus.pending,
  });

  // Helper methods
  bool get isResolved => status == ReportStatus.resolved;
  bool get isPending => status == ReportStatus.pending;

  // Validation
  bool get isValidDescription =>
      description.isNotEmpty && description.length >= 10;

  // Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'item_id': itemId,
      'reason': reason.name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  // Convert from Supabase JSON
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      reporterId: json['reporter_id'] ?? '',
      reportedUserId: json['reported_user_id'],
      itemId: json['item_id'],
      reason: ReportReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => ReportReason.other,
      ),
      description: json['description'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
    );
  }

  Report copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? itemId,
    ReportReason? reason,
    String? description,
    DateTime? createdAt,
    ReportStatus? status,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      itemId: itemId ?? this.itemId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Report(id: $id, reporter: $reporterId, reason: $reason, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Report &&
        other.id == id &&
        other.reporterId == reporterId &&
        other.reportedUserId == reportedUserId &&
        other.itemId == itemId &&
        other.reason == reason &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      reporterId,
      reportedUserId,
      itemId,
      reason,
      description,
      createdAt,
      status,
    );
  }
}
