import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/todos.dart';
import 'add_todo_sheet.dart';
import '../widgets/drawer_widget.dart';
import '../services/notification_service.dart';

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Todo> todos = []; 
  TodoFilter _currentFilter = TodoFilter.all;
  DateTime _selectedDate = DateTime.now(); // State tanggal terpilih

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

  // --- Logic Helper ---

  // Cek apakah tanggal sama (abaikan jam)
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Filter apakah task muncul di _selectedDate
  bool shouldShowOnSelectedDate(Todo todo) {
    if (todo.repeatType == 'none') {
      String targetStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      return todo.date == targetStr;
    }

    if (todo.repeatType == 'daily') return true;

    if (todo.repeatType == 'weekly') {
      return todo.repeatValue == _selectedDate.weekday;
    }

    if (todo.repeatType == 'monthly') {
      return todo.repeatValue == _selectedDate.day;
    }

    if (todo.repeatType == 'yearly') {
      int mmdd = _selectedDate.month * 100 + _selectedDate.day; // Format MMDD ex: 2 * 100 + 20 = 220 = Feb 20
      return todo.repeatValue == mmdd;
    }

    return false;
  }

  // Cek apakah task repeat perlu di-reset statusnya (berdasarkan Updated Real Time, bukan SelectedDate)
  bool shouldReset(Todo todo) {
    if (todo.lastDoneDate == null) return false;

    DateTime last = DateTime.parse(todo.lastDoneDate!);
    DateTime now = DateTime.now(); // Reset selalu pakai waktu sekarang

    if (todo.repeatType == 'daily') {
      return !isSameDay(last, now);
    }

    if (todo.repeatType == 'weekly') {
      // selisih hari >= 7
      return now.difference(last).inDays >= 7;
    }

    if (todo.repeatType == 'monthly') {
      return last.month != now.month || last.year != now.year; // Kalau bulan atau tahun berubah, reset!
    }

    if (todo.repeatType == 'yearly') {
      return last.year != now.year; // Kalau tahun berubah, reset!
    }

    return false;
  }

  Future<void> _handleTaskCompletionToggle(Todo todo) async {
    // Logic toggle
    todo.isDone = !todo.isDone;

    // Jika dicentang, simpan tanggal hari ini (Real Time) sebagai lastDoneDate
    if (todo.isDone) {
      todo.lastDoneDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // Cancel notification if marked as done
      await NotificationService().cancelNotification(todo.notificationId);
    } else {
      // Re-schedule if marked as undone
      if (todo.isReminder) {
        await NotificationService().scheduleTodoNotification(todo);
      }
    }

    await DBHelper.instance.updateTodo(todo);
    loadTodos();
  }

  void _deleteTask(int id) async {
    // Get the todo first to find notificationId
    final todoToDelete = todos.firstWhere((t) => t.id == id);
    await NotificationService().cancelNotification(todoToDelete.notificationId);
    
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
    return todo.category == requiredCategory;
  }


  // --- UI Components ---

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
              child: Image.asset('assets/img/empty.png', width: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada tugas',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Ayo masukkan list pertamamu!',
              style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag(String category) {
    Color tagColor = Theme.of(context).primaryColor;
    if (category == "Umum") tagColor = Colors.blue;
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
    final titleController = TextEditingController(text: todo.title); // Prefill dengan judul lama
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
              onPressed: () => Navigator.pop(context), // tutup dialog
              child:
                  Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final updatedTodo = Todo(
                  id: todo.id,
                  title: titleController.text.trim(), // Update dengan judul baru dan (trim) hapus spasi berlebih
                  isDone: todo.isDone,
                  time: todo.time,
                  date: todo.date,
                  repeatType: todo.repeatType,
                  repeatValue: todo.repeatValue,
                  category: todo.category,
                  lastDoneDate: todo.lastDoneDate,
                  isReminder: todo.isReminder,
                  reminderTime: todo.reminderTime,
                  notificationId: todo.notificationId,
                );

                if (updatedTodo.isReminder && !updatedTodo.isDone) {
                  await NotificationService().scheduleTodoNotification(updatedTodo);
                }
                
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
        child: InkWell( // animasi klik
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
                            _buildCategoryTag(todo.category!),
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
                    if (value == 'edit')
                      _openEditTaskDialog(todo);
                    else if (value == 'delete') _deleteTask(todo.id!);
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
    List<Todo> relevantTodos = todos.where((t) {
      if (shouldReset(t)) { // ketika repeat, reset ke belum selesai
        t.isDone = false;
      }
      return shouldShowOnSelectedDate(t);
    }).toList();

    if (_currentFilter != TodoFilter.all) {
      // Filter kategori
      relevantTodos =
          relevantTodos.where((t) => _isMatchingCategory(t)).toList();
    }

    List<Todo> activeTodos = relevantTodos.where((t) => !t.isDone).toList();
    List<Todo> doneTodos = relevantTodos.where((t) => t.isDone).toList();

    activeTodos.sort((a, b) => a.time.compareTo(b.time)); // Urutkan berdasarkan waktu (ascending)
    doneTodos.sort((a, b) => a.time.compareTo(b.time));

    // Cek apakah tanggal yg dipilih adalah Hari Ini
    bool isToday = isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      key: _scaffoldKey,
      drawer: DailykuDrawer(
        selectedDate: _selectedDate,
        todos: todos,
        onDateChanged: (val) { //ketika tanggal di drawer berubah, update state tanggal terpilih
          setState(() {
            _selectedDate = val;
          });
        },
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 1.5,
          shadowColor: Colors.black.withOpacity(0.15),
          toolbarHeight: 72,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          shape: Border(
            bottom: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dailyku',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isToday
                    ? 'Hari ini, ${DateFormat('d MMM').format(_selectedDate)}'
                    : DateFormat('EEEE, d MMM yyyy', 'id_ID') // kalo bukan hari ini, tampilkan format lengkap dengan nama hari
                        .format(_selectedDate),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24, right: 16),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddTodoSheet(onSave: loadTodos),
            );
          },
          elevation: 4,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          tooltip: 'Tambah Tugas',
          child: const Icon(Icons.add_rounded, size: 24),
        ),
      ),
    );
  }
}
