class Todo {
  final int id;
  final String task;
  final String dateTime;
  final String tag;

  Todo({required this.id, required this.task, required this.dateTime, required this.tag});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'dateTime': dateTime,
      'tag': tag,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      task: map['task'],
      dateTime: map['dateTime'],
      tag: map['tag'],
    );
  }
}
