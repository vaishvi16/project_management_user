class Project {
  final String id;
  final String name;
  final String description;
  final String type;
  final List<String> members;
  final DateTime startDate;
  final DateTime endDate;
  final double progress;
  String status; // <-- make it non-final

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.members,
    required this.startDate,
    required this.endDate,
    required this.progress,
    this.status = 'pending', // default value
  });
}
