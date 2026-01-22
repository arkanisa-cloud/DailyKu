class Todo {
  int? id;
  String title;
  bool isDone;

  String? date; // yyyy-MM-dd (sekali)
  String time; // HH:mm

  String repeatType; // none, weekly, monthly, yearly
  int? repeatValue;

  String? category;
  String? lastDoneDate; // yyyy-MM-dd

  Todo({
    this.id,
    required this.title,
    this.isDone = false,
    this.date,
    required this.time,
    this.repeatType = 'none',
    this.repeatValue,
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
      'repeatType': repeatType,
      'repeatValue': repeatValue,
      'category': category,
      'lastDoneDate': lastDoneDate,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      isDone: map['isDone'] == 1,
      date: map['date'],
      time: map['time'],
      repeatType: map['repeatType'],
      repeatValue: map['repeatValue'],
      category: map['category'],
      lastDoneDate: map['lastDoneDate'],
    );
  }
}
