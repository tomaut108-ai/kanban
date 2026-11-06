import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model.dart';

class KanbanViewModel extends ChangeNotifier {
  final prefs = SharedPreferencesAsync();
  final tasks = <Task>[];

  Future<void> load() async {
    final data = await prefs.getString('kanban');
    if (data == null) return;
    tasks.clear();
    for (final t in jsonDecode(data)) {
      tasks.add(Task(t['title'], t['status']));
    }
  }

  Future<void> save() async {
    notifyListeners();
    final data = [
      for (final t in tasks) {'title': t.title, 'status': t.status},
    ];
    await prefs.setString('kanban', jsonEncode(data));
  }

  void add(String text) {
    tasks.add(Task(text));
    save();
  }

  void move(Task t, int status) {
    t.status = status;
    save();
  }

  void rename(Task t, String text) {
    t.title = text;
    save();
  }

  void remove(Task t) {
    tasks.remove(t);
    save();
  }
}
