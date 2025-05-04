import 'package:intl/intl.dart';

class Book {
  final String id;
  final String name;
  final String filePath;
  final DateTime addedDate;

  Book({
    required this.id,
    required this.name,
    required this.filePath,
    required this.addedDate,
  });

  String get formattedDate => DateFormat('MMM d, yyyy').format(addedDate);

  Book copyWith({
    String? id,
    String? name,
    String? filePath,
    DateTime? addedDate,
  }) {
    return Book(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'addedDate': addedDate.millisecondsSinceEpoch,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      name: json['name'],
      filePath: json['filePath'],
      addedDate: DateTime.fromMillisecondsSinceEpoch(json['addedDate']),
    );
  }
}
