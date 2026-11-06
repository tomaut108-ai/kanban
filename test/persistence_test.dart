import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanban/view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('初回は空、追加・移動・編集・削除の各操作後にJSONが保存される', () async {
    final vm = KanbanViewModel();
    addTearDown(vm.dispose);
    final prefs = SharedPreferencesAsync();
    await vm.load();
    expect(vm.tasks, isEmpty);

    Future<void> expectStored(List<Map<String, Object>> expected) async {
      expect(jsonDecode((await prefs.getString('kanban'))!), expected);
      final restarted = KanbanViewModel();
      addTearDown(restarted.dispose);
      await restarted.load();
      expect([
        for (final t in restarted.tasks) {'title': t.title, 'status': t.status},
      ], expected);
    }

    vm.add('日本語のタスク');
    await expectStored([
      {'title': '日本語のタスク', 'status': 0},
    ]);
    final task = vm.tasks.single;
    vm.move(task, 2);
    await expectStored([
      {'title': '日本語のタスク', 'status': 2},
    ]);
    vm.rename(task, '編集後のタスク');
    await expectStored([
      {'title': '編集後のタスク', 'status': 2},
    ]);
    vm.remove(task);
    await expectStored([]);
  });
}
