import 'package:flutter/material.dart';
import '../models/todos.dart';
import '../database/db_helper.dart';

class AddTodoSheet extends StatefulWidget {
  final Function() onSave;

  const AddTodoSheet({super.key, required this.onSave});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final TextEditingController titleController = TextEditingController();

  String repeatType = 'none';
  int? repeatValue;
  String selectedCategory = "Umum";

  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime selectedDate = DateTime.now();

  final categories = ["Umum", "Kerja", "Personal", "Liburan"];

  String get formattedDate =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  String get _formattedTime =>
      "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

  void _setRepeatValue() {
    if (repeatType == 'weekly') {
      repeatValue = selectedDate.weekday; // 1-7
    } else if (repeatType == 'monthly') {
      repeatValue = selectedDate.day; // 1-31
    } else if (repeatType == 'yearly') {
      repeatValue = selectedDate.month * 100 + selectedDate.day; // MMDD
    } else {
      repeatValue = null;
    }
  }

  Future<void> _saveTodo() async {
    if (titleController.text.trim().isEmpty) return;

    _setRepeatValue();

    Todo todo = Todo(
      title: titleController.text.trim(),
      time: _formattedTime,
      date: repeatType == 'none' ? formattedDate : null,
      repeatType: repeatType,
      repeatValue: repeatValue,
      category: selectedCategory == "Umum" ? null : selectedCategory,
      isDone: false,
    );

    await DBHelper.instance.insertTodo(todo);
    widget.onSave();
    Navigator.pop(context);
  }

  void _showCategoryPicker() {
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
                        setState(() => selectedCategory = cat);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  void _showRepeatPicker() {
    String tempRepeat = repeatType;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                   const Text(
                    "Set as Repeat Task",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Switch(
                    value: tempRepeat != 'none',
                    onChanged: (v) {
                      setDialogState(() => tempRepeat = v ? 'daily' : 'none');
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Hour', 'Daily', 'Weekly', 'Monthly', 'Yearly'].map((type) {
                        String val = type.toLowerCase();
                        bool isSelected = tempRepeat == val;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (s) {
                              setDialogState(() => tempRepeat = s ? val : 'none');
                            },
                            selectedColor: const Color(0xFFEDF4FF),
                            backgroundColor: const Color(0xFFF3F6F9),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.blue : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide.none,
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.blue)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => repeatType = tempRepeat);
                    Navigator.pop(context);
                  },
                  child: const Text("DONE", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isNotEmpty = titleController.text.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            maxLines: 4,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Input new task here',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF3F6F9),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: _showCategoryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF4FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedCategory == "Umum" ? "No Category" : selectedCategory,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Colors.blue.shade400, size: 28),
                    Positioned(
                      top: 8,
                      child: Text(
                        selectedDate.day.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {}, // Future: Share functionality
                icon: Icon(Icons.share_outlined, color: Colors.blue.shade400, size: 24),
              ),
              IconButton(
                onPressed: _showRepeatPicker,
                icon: Icon(Icons.check_box_outlined, color: Colors.blue.shade400, size: 24),
              ),
              const Spacer(),
              GestureDetector(
                onTap: isNotEmpty ? _saveTodo : null,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isNotEmpty ? Colors.blue : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    boxShadow: isNotEmpty
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
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
        ],
      ),
    );
  }
}
