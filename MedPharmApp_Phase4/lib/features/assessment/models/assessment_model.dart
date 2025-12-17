
class AssessmentModel {

  final String id;  
  final String studyId;  
  final int nrsScore; 
  final int vasScore;  
  final DateTime timestamp; 
  final bool isSynced;  
  final DateTime createdAt;  

  AssessmentModel({
    String? id,
    required this.studyId,
    required this.nrsScore,
    required this.vasScore,
    required this.timestamp,
    this.isSynced = false,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now() {
    if (nrsScore < 0 || nrsScore > 10) {
      throw ArgumentError('NRS score must be between 0 and 10');
    }
    if (vasScore < 0 || vasScore > 100) {
      throw ArgumentError('VAS score must be between 0 and 100');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'study_id': studyId,
      'nrs_score': nrsScore,
      'vas_score': vasScore,
      'timestamp': timestamp.toIso8601String(),  
      'is_synced': isSynced ? 1 : 0,  
      'created_at': createdAt.toIso8601String(),
    };
  }


  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    return AssessmentModel(
      id: map['id'] as String,
      studyId: map['study_id'] as String,
      nrsScore: map['nrs_score'] as int,
      vasScore: map['vas_score'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: map['is_synced'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }


  AssessmentModel copyWith({
    String? id,
    String? studyId,
    int? nrsScore,
    int? vasScore,
    DateTime? timestamp,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return AssessmentModel(
      id: id ?? this.id,
      studyId: studyId ?? this.studyId,
      nrsScore: nrsScore ?? this.nrsScore,
      vasScore: vasScore ?? this.vasScore,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }


  String get painLevelDescription {
    if (nrsScore == 0) return 'No Pain';
    if (nrsScore <= 3) return 'Mild Pain';
    if (nrsScore <= 6) return 'Moderate Pain';
    if (nrsScore <= 9) return 'Severe Pain';
    return 'Worst Possible Pain';
  }

  String get painLevelColor {
    if (nrsScore == 0) return '#4CAF50';  // Green
    if (nrsScore <= 3) return '#8BC34A';  // Light Green
    if (nrsScore <= 6) return '#FFC107';  // Yellow
    if (nrsScore <= 9) return '#FF9800';  // Orange
    return '#F44336';  // Red
  }

  bool get isTodayAssessment {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  String get formattedDate {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'AssessmentModel(id: $id, NRS: $nrsScore, VAS: $vasScore, date: $formattedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssessmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

