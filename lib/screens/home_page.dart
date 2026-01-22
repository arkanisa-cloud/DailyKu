import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/todos.dart';

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

  DateTime selectedDate = DateTime.now();

  String get formattedDate => selectedDate.toIso8601String().split('T')[0];

  int get selectedDayOfWeek {
    return selectedDate.weekday; // DateTime.weekday: 1=Senin ... 7=Minggu
  }

  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dayName(int day) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return days[day - 1];
  }

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  /// Memuat semua data tugas dari database
  Future<void> loadTodos() async {
    final data = await DBHelper.instance.getTodos();
    setState(() {
      todos = data;
    });
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void showAddTodoSheet() {
    final titleController = TextEditingController();
    DateTime? taskDate;
    TimeOfDay? taskTime;
    bool isDailyRepeat = false;
    String selectedCategory = "Umum";

    final categories = ["Umum", "Kerja", "Personal", "Liburan"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tambah Tugas Baru",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Apa yang ingin kamu kerjakan?',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (text) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickAction(
                        icon: Icons.category_rounded,
                        label: selectedCategory,
                        onTap: () {
                          _showCategoryPicker(context, categories, (val) {
                            setSheetState(() => selectedCategory = val);
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        icon: Icons.calendar_month_rounded,
                        label: taskDate == null
                            ? "Hari ini"
                            : taskDate!.toIso8601String().split('T')[0],
                        onTap: () async {
                          final result = await _openDateTimePicker(
                            initialDate: taskDate ?? selectedDate,
                            initialTime: taskTime,
                            initialRepeat: isDailyRepeat,
                          );
                          if (result != null) {
                            setSheetState(() {
                              taskDate = result['date'];
                              taskTime = result['time'];
                              isDailyRepeat = result['isRepeat'];
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: titleController.text.trim().isEmpty
                          ? null
                          : () async {
                              await DBHelper.instance.insertTodo(
                                Todo(
                                  title: titleController.text.trim(),
                                  time: taskTime != null
                                      ? _formatTime(taskTime!)
                                      : "09:00",
                                  isRepeat: isDailyRepeat,
                                  date: isDailyRepeat
                                      ? null
                                      : (taskDate
                                              ?.toIso8601String()
                                              .split('T')[0] ??
                                          formattedDate),
                                  category: selectedCategory == "Umum"
                                      ? null
                                      : selectedCategory,
                                ),
                              );
                              Navigator.pop(context);
                              loadTodos();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text("Simpan Tugas",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blue),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(
      BuildContext context, List<String> categories, Function(String) onPick) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories
                .map((cat) => ListTile(
                      title: Text(cat),
                      onTap: () {
                        onPick(cat);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay t) {
    return _formatTimeOfDay(t);
  }

  /// Dialog untuk mengatur tanggal, waktu, dan pengulangan
  Future<Map<String, dynamic>?> _openDateTimePicker({
    required DateTime initialDate,
    TimeOfDay? initialTime,
    bool initialRepeat = false,
  }) {
    DateTime localDate = initialDate;
    TimeOfDay? localTime = initialTime;
    bool localRepeat = initialRepeat;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Bulan/Tahun handled by CalendarDatePicker header usually, but we can customize)
                // We'll trust CalendarDatePicker's header or hide it.
                // Let's just put the CalendarDatePicker
                Expanded(
                  child: ListView(
                    children: [
                      CalendarDatePicker(
                        initialDate: localDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        onDateChanged: (val) {
                          setModalState(() {
                            localDate = val;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      // Presets
                      const SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey.shade300),
                      // Time
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text("Time"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (localTime != null)
                              Text(_formatTimeOfDay(localTime!),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            Switch(
                              value: localTime != null,
                              onChanged: (val) async {
                                if (val) {
                                  final t = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now());
                                  if (t != null)
                                    setModalState(() => localTime = t);
                                } else {
                                  setModalState(() => localTime = null);
                                }
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      Divider(color: Colors.grey.shade300),
                      // Reminder (Visual only for now)
                      ListTile(
                        leading: const Icon(Icons.notifications_none),
                        title: const Text("Reminder"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("No",
                                style: TextStyle(
                                    color: Colors.grey)), // Placeholder
                            Switch(
                              value: false,
                              onChanged: (val) {},
                            ),
                          ],
                        ),
                      ),
                      Divider(color: Colors.grey.shade300),
                      // Repeat
                      ListTile(
                        leading: const Icon(Icons.repeat),
                        title: const Text("Repeat Daily"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (localRepeat)
                              const Text("Every Day",
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)),
                            Switch(
                              value: localRepeat,
                              onChanged: (val) {
                                setModalState(() => localRepeat = val);
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), // Cancel
                      child: const Text("CANCEL",
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        Navigator.pop(context, {
                          'date': localDate,
                          'time': localTime,
                          'isRepeat': localRepeat,
                        });
                      },
                      child: const Text("DONE",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildPresetButton(String text, VoidCallback onTap,
      {bool isSelected = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Menghapus tugas berdasarkan ID
  void _deleteTask(int id) async {
    await DBHelper.instance.deleteTodo(id);
    loadTodos();
  }

  /// Menangani perubahan status selesai/tidak pada tugas
  void _handleTaskCompletionToggle(Todo todo, bool isCompleted) async {
    if (todo.isRepeat && isCompleted == true) {
      // Logika khusus untuk tugas berulang (Daily):
      // 1. Tugas utama tidak ditandai selesai (agar muncul lagi besok)
      // 2. Simpan tanggal terakhir diselesaikan
      // 3. Buat salinan sebagai riwayat yang sudah selesai hari ini

      final updatedMasterTask = Todo(
        id: todo.id,
        title: todo.title,
        isDone: false,
        date: todo.date,
        time: todo.time,
        isRepeat: true,
        dayOfWeek: todo.dayOfWeek,
        category: todo.category,
        lastDoneDate: formattedDate,
      );
      await DBHelper.instance.updateTodo(updatedMasterTask);

      final completionHistory = Todo(
        title: todo.title,
        isDone: true,
        date: formattedDate,
        time: todo.time,
        isRepeat: false,
        category: todo.category,
      );
      await DBHelper.instance.insertTodo(completionHistory);
    } else {
      // Logika untuk tugas biasa
      await DBHelper.instance.updateTodoStatus(todo.id!, isCompleted);
    }
    loadTodos();
  }

  /// Membuka dialog untuk mengedit informasi tugas
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

                final updatedTodo = Todo(
                  id: todo.id,
                  title: titleController.text.trim(),
                  isDone: todo.isDone,
                  time: todo.time,
                  date: todo.date,
                  isRepeat: todo.isRepeat,
                  dayOfWeek: todo.dayOfWeek,
                  category: todo.category,
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

  bool _isCompletedNormalTodo(Todo todo) {
    return !todo.isRepeat && todo.isDone; // Bukan repeat dan sudah done
  }

  /// Mendapatkan daftar tugas yang aktif (belum selesai) untuk hari ini
  List<Todo> get todayTodos {
    final result = todos.where((todo) {
      if (todo.isDone && todo.isRepeat == false) return false;
      if (todo.isDone && todo.isRepeat && todo.lastDoneDate == formattedDate)
        return false;

      if (!_isMatchingCategory(todo)) return false;

      if (todo.isRepeat) {
        if (todo.lastDoneDate == formattedDate) return false;
        return true;
      }

      if (todo.date == formattedDate) return true;

      return false;
    }).toList();
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  /// Mendapatkan daftar tugas yang sudah selesai hari ini
  List<Todo> get _completedTasksToday {
    final result = todos.where((todo) {
      if (!todo.isDone) return false;
      if (!_isMatchingCategory(todo)) return false;
      if (todo.date == formattedDate) return true;
      return false;
    }).toList();
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  /// Mengecek apakah tugas sesuai dengan filter kategori yang dipilih
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

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

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
                  if (todayTodos.isEmpty && _completedTasksToday.isEmpty)
                    _buildEmptyState()
                  else ...[
                    _buildTaskSection("Tugas Aktif", todayTodos),
                    _buildTaskSection("Selesai", _completedTasksToday,
                        isInitiallyExpanded: false),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: showAddTodoSheet,
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.add_rounded, size: 36),
      ),
    );
  }

  /// Tampilan jika tidak ada tugas
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

  /// Widget item tunggal untuk daftar tugas
  Widget _buildTodoItem(Todo todo) {
    final themeColor = Theme.of(context).primaryColor;

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
            onTap: () => _handleTaskCompletionToggle(todo, !todo.isDone),
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
                            if (todo.isRepeat) ...[
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

  /// Menu opsi untuk tugas (Edit/Hapus)
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

  /// Filter chip kustom untuk kategori
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

  /// Bagian daftar tugas dengan judul yang bisa di-expand
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
}
