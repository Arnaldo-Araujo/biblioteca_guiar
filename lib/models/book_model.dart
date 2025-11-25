class BookModel {
  final String id;
  final String titulo;
  final String autor;
  final String isbn;
  final String categoria;
  final String sinopse;
  final int quantidadeDisponivel;
  final String imageUrl;
  final bool isActive;

  BookModel({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.isbn,
    required this.categoria,
    required this.sinopse,
    required this.quantidadeDisponivel,
    required this.imageUrl,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'autor': autor,
      'isbn': isbn,
      'categoria': categoria,
      'sinopse': sinopse,
      'quantidadeDisponivel': quantidadeDisponivel,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BookModel(
      id: documentId,
      titulo: map['titulo'] ?? '',
      autor: map['autor'] ?? '',
      isbn: map['isbn'] ?? '',
      categoria: map['categoria'] ?? '',
      sinopse: map['sinopse'] ?? '',
      quantidadeDisponivel: map['quantidadeDisponivel'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}

