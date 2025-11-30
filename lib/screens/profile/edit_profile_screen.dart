import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_network_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).userModel!;
    _nameController = TextEditingController(text: user.nome);
    _phoneController = TextEditingController(text: user.telefone);
    _addressController = TextEditingController(text: user.endereco);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.userModel!;

    final updatedUser = UserModel(
      uid: currentUser.uid,
      nome: _nameController.text.trim(),
      email: currentUser.email,
      cpf: currentUser.cpf,
      telefone: _phoneController.text.trim(),
      endereco: _addressController.text.trim(),
      isAdmin: currentUser.isAdmin,
      isHelper: currentUser.isHelper,
      photoUrl: currentUser.photoUrl,
    );

    try {
      await userProvider.updateUserProfile(updatedUser, _imageFile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.userModel!;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    _imageFile != null
                        ? CircleAvatar(
                            radius: 60,
                            backgroundImage: FileImage(_imageFile!),
                          )
                        : CustomNetworkImage(
                            imageUrl: user.photoUrl,
                            width: 120,
                            height: 120,
                            isCircular: true,
                            fallbackIcon: Icons.person,
                            fallbackIconSize: 60,
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Endereço'),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 32),
              if (userProvider.isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('SALVAR ALTERAÇÕES'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
