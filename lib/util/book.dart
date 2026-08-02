class Book {
  final int? id;
  final String title;
  final String? author;
  final String status;
  final String? datePurchase;
  final String? dateFinished;
  final String? isbn;
  final String? publisher;

  Book({
    this.id,
    required this.title,
    this.author,
    required this.status,
    this.datePurchase,
    this.dateFinished,
    this.isbn,
    this.publisher,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'] ?? '',
      author: map['author'],
      status: map['status'] ?? '0',
      datePurchase: map['datePurchase'],
      dateFinished: map['dateFinished'],
      isbn: map['isbn'],
      publisher: map['publisher'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'status': status,
      'datePurchase': datePurchase,
      'dateFinished': dateFinished,
      'isbn': isbn,
      'publisher': publisher,
    };
  }
}