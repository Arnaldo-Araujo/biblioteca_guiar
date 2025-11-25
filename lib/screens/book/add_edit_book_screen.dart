import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../providers/book_provider.dart';
import '../../widgets/custom_network_image.dart';

class AddEditBookScreen extends StatefulWidget {
  const AddEditBookScreen({super.key});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _sinopseController = TextEditingController();
  final _quantidadeController = TextEditingController();
  
  File? _imageFile;
  String? _currentImageUrl;
  BookModel? _editingBook;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BookModel && _editingBook == null) {
      _editingBook = args;
      _tituloController.text = args.titulo;
      _autorController.text = args.autor;
      _isbnController.text = args.isbn;
      _categoriaController.text = args.categoria;
      _sinopseController.text = args.sinopse;
      _quantidadeController.text = args.quantidadeDisponivel.toString();
      _currentImageUrl = args.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _currentImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma imagem de capa')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      
      final bookData = BookModel(
        id: _editingBook?.id ?? '',
        titulo: _tituloController.text.trim(),
        autor: _autorController.text.trim(),
        isbn: _isbnController.text.trim(),
        categoria: _categoriaController.text.trim(),
        sinopse: _sinopseController.text.trim(),
        quantidadeDisponivel: int.parse(_quantidadeController.text.trim()),
        imageUrl: _currentImageUrl ?? '',
      );

      if (_editingBook != null) {
        await bookProvider.updateBook(bookData, _imageFile);
      } else {
        await bookProvider.addBook(bookData, _imageFile);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editingBook != null ? 'Editar Livro' : 'Cadastrar Livro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Câmera'),
                            onTap: () async {
                              Navigator.pop(context);
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(source: ImageSource.camera);
                              if (pickedFile != null) {
                                setState(() {
                                  _imageFile = File(pickedFile.path);
                                });
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Galeria'),
                            onTap: () async {
                              Navigator.pop(context);
                              _pickImage();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 200,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomNetworkImage(
                                imageUrl: _currentImageUrl!,
                                fit: BoxFit.cover,
                                fallbackIcon: Icons.book,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Adicionar Capa', style: TextStyle(color: Colors.grey)),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _autorController,
                decoration: const InputDecoration(labelText: 'Autor'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _isbnController,
                decoration: const InputDecoration(labelText: 'ISBN'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoria'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sinopseController,
                      decoration: const InputDecoration(labelText: 'Sinopse'),
                      maxLines: 3,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.document_scanner),
                    tooltip: 'Escanear Texto',
                    onPressed: () {
                      // Placeholder for OCR function
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funcionalidade de OCR em desenvolvimento')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantidadeController,
                decoration: const InputDecoration(labelText: 'Quantidade Disponível'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveBook,
                    child: const Text('SALVAR'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
