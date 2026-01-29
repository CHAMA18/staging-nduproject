/// Model for an agile task/user story in Agile Development Iterations page
class AgileTask {
  final String id;
  String userStory; // User Story/Task name
  String assignedRole; // Role from Staff Needs
  int storyPoints; // 1, 2, 3, 5, 8
  String priority; // Critical, High, Medium, Low
  String status; // To-Do, In-Progress, Testing, Done
  String taskDescription; // Prose description
  String acceptanceCriteria; // "." bullet format
  String iterationNotes; // Prose, no bullets, manual input only

  AgileTask({
    String? id,
    this.userStory = '',
    this.assignedRole = '',
    this.storyPoints = 1,
    this.priority = 'Medium',
    this.status = 'To-Do',
    this.taskDescription = '',
    this.acceptanceCriteria = '',
    this.iterationNotes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  AgileTask copyWith({
    String? userStory,
    String? assignedRole,
    int? storyPoints,
    String? priority,
    String? status,
    String? taskDescription,
    String? acceptanceCriteria,
    String? iterationNotes,
  }) {
    return AgileTask(
      id: id,
      userStory: userStory ?? this.userStory,
      assignedRole: assignedRole ?? this.assignedRole,
      storyPoints: storyPoints ?? this.storyPoints,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      taskDescription: taskDescription ?? this.taskDescription,
      acceptanceCriteria: acceptanceCriteria ?? this.acceptanceCriteria,
      iterationNotes: iterationNotes ?? this.iterationNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userStory': userStory,
        'assignedRole': assignedRole,
        'storyPoints': storyPoints,
        'priority': priority,
        'status': status,
        'taskDescription': taskDescription,
        'acceptanceCriteria': acceptanceCriteria,
        'iterationNotes': iterationNotes,
      };

  factory AgileTask.fromJson(Map<String, dynamic> json) {
    int parseStoryPoints(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 1;
    }

    return AgileTask(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      userStory: json['userStory']?.toString() ?? '',
      assignedRole: json['assignedRole']?.toString() ?? '',
      storyPoints: parseStoryPoints(json['storyPoints']),
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'To-Do',
      taskDescription: json['taskDescription']?.toString() ?? '',
      acceptanceCriteria: json['acceptanceCriteria']?.toString() ?? '',
      iterationNotes: json['iterationNotes']?.toString() ?? '',
    );
  }
}
