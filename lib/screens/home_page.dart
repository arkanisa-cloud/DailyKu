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

  void loadTodos() async {
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
    // Default values
    DateTime? tempDate;
    TimeOfDay? tempTime;
    bool tempRepeat = false;
    String selectedCategory = "No Category"; // Default

    final categories = ["No Category", "Kerja", "Personal", "Liburan"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Gunakan StatefulBuilder jika ingin mengubah state icon (misal warna berubah jika date terpilih)
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    onChanged: (_) =>
                        setStateSheet(() {}), // biar icon ikut update
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Masukkan jadwalmu di sini!',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Category Dropdown
                      PopupMenuButton<String>(
                        initialValue: selectedCategory,
                        onSelected: (String value) {
                          setStateSheet(() {
                            selectedCategory = value;
                          });
                        },
                        itemBuilder: (BuildContext context) {
                          return categories.map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            selectedCategory,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Calendar Button -> Opens Detail Modal
                      IconButton(
                        icon: Icon(Icons.calendar_today_outlined,
                            color:
                                tempDate != null ? Colors.blue : Colors.grey),
                        onPressed: () async {
                          final result = await _showDetailDateModal(
                            initialDate: tempDate ?? selectedDate,
                            initialTime: tempTime,
                            initialRepeat: tempRepeat,
                          );
                          if (result != null) {
                            setStateSheet(() {
                              tempDate = result['date'];
                              tempTime = result['time'];
                              tempRepeat = result['isRepeat'];
                            });
                          }
                        },
                      ),
                      const Spacer(),
                      Container(
                        decoration: const BoxDecoration(
                            color: Colors.grey, shape: BoxShape.circle),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_upward,
                            color: titleController.text.trim().isNotEmpty
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty) return;

                            await DBHelper.instance.insertTodo(
                              Todo(
                                title: titleController.text.trim(),
                                time: tempTime != null
                                    ? _formatTimeOfDay(tempTime!)
                                    : "09:00",
                                isRepeat: tempRepeat,
                                date: tempRepeat
                                    ? null
                                    : (tempDate
                                            ?.toIso8601String()
                                            .split('T')[0] ??
                                        formattedDate),
                                dayOfWeek: null,
                                category: selectedCategory == "No Category"
                                    ? null
                                    : selectedCategory,
                              ),
                            );

                            Navigator.pop(context);
                            loadTodos();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showDetailDateModal({
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

  void deleteTodo(int id) async {
    await DBHelper.instance.deleteTodo(id);
    loadTodos();
  }

  void toggleTodo(Todo todo, bool value) async {
    if (todo.isRepeat && value == true) {
      // Logic Repeat:
      // 1. Jangan ubah isDone master jadi true (agar besok masih ada)
      // 2. Set lastDoneDate = formattedDate
      // 3. Buat duplikat task yg isDone=true, isRepeat=false, date=formattedDate untuk history hari ini

      // Update Master
      final updatedMaster = Todo(
        id: todo.id,
        title: todo.title,
        isDone: false, // Tetap false
        date: todo.date,
        time: todo.time,
        isRepeat: true,
        dayOfWeek: todo.dayOfWeek,
        category: todo.category,
        lastDoneDate: formattedDate, // Tandai sdh dikerjakan hari ini
      );
      await DBHelper.instance.updateTodo(updatedMaster);

      // Buat History
      final historyTask = Todo(
        title: todo.title,
        isDone: true,
        date: formattedDate,
        time: todo.time,
        isRepeat: false, // Jadi single task di history
        category: todo.category,
      );
      await DBHelper.instance.insertTodo(historyTask);
    } else {
      // Logic Biasa
      await DBHelper.instance.updateTodoStatus(todo.id!, value);
    }
    loadTodos();
  }

  void editTodo(Todo todo) {
    final controller = TextEditingController(text: todo.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Masukkan task baru',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;

                final updatedTodo = Todo(
                  id: todo.id, // tetap pake id lama
                  title: controller.text.trim(), // judul baru
                  isDone: todo.isDone, // status tidak berubah
                  time: todo.time, // jam tidak berubah
                  date: todo.date,
                  isRepeat: todo.isRepeat,
                  dayOfWeek: todo.dayOfWeek,
                  category: todo.category,
                );

                await DBHelper.instance.updateTodo(updatedTodo);

                Navigator.pop(context);
                loadTodos();
              },
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

  List<Todo> get todayTodos {
    final result = todos.where((todo) {
      if (todo.isDone && todo.isRepeat == false)
        return false; // Selesai biasa -> masuk Completed
      if (todo.isDone && todo.isRepeat && todo.lastDoneDate == formattedDate)
        return false; // Repeat yg sdh selesai hari ini

      // Filter Category
      if (!_checkCategory(todo))
        return false; // kalo kategori nggak sesuai filter jangan tampilkan!

      // 1. Repeat (Active & Not done today)
      if (todo.isRepeat) {
        if (todo.lastDoneDate == formattedDate)
          return false; // Sudah done hari ini jangan tampilkan
        return true; // kalo yang belum done, tampilkan
      }

      // 2. Single Task Today
      if (todo.date == formattedDate) {
        return true;
      }

      if (_isCompletedNormalTodo(todo))
        return false; // todo biasa yang done jangan tampilkan

      return false;
    }).toList();
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  List<Todo> get completedTodayTodos {
    final result = todos.where((todo) {
      if (!todo.isDone) return false;
      if (!_checkCategory(todo)) return false;

      // Check if done today
      // Logic: date == today OR lastDoneDate == today (for repeats history if stored that way)
      // With new logic: we create a COPY with isRepeat=false, isDone=true, date=today.
      // So just check date == formattedDate
      if (todo.date == formattedDate) return true;

      return false;
    }).toList();
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  bool _checkCategory(Todo todo) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dailyku'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterButton('Semua', TodoFilter.all),
                _buildFilterButton('Kerja', TodoFilter.kerja),
                _buildFilterButton('Personal', TodoFilter.personal),
                _buildFilterButton('Liburan', TodoFilter.liburan),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                children: [
                  _buildSection("Today", todayTodos),
                  _buildSection("Completed Today", completedTodayTodos,
                      isExpanded: false),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTodoSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.event_note, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada jadwal hari ini',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoTile(Todo todo) {
    return GestureDetector(
      onLongPress: () => _showTodoOptions(todo),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  todo.time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (todo.isRepeat)
                  const Icon(Icons.repeat, size: 14, color: Colors.blue),
              ],
            ),
            title: Text(
              todo.title,
              style: TextStyle(
                fontSize: 16,
                decoration: todo.isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: todo.isDone ? Colors.grey : Colors.black87,
                fontWeight: todo.isDone ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            trailing: Checkbox(
              value: todo.isDone,
              onChanged: (value) {
                toggleTodo(todo, value!);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showTodoOptions(Todo todo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Jadwal'),
              onTap: () {
                Navigator.pop(context);
                editTodo(todo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Jadwal'),
              onTap: () {
                Navigator.pop(context);
                deleteTodo(todo.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, TodoFilter filter) {
    final isActive = _currentFilter == filter;

    return ChoiceChip(
      label: Text(text),
      selected: isActive,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
          });
        }
      },
      selectedColor: Colors.blue.shade100, // Light blue for selected
      backgroundColor: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade200)),
      labelStyle: TextStyle(
        color: isActive ? Colors.blue.shade900 : Colors.grey,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSection(String title, List<Todo> items,
      {bool isExpanded = true}) {
    if (items.isEmpty && title != "Completed Today")
      return const SizedBox.shrink();
    if (items.isEmpty && title == "Completed Today") {
      return const SizedBox.shrink(); // Hide if empty
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: items.map((todo) {
          return Dismissible(
            key: ValueKey(todo.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              // Confirmation logic if needed
              return true;
            },
            onDismissed: (_) {
              deleteTodo(todo.id!);
            },
            child: _buildTodoTile(todo),
          );
        }).toList(),
      ),
    );
  }
}
