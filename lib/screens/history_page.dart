import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/todos.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoading = true;
  Map<String, List<Todo>> _groupedHistory = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async { 
    final allTodos = await DBHelper.instance.getTodos(); 
    final historyTodos = allTodos.where((todo) {
      if (todo.repeatType == 'none') { 
        return todo.isDone; 
      } else {
        return todo.lastDoneDate != null; // Rutin yang sudah pernah dikerjakan setidaknya sekali
      }
    }).toList();

    // Sorting Descending by Last Done Date
    historyTodos.sort((a, b) { 
      final dateA = a.lastDoneDate ?? a.date ?? "1970-01-01"; 
      final dateB = b.lastDoneDate ?? b.date ?? "1970-01-01"; 
      return dateB.compareTo(dateA); // Terbaru di atas
    });

    // Grouping
    Map<String, List<Todo>> groups = {};
    for (var todo in historyTodos) {
      String dateKey = todo.lastDoneDate ?? todo.date ?? "Unknown";

      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(todo);
    }

    setState(() {
      _groupedHistory = groups;
      _isLoading = false;
    });
  }

  String _getSectionTitle(String dateString) {
    if (dateString == "Unknown") return "Lainnya";

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) return "Hari Ini";
      if (dateOnly == yesterday) return "Kemarin";

      // Format tanggal lengkap: 12 Feb 2026
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Riwayat",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedHistory.isEmpty
              ? _buildEmptyHistory()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _groupedHistory.keys.length,
                  itemBuilder: (context, index) {
                    String dateKey = _groupedHistory.keys.elementAt(index);
                    List<Todo> todos = _groupedHistory[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _getSectionTitle(dateKey),
                            style: TextStyle(
                              color: Colors.blueGrey.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ...todos.map((todo) => _buildHistoryItem(todo)),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada riwayat tugas.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Todo todo) {
    bool isRepeat = todo.repeatType != 'none';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon Checklist (Static)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600, // Opacity effect
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                if (isRepeat) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        "Rutin",
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),

          // Time
          Text(
            todo.time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
