import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/todos.dart';
import 'add_todo_sheet.dart';

enum TodoFilter {
  all,
  kerja,
  personal,
  liburan,
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Todo> todos = [];
  TodoFilter _currentFilter = TodoFilter.all;
  DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  Future<void> loadTodos() async {
    List<Todo> data = await DBHelper.instance.getTodos();
    setState(() {
      todos = data;
    });
  }

  DateTime get selectedDate => today;
  String get formattedDate =>
      selectedDate.toIso8601String().split('T')[0]; // yyyy-MM-dd

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool shouldShowToday(Todo todo) {
    if (todo.repeatType == 'none') {
      return todo.date ==
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    }

    if (todo.repeatType == 'daily') return true;

    if (todo.repeatType == 'weekly') {
      return todo.repeatValue == today.weekday;
    }

    if (todo.repeatType == 'monthly') {
      return todo.repeatValue == today.day;
    }

    if (todo.repeatType == 'yearly') {
      int mmdd = today.month * 100 + today.day;
      return todo.repeatValue == mmdd;
    }

    return false;
  }

  bool shouldReset(Todo todo) {
    if (todo.lastDoneDate == null) return false;

    DateTime last = DateTime.parse(todo.lastDoneDate!);

    if (todo.repeatType == 'daily') {
      return !isSameDay(last, today); // Reset jika bukan hari yang sama
    }

    if (todo.repeatType == 'weekly') {
      return today.difference(last).inDays >=
          7; // Minggu baru jika sudah lewat 7 hari
    }

    if (todo.repeatType == 'monthly') {
      return last.month != today.month ||
          last.year != today.year; // Bulan baru jika bulan atau tahun berbeda
    }

    if (todo.repeatType == 'yearly') {
      return last.year != today.year; // Tahun baru jika tahun berbeda
    }

    return false;
  }

  Future<void> _handleTaskCompletionToggle(Todo todo) async {
    todo.isDone = !todo.isDone;
    if (todo.isDone) {
      todo.lastDoneDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    }
    await DBHelper.instance.updateTodo(todo);
    loadTodos();
  }

  void _deleteTask(int id) async {
    await DBHelper.instance.deleteTodo(id);
    loadTodos();
  }

  bool _isMatchingCategory(Todo todo) {
    if (_currentFilter == TodoFilter.all) return true;

    String requiredCategory = "";
    switch (_currentFilter) {
      case TodoFilter.kerja:
        requiredCategory = "Kerja";
        break;
      case TodoFilter.personal:
        requiredCategory = "Personal";
        break;
      case TodoFilter.liburan:
        requiredCategory = "Liburan";
        break;
      default:
        break;
    }
    // Compare ignoring case safely if needed, but assuming exact match for now based on lama
    return todo.category == requiredCategory;
  }

  // --- UI COMPONENTS FROM home_page_lama ---

  Widget _buildCategoryFilterChip(String text, TodoFilter filter) {
    final isActive = _currentFilter == filter;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: isActive,
        onSelected: (selected) {
          if (selected) setState(() => _currentFilter = filter);
        },
        selectedColor: primaryColor.withOpacity(0.12),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isActive ? primaryColor : Colors.grey.shade200,
          width: 1.5,
        ),
        labelStyle: TextStyle(
          color: isActive ? primaryColor : Colors.grey.shade700,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/img/empty.png',
                width: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Semua masih kosong.',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Yuk, tambahkan tugas pertamamu!',
              style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTinyCategoryTag(String category) {
    Color tagColor = Theme.of(context).primaryColor;
    if (category == "Kerja") tagColor = Colors.orange;
    if (category == "Personal") tagColor = Colors.green;
    if (category == "Liburan") tagColor = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tagColor.withOpacity(0.1), width: 1),
      ),
      child: Text(
        category,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: tagColor),
      ),
    );
  }

  void _openEditTaskDialog(Todo todo) {
    final titleController = TextEditingController(text: todo.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Tugas'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nama tugas baru',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final updatedTodo = Todo(
                  id: todo.id,
                  title: titleController.text.trim(),
                  isDone: todo.isDone,
                  time: todo.time,
                  date: todo.date,
                  repeatType: todo.repeatType,
                  repeatValue: todo.repeatValue,
                  category: todo.category,
                  lastDoneDate: todo.lastDoneDate,
                );
                await DBHelper.instance.updateTodo(updatedTodo);
                Navigator.pop(context);
                loadTodos();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showTaskOptionsSheet(Todo todo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.edit_rounded,
                    color: Theme.of(context).primaryColor),
              ),
              title: const Text('Edit Tugas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _openEditTaskDialog(todo);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.delete_rounded, color: Colors.red),
              ),
              title: const Text('Hapus Tugas',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _deleteTask(todo.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(Todo todo) {
    final primaryColor = Theme.of(context).primaryColor;
    bool isRepeat = todo.repeatType != 'none';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _handleTaskCompletionToggle(todo),
          onLongPress: () => _showTaskOptionsSheet(todo),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: todo.isDone
                        ? const Color(0xFF34C759)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: todo.isDone
                          ? const Color(0xFF34C759)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: todo.isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: todo.isDone
                              ? Colors.grey.shade400
                              : Colors.black87,
                          decoration:
                              todo.isDone ? TextDecoration.lineThrough : null,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.blueGrey.shade200),
                          const SizedBox(width: 4),
                          Text(
                            todo.time,
                            style: TextStyle(
                                fontSize: 13, color: Colors.blueGrey.shade300),
                          ),
                          if (todo.category != null) ...[
                            const SizedBox(width: 12),
                            _buildTinyCategoryTag(todo.category!),
                          ],
                          if (isRepeat) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.repeat_rounded,
                                size: 14, color: primaryColor.withOpacity(0.4)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEditTaskDialog(todo);
                    } else if (value == 'delete') {
                      _deleteTask(todo.id!);
                    }
                  },
                  icon: Icon(Icons.more_horiz_rounded,
                      color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 20, color: Color(0xFF5C7CFA)),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded,
                              size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskSection(String title, List<Todo> items,
      {bool isInitiallyExpanded = true}) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isInitiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
            color: Colors.blueGrey.shade900,
          ),
        ),
        iconColor: Colors.blueGrey.shade300,
        children: items.map((todo) => _buildTodoItem(todo)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter relevant todos
    List<Todo> relevantTodos = todos.where((t) {
      if (shouldReset(t)) t.isDone = false;
      return shouldShowToday(t);
    }).toList();

    if (_currentFilter != TodoFilter.all) {
      relevantTodos =
          relevantTodos.where((t) => _isMatchingCategory(t)).toList();
    }

    List<Todo> activeTodos = relevantTodos.where((t) => !t.isDone).toList();
    List<Todo> doneTodos = relevantTodos.where((t) => t.isDone).toList();

    activeTodos.sort((a, b) => a.time.compareTo(b.time));
    doneTodos.sort((a, b) => a.time.compareTo(b.time));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1.5,
          shadowColor: Colors.black.withOpacity(0.15),
          toolbarHeight: 72,
          shape: Border(
            bottom: BorderSide(
              color: Colors.blueGrey.shade300,
              width: 1,
            ),
          ),
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/img/logo.png',
                  width: 44, // lebih proporsional
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dailyku',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kelola harimu dengan lebih produktif!',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildCategoryFilterChip('Semua', TodoFilter.all),
                    _buildCategoryFilterChip('Kerja', TodoFilter.kerja),
                    _buildCategoryFilterChip('Personal', TodoFilter.personal),
                    _buildCategoryFilterChip('Liburan', TodoFilter.liburan),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  children: [
                    if (activeTodos.isEmpty && doneTodos.isEmpty)
                      _buildEmptyState()
                    else ...[
                      _buildTaskSection("Tugas Aktif", activeTodos),
                      const SizedBox(height: 24),
                      _buildTaskSection("Selesai", doneTodos,
                          isInitiallyExpanded: false),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddTodoSheet(onSave: loadTodos),
          );
        },
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 36),
      ),
    );
  }
}
