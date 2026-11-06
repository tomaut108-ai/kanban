import 'package:flutter/material.dart';
import 'model.dart';
import 'view_model.dart';

final names = ['📝 未着手', '📚 取り組み中', '📮 提出済み'];
final labels = ['未着手', '取り組み中', '提出済み'];
final colors = [Colors.blue.shade50, Colors.amber.shade50, Colors.teal.shade50];

class KanbanView extends StatefulWidget {
  final KanbanViewModel vm;
  const KanbanView(this.vm, {super.key});

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  final input = TextEditingController();

  void add() {
    widget.vm.add(input.text);
    input.clear();
  }

  Future<void> edit(Task t) async {
    var text = t.title;
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('タスクを編集'),
        content: TextFormField(
          initialValue: text,
          autofocus: true,
          onChanged: (v) => text = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('キャンセル')),
          FilledButton(
            onPressed: () => Navigator.pop(c, text),
            child: Text('保存'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result != null) widget.vm.rename(t, result);
  }

  Widget taskCard(Task t) {
    final s = t.status;
    final buttons = Wrap(
      spacing: 4,
      children: [
        if (s > 0)
          TextButton(
            onPressed: () => widget.vm.move(t, s - 1),
            child: Text('← ${labels[s - 1]}へ'),
          ),
        if (s < 2)
          FilledButton(
            onPressed: () => widget.vm.move(t, s + 1),
            child: Text('${labels[s + 1]}へ →'),
          ),
      ],
    );
    return Card(
      child: ListTile(
        title: Text(t.title),
        subtitle: buttons,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              tooltip: 'タスクを編集',
              onPressed: () => edit(t),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline),
              tooltip: 'タスクを削除',
              onPressed: () => widget.vm.remove(t),
            ),
          ],
        ),
      ),
    );
  }

  Widget lane(int s) {
    final cards = [
      for (final t in widget.vm.tasks)
        if (t.status == s) taskCard(t),
    ];
    return SizedBox(
      width: 300,
      child: Card(
        color: colors[s],
        child: Column(
          children: [
            ListTile(title: Text(names[s]), trailing: Text('${cards.length}件')),
            Expanded(child: ListView(children: cards)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: input,
      decoration: InputDecoration(
        labelText: '新しい課題',
        hintText: '例：プログラミングのレポートを提出する',
        border: OutlineInputBorder(),
      ),
    );
    final button = ValueListenableBuilder(
      valueListenable: input,
      builder: (context, value, child) => FilledButton.icon(
        onPressed: value.text.isEmpty ? null : add,
        icon: Icon(Icons.add),
        label: Text('課題を追加'),
      ),
    );
    final entry = Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            field,
            Align(alignment: Alignment.centerRight, child: button),
          ],
        ),
      ),
    );
    final board = ListenableBuilder(
      listenable: widget.vm,
      builder: (context, child) => ListView(
        scrollDirection: Axis.horizontal,
        children: [for (int s = 0; s < 3; s++) lane(s)],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('📋 課題・提出 Kanban')),
      body: Column(
        children: [
          entry,
          Expanded(child: board),
        ],
      ),
    );
  }
}
