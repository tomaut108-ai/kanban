import 'package:flutter/material.dart';
import 'view.dart';
import 'view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final vm = KanbanViewModel();
  await vm.load();
  runApp(MaterialApp(home: KanbanView(vm)));
}
