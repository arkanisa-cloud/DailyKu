import 'package:flutter/material.dart';
import '../models/todos.dart';
import '../database/db_helper.dart';

class AddTodoSheet extends StatefulWidget {
  final VoidCallback onSave;

  const AddTodoSheet({super.key, required this.onSave});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final TextEditingController _titleController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _repeatType = 'none'; // none, daily, weekly, monthly, yearly
  int? _repeatValue;

  String _selectedCategory = "Umum";
  final List<String> _categories = ["Umum", "Kerja", "Personal", "Liburan"];

  bool _isReminder = false;
  TimeOfDay? _reminderTime;

  // ---------- Helper ----------

  String _formatDate(DateTime date) => date.toIso8601String().split('T')[0];

  String _formatTime(TimeOfDay time) =>
      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

  void _calculateRepeatValue(DateTime date) {
    if (_repeatType == 'weekly') {
      _repeatValue = date.weekday; // 1-7
    } else if (_repeatType == 'monthly') {
      _repeatValue = date.day; // 1-31
    } else if (_repeatType == 'yearly') {
      _repeatValue = date.month * 100 + date.day; // MMDD
    } else {
      _repeatValue = null;
    }
  }

  // ---------- Save ----------

  Future<void> _saveTodo() async {
    if (_titleController.text.trim().isEmpty) return;

    final DateTime finalDate = _selectedDate ?? DateTime.now();
    _calculateRepeatValue(finalDate);

    final Todo todo = Todo(
      title: _titleController.text.trim(),
      time: _selectedTime != null ? _formatTime(_selectedTime!) : "09:00",
      date: _repeatType == 'none' ? _formatDate(finalDate) : null,
      repeatType: _repeatType,
      repeatValue: _repeatValue,
      category: _selectedCategory == "Umum" ? null : _selectedCategory,
      isDone: false,
      isReminder: _isReminder,
      reminderTime: _reminderTime != null ? _formatTime(_reminderTime!) : null,
    );

    await DBHelper.instance.insertTodo(todo);
    widget.onSave();
    Navigator.pop(context);
  }

  // ---------- UI Helpers ----------

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.map((cat) {
            return ListTile(
              title: Text(cat),
              onTap: () {
                setState(() => _selectedCategory = cat);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _openDateTimePicker() async {
    DateTime tempDate = _selectedDate ?? DateTime.now();
    TimeOfDay? tempTime = _selectedTime;
    String tempRepeat = _repeatType;
    bool tempIsReminder = _isReminder;
    TimeOfDay? tempReminderTime = _reminderTime;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final primaryColor = Theme.of(context).primaryColor;
            final isRepeatEnabled = tempRepeat != 'none';

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        CalendarDatePicker(
                          initialDate: tempDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                          onDateChanged: (val) {
                            setModalState(() => tempDate = val);
                          },
                        ),
                        const Divider(height: 32),
                        
                        // Set Time
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.access_time_rounded, color: primaryColor),
                          ),
                          title: const Text("Tentukan Waktu", style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Switch(
                            value: tempTime != null,
                            activeColor: primaryColor,
                            onChanged: (val) async {
                              if (val) {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (t != null) setModalState(() => tempTime = t);
                              } else {
                                setModalState(() => tempTime = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Upgrade Repeat Section
                        _buildRepeatSettingSection(tempRepeat, (newRepeat) {
                          setModalState(() => tempRepeat = newRepeat);
                        }),

                        const SizedBox(height: 16),

                        // Reminder Section (Below Repeat)
                        _buildReminderSettingSection(tempIsReminder, tempReminderTime, (enabled, time) {
                          setModalState(() {
                            tempIsReminder = enabled;
                            tempReminderTime = time;
                          });
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text("Batal", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'date': tempDate,
                              'time': tempTime,
                              'repeat': tempRepeat,
                              'isReminder': tempIsReminder,
                              'reminderTime': tempReminderTime,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Terapkan", style: TextStyle(fontWeight: FontWeight.bold)),
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

    if (result != null) {
      setState(() {
        _selectedDate = result['date'];
        _selectedTime = result['time'];
        _repeatType = result['repeat'];
        _isReminder = result['isReminder'];
        _reminderTime = result['reminderTime'];
      });
    }
  }

  Widget _buildRepeatSettingSection(String currentRepeat, Function(String) onRepeatChanged) {
    bool isEnabled = currentRepeat != 'none';
    final primaryColor = Theme.of(context).primaryColor;
    final List<Map<String, String>> options = [
      {'val': 'hourly', 'label': 'Jam'},
      {'val': 'daily', 'label': 'Harian'},
      {'val': 'weekly', 'label': 'Mingguan'},
      {'val': 'monthly', 'label': 'Bulanan'},
      {'val': 'yearly', 'label': 'Tahunan'},
    ];

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.repeat_rounded, color: Colors.orange),
          ),
          title: const Text("Pengulangan", style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Switch(
            value: isEnabled,
            activeColor: primaryColor,
            onChanged: (val) {
              onRepeatChanged(val ? 'daily' : 'none');
            },
          ),
        ),
        if (isEnabled)
          Container(
            padding: const EdgeInsets.only(top: 8),
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final opt = options[index];
                final isSelected = currentRepeat == opt['val'];
                return InkWell(
                  onTap: () => onRepeatChanged(opt['val']!),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      opt['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReminderSettingSection(bool isEnabled, TimeOfDay? time, Function(bool, TimeOfDay?) onChanged) {
    final primaryColor = Theme.of(context).primaryColor;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.notifications_active_outlined, color: Colors.red),
      ),
      title: const Text("Pengingat", style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: (isEnabled && time != null) 
          ? Text("Pukul ${_formatTime(time)}", style: TextStyle(color: primaryColor, fontSize: 12))
          : null,
      trailing: Switch(
        value: isEnabled,
        activeColor: primaryColor,
        onChanged: (val) async {
          if (val) {
            final t = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (t != null) {
              onChanged(true, t);
            }
          } else {
            onChanged(false, null);
          }
        },
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    bool hasText = _titleController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _titleController,
                autofocus: true,
                maxLines: null,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: "Input new task here",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (text) {
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Actions Row
            Row(
              children: [
                // Category Chip
                _buildCategoryChip(),
                const SizedBox(width: 8),

                // Date Picker Button
                _buildDateIcon(),
                const SizedBox(width: 8),

                // Reminder Status (Small indicator if active)
                if (_isReminder)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, size: 22, color: Colors.red),
                  ),

                const Spacer(),

                // Dynamic Save Button
                GestureDetector(
                  onTap: hasText ? _saveTodo : null,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: hasText ? Theme.of(context).primaryColor : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: hasText
                          ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    final primaryColor = Theme.of(context).primaryColor;
    return InkWell(
      onTap: _showCategoryPicker,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 18, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              _selectedCategory,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateIcon() {
    final primaryColor = Theme.of(context).primaryColor;
    return IconButton(
      onPressed: _openDateTimePicker,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 22, color: primaryColor),
            if (_selectedDate != null)
              Positioned(
                bottom: 0,
                child: Text(
                  _selectedDate!.day.toString(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
