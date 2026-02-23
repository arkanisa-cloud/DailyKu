import 'package:flutter/material.dart';
import '../models/todos.dart';
import '../screens/history_page.dart';

class DailykuDrawer extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final List<Todo> todos; 

  const DailykuDrawer({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.todos,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drawer
          Container(
            padding:
                const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dailyku',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ringkasan aktivitas harianmu',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.blueGrey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Kalender
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      onDateChanged: (value) {
                        onDateChanged(value);
                        Navigator.pop(
                            context); // Tutup drawer setelah pilih tanggal
                      },
                    ),
                  ),

                  const Divider(height: 1, indent: 24, endIndent: 24),
                  const SizedBox(height: 16),

                  // Menu Drawer
                  _buildMenuItem(
                    context,
                    icon: Icons.history_edu_rounded,
                    title: 'Semua Riwayat',
                    onTap: () {
                      Navigator.pop(context); // Tutup drawer dulu
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Versi App (Footer)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Versi 1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return ListTile(
      leading: Icon(icon, color: primaryColor, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 15,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: primaryColor.withOpacity(0.08),
      splashColor: primaryColor.withOpacity(0.12),
    );
  }
}
