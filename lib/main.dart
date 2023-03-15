import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'todo.dart';

final todoListProvider = StateNotifierProvider<TodoListNotifier, List<Todo>>(
    (ref) => TodoListNotifier());

class TodoListNotifier extends StateNotifier<List<Todo>> {
  late Database _db;

  TodoListNotifier() : super([]) {
    initDatabase();
  }

  Future<void> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'todos.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
            'CREATE TABLE todos (id INTEGER PRIMARY KEY, task TEXT, dateTime TEXT, tag TEXT)');
      },
    );
    fetchTodos();
  }

  Future<void> fetchTodos() async {
    List<Map<String, dynamic>> maps = await _db.query('todos');
    state = List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  Future<void> addTask(String task, String tag) async {
    int id = DateTime.now().millisecondsSinceEpoch;
    String dateTime = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    await _db.insert(
        'todos', {'id': id, 'task': task, 'dateTime': dateTime, 'tag': tag});
    fetchTodos();
  }

  Future<void> removeTask(int id) async {
    await _db.delete('todos', where: 'id = ?', whereArgs: [id]);
    fetchTodos();
  }
}

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo App with Riverpod',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ToDoApp(),
    );
  }
}

class ToDoApp extends ConsumerWidget {
  final TextEditingController _controller = TextEditingController();
  final List<String> _tags = ['仕事', '読書'];
  String? _selectedTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoList = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: Text('ToDo App with Riverpod')),
      body: ListView.builder(
        itemCount: todoList.length,
        itemBuilder: (context, index) {
          final todo = todoList[index];
          Color tagColor = todo.tag == '仕事' ? Colors.green : Colors.blue;
          return ListTile(
            title: Text(todo.task),
            subtitle: Text('Created: ${todo.dateTime}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: tagColor.withOpacity(0.2),
                  ),
                  child: Text(
                    todo.tag,
                    style: TextStyle(color: tagColor),
                  ),
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    ref.read(todoListProvider.notifier).removeTask(todo.id);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddTaskDialog(ref: ref),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final WidgetRef ref;

  AddTaskDialog({Key? key, required this.ref}) : super(key: key);

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _tags = ['仕事', '読書'];
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add a new task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _controller),
          SizedBox(height: 16),
          DropdownButton<String>(
            value: _selectedTag,
            hint: Text('Select a tag'),
            onChanged: (String? newValue) {
              setState(() {
                _selectedTag = newValue;
              });
            },
            items: _tags.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty && _selectedTag != null) {
              widget.ref
                  .read(todoListProvider.notifier)
                  .addTask(_controller.text, _selectedTag!);
              Navigator.of(context).pop();
              _controller.clear();
              _selectedTag = null;
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
