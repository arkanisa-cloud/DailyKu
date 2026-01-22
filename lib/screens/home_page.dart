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
  String get formattedDate => selectedDate.toIso8601String().split('T')[0];

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
      return !isSameDay(last, today);
    }

    if (todo.repeatType == 'weekly') {
      return today.difference(last).inDays >= 7;
    }

    if (todo.repeatType == 'monthly') {
      return last.month != today.month || last.year != today.year;
    }

    if (todo.repeatType == 'yearly') {
      return last.year != today.year;
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
    final themeColor = Theme.of(context).primaryColor;

    return ChoiceChip(
      label: Text(text),
      selected: isActive,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
          });
        }
      },
      selectedColor: themeColor.withOpacity(0.1),
      backgroundColor: Colors.white,
      side: BorderSide(
          color: isActive ? themeColor : Colors.grey.shade200, width: 1.5),
      labelStyle: TextStyle(
        color: isActive ? themeColor : Colors.grey.shade600,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wb_sunny_rounded,
                  size: 80, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hari yang cerah!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada tugas untuk saat ini.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTinyCategoryTag(String category) {
    Color tagColor = Colors.blue;
    if (category == "Kerja") tagColor = Colors.orange;
    if (category == "Personal") tagColor = Colors.green;
    if (category == "Liburan") tagColor = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: tagColor),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nama tugas baru',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;

                // Create a copy with updated title, preserving other fields
                // including the new repeat types logic
                final updatedTodo = Todo(
                  id: todo.id,
                  title: titleController.text.trim(),
                  isDone: todo.isDone,
                  time: todo.time,
                  date: todo.date,
                  // Preserve new repeat logic fields
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded, color: Colors.blue),
              ),
              title: const Text('Edit Tugas',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _openEditTaskDialog(todo);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_rounded, color: Colors.red),
              ),
              title: const Text('Hapus Tugas',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.red)),
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
    final themeColor = Theme.of(context).primaryColor;
    bool isRepeat = todo.repeatType != 'none';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleTaskCompletionToggle(todo),
            onLongPress: () => _showTaskOptionsSheet(todo),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox Kustom
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: todo.isDone ? Colors.green : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            todo.isDone ? Colors.green : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: todo.isDone
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Detail Tugas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: todo.isDone ? Colors.grey : Colors.black87,
                            decoration:
                                todo.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              todo.time,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500),
                            ),
                            if (todo.category != null) ...[
                              const SizedBox(width: 12),
                              _buildTinyCategoryTag(todo.category!),
                            ],
                            if (isRepeat) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.repeat_rounded,
                                  size: 14, color: themeColor.withOpacity(0.5)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Indikator Menu
                  Icon(Icons.more_horiz_rounded, color: Colors.grey.shade300),
                ],
              ),
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
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5),
        ),
        children: items.map((todo) {
          return Dismissible(
            key: ValueKey(todo.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            onDismissed: (_) => _deleteTask(todo.id!),
            child: _buildTodoItem(todo),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    // Filter relevant todos
    List<Todo> relevantTodos = todos.where((t) {
      // Logic from home_page.dart: reset if needed
      if (shouldReset(t)) {
        t.isDone = false;
      }
      return shouldShowToday(t);
    }).toList();

    // Apply category filter
    if (_currentFilter != TodoFilter.all) {
      relevantTodos =
          relevantTodos.where((t) => _isMatchingCategory(t)).toList();
    }

    // Split active and done
    List<Todo> activeTodos =
        relevantTodos.where((t) => !t.isDone).toList();
    List<Todo> doneTodos =
        relevantTodos.where((t) => t.isDone).toList();
        
    // Sort logic from lama (by time)
    activeTodos.sort((a, b) => a.time.compareTo(b.time));
    doneTodos.sort((a, b) => a.time.compareTo(b.time));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Dailyku',
          style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Filter Kategori
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryFilterChip('📅 Semua', TodoFilter.all),
                const SizedBox(width: 8),
                _buildCategoryFilterChip('🏢 Kerja', TodoFilter.kerja),
                const SizedBox(width: 8),
                _buildCategoryFilterChip('🏠 Personal', TodoFilter.personal),
                const SizedBox(width: 8),
                _buildCategoryFilterChip('🏖️ Liburan', TodoFilter.liburan),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  if (activeTodos.isEmpty && doneTodos.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _buildTaskSection("Tugas Aktif", activeTodos),
                    _buildTaskSection("Selesai", doneTodos,
                        isInitiallyExpanded: false),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddTodoSheet(onSave: loadTodos),
          );
        },
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.add_rounded, size: 36),
      ),
    );
  }
}
