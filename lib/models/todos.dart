  class Todo {
    int? id;
    String title;
    bool isDone;

    // Hybrid schedule
    String? date; // yyyy-MM-dd (untuk sekali)
    String time; // HH:mm
    bool isRepeat; // true = rutin mingguan
    int? dayOfWeek; // 1=Senin ... 7=Minggu
    String? category; // 'Kerja', 'Personal', 'Liburan'
    String? lastDoneDate; // yyyy-MM-dd (untuk tracking repeat daily selesai hari ini)

    Todo({
      this.id,
      required this.title,
      this.isDone = false,
      this.date,
      required this.time,
      this.isRepeat = false,
      this.dayOfWeek,
      this.category,
      this.lastDoneDate,
    });

    Map<String, dynamic> toMap() {
      return {
        'id': id,
        'title': title,
        'isDone': isDone ? 1 : 0,
        'date': date,
        'time': time,
        'isRepeat': isRepeat ? 1 : 0,
        'dayOfWeek': dayOfWeek,
        'category': category,
        'lastDoneDate': lastDoneDate,
      };
    }

    factory Todo.fromMap(Map<String, dynamic> map) {
      return Todo(
        id: map['id'] as int?,
        title: map['title'] as String,
        isDone: (map['isDone'] as int) == 1,
        date: map['date'] as String?,
        time: map['time'] as String,
        isRepeat: (map['isRepeat'] as int) == 1,
        dayOfWeek: map['dayOfWeek'] as int?,
        category: map['category'] as String?,
        lastDoneDate: map['lastDoneDate'] as String?,
      );
    }
  }
