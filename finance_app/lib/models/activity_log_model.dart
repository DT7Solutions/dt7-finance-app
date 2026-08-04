class ActivityLogModel {
  final int id;
  final String userName;
  final String title;
  final String description;
  final String timestamp;
  final String logType;

  ActivityLogModel({
    required this.id,
    required this.userName,
    required this.title,
    required this.description,
    required this.timestamp,
    this.logType = 'INFO',
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] ?? '',
      logType: json['log_type'] ?? 'INFO',
    );
  }
}
