import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanban/view.dart';
import 'package:kanban/view_model.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets('演習1：空入力、2件追加、件数更新、入力クリア', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = KanbanViewModel();
    addTearDown(vm.dispose);
    await tester.pumpWidget(MaterialApp(home: KanbanView(vm)));

    final button = find.widgetWithText(FilledButton, '課題を追加');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(find.text('0件'), findsNWidgets(3));

    await tester.enterText(find.byType(TextField), 'レポートを書く');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('レポートを書く'), findsOneWidget);
    expect(find.text('1件'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '発表資料を作る');
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(find.text('レポートを書く'), findsOneWidget);
    expect(find.text('発表資料を作る'), findsOneWidget);
    expect(find.text('2件'), findsOneWidget);
    expect(find.text('0件'), findsNWidgets(2));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(vm.tasks.map((task) => task.status), everyElement(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('演習2・3：左右移動、端のボタン制御、件数とタスクの保持', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = KanbanViewModel();
    addTearDown(vm.dispose);
    vm.add('レポートを書く');
    vm.add('発表資料を作る');
    final target = vm.tasks.first;
    await tester.pumpWidget(MaterialApp(home: KanbanView(vm)));

    Finder targetCard() => find
        .ancestor(of: find.text('レポートを書く'), matching: find.byType(Card))
        .first;

    void checkState(int status, List<int> counts) {
      expect(target.status, status);
      expect(vm.tasks.length, 2);
      expect(vm.tasks.first, same(target));
      expect(find.text('レポートを書く'), findsOneWidget);
      expect(find.text('発表資料を作る'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        final lane = find
            .ancestor(of: find.text(names[i]), matching: find.byType(Card))
            .first;
        expect(
          find.descendant(of: lane, matching: find.text('${counts[i]}件')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: lane, matching: find.text('レポートを書く')),
          i == status ? findsOneWidget : findsNothing,
        );
      }
      expect(
        find.descendant(of: targetCard(), matching: find.byType(TextButton)),
        status > 0 ? findsOneWidget : findsNothing,
      );
      expect(
        find.descendant(of: targetCard(), matching: find.byType(FilledButton)),
        status < 2 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    }

    Future<void> move(String label) async {
      await tester.tap(
        find.descendant(of: targetCard(), matching: find.text(label)),
      );
      await tester.pump();
    }

    checkState(0, [2, 0, 0]);
    await move('取り組み中へ →');
    checkState(1, [1, 1, 0]);
    await move('提出済みへ →');
    checkState(2, [1, 0, 1]);
    await move('← 取り組み中へ');
    checkState(1, [1, 1, 0]);
    await move('← 未着手へ');
    checkState(0, [2, 0, 0]);

    // 保存したデータを読み込み、起動し直しても名前と状態を復元する。
    final restartedVm = KanbanViewModel();
    addTearDown(restartedVm.dispose);
    await restartedVm.load();
    await tester.pumpWidget(
      MaterialApp(home: KanbanView(restartedVm, key: UniqueKey())),
    );
    expect(find.text('2件'), findsOneWidget);
    expect(find.text('0件'), findsNWidgets(2));
    expect(find.text('レポートを書く'), findsOneWidget);
    expect(find.text('発表資料を作る'), findsOneWidget);
  });

  testWidgets('演習5・6：全列で編集・キャンセル・削除し、保存内容を復元', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = KanbanViewModel();
    addTearDown(vm.dispose);
    vm.add('未着手タスク');
    vm.add('作業中タスク');
    vm.move(vm.tasks[1], 1);
    vm.add('完了タスク');
    vm.move(vm.tasks[2], 2);
    await tester.pumpWidget(MaterialApp(home: KanbanView(vm)));
    await tester.pumpAndSettle();

    Finder card(String title) =>
        find.ancestor(of: find.text(title), matching: find.byType(Card)).first;

    for (var status = 0; status < 3; status++) {
      final task = vm.tasks[status];
      final original = task.title;
      await tester.tap(
        find.descendant(of: card(original), matching: find.byIcon(Icons.edit)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).initialValue,
        original,
      );
      await tester.enterText(find.byType(TextFormField), 'キャンセルする名前');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(task.title, original);
      expect(find.text(original), findsOneWidget);

      await tester.tap(
        find.descendant(of: card(original), matching: find.byIcon(Icons.edit)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '編集済み$status');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(task.title, '編集済み$status');
      expect(task.status, status);
      expect(find.text('編集済み$status'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    final restored = KanbanViewModel();
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.tasks.map((t) => t.title), ['編集済み0', '編集済み1', '編集済み2']);
    expect(restored.tasks.map((t) => t.status), [0, 1, 2]);

    for (var status = 0; status < 3; status++) {
      await tester.tap(
        find.descendant(
          of: card('編集済み$status'),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('編集済み$status'), findsNothing);
      expect(find.text('0件'), findsNWidgets(status + 1));
    }

    // 同名でも、押したカードのTaskだけを削除する。
    vm.add('同名タスク');
    vm.add('同名タスク');
    await tester.pumpAndSettle();
    final survivor = vm.tasks.last;
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('同名タスク'), findsOneWidget);
    expect(vm.tasks.single, same(survivor));
    await restored.load();
    expect(restored.tasks.single.title, '同名タスク');

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await restored.load();
    expect(restored.tasks, isEmpty);
    await tester.pumpWidget(
      MaterialApp(home: KanbanView(restored, key: UniqueKey())),
    );
    expect(find.text('0件'), findsNWidgets(3));
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
