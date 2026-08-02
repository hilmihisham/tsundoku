class Book {
  final int? id;
  final String title;
  final String? author;
  final String status;
  final String? datePurchase;
  final String? dateFinished;
  final String? dateCreated;
  final String? isbn;
  final String? publisher;

  Book({
    this.id,
    required this.title,
    this.author,
    required this.status,
    this.datePurchase,
    this.dateFinished,
    this.dateCreated,
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
      dateCreated: map['dateCreated'],
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
      'dateCreated': dateCreated,
      'isbn': isbn,
      'publisher': publisher,
    };
  }

  // helper methods below
  bool get isNew => status == '0';
  bool get isReading => status == '1';
  bool get isFinished => status == '2';
  
  String get displayTitle => title.isNotEmpty ? title : 'Untitled';

  String get displayAuthor => author ?? 'Unknown Author';

  String toDebugString() {
    return 'Book(id: $id, title: $title, author: $author, status: $status, dateCreated: $dateCreated)';
  }
}