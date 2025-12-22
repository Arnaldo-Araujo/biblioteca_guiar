import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Fields for Step 2
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController(); // Detalhes (Rua, Nº)

  // Location & Church State
  String? _selectedUF;
  String? _selectedCity;
  String? _selectedChurchId;
  
  List<String> _cities = [];
  bool _isLoadingCities = false;

  final List<String> _ufs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  // Specific Constants
  static const String _targetUF = 'TO';
  static const String _targetCity = 'Palmas';
  static const String _churchName = 'Igreja Metodista de Palmas';
  // You might want to store the ID in constants or fetch from DB if scalable
  static const String _churchId = 'metodista_palmas'; 

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _fetchCities(String uf) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _selectedCity = null;
      _selectedChurchId = null; // Reset church if location changes
    });

    try {
      final url = Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$uf/distritos');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Extract names and sort
        final List<String> cityNames = data.map((e) => e['nome'].toString()).toList();
        cityNames.sort();

        setState(() {
          _cities = cityNames;
        });
      } else {
        print('Erro IBGE: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar cidades: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao carregar cidades. Verifique sua conexão.')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 600,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    } catch (e) {
      print("Erro ao selecionar imagem: $e");
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Erro de Cadastro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate back to Login as user was deleted
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Voltar ao Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final showChurchSelect = _selectedUF == _targetUF && _selectedCity == _targetCity;

    return Scaffold(
      appBar: AppBar(title: const Text('Completar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Photo Picker
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _imageFile != null ? FileImage(File(_imageFile!.path)) : null,
                  child: _imageFile == null
                      ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Toque para adicionar foto'),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _cpfController,
                decoration: const InputDecoration(labelText: 'CPF'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo obrigatório';
                  if (!CPFValidator.isValid(value)) return 'CPF inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              
              // --- ENDEREÇO & LOCALIZAÇÃO ---
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'UF'),
                      value: _selectedUF,
                      items: _ufs.map((uf) {
                        return DropdownMenuItem(value: uf, child: Text(uf));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) _fetchCities(val);
                        setState(() => _selectedUF = val);
                      },
                      validator: (v) => v == null ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Cidade/Distrito'),
                      value: _selectedCity,
                      isExpanded: true,
                      items: _cities.map((city) {
                        return DropdownMenuItem(value: city, child: Text(city, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: _cities.isEmpty ? null : (val) {
                         setState(() {
                           _selectedCity = val;
                           // Reset church if changed away from target
                           if (!(_selectedUF == _targetUF && val == _targetCity)) {
                             _selectedChurchId = null;
                           }
                         });
                      },
                       validator: (v) => v == null ? 'Obrigatório' : null,
                       icon: _isLoadingCities 
                         ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                         : const Icon(Icons.arrow_drop_down),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(
                  labelText: 'Endereço (Rua, Nº, Bairro)',
                  hintText: 'Ex: Rua 10, Qd 2, Lote 5',
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // --- LOGICA DA IGREJA ---
              if (showChurchSelect)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Qual sua igreja?',
                      border: OutlineInputBorder(),
                      fillColor: Color(0xFFE8F5E9), // Light Green hint
                      filled: true,
                    ),
                    value: _selectedChurchId,
                    items: const [
                       DropdownMenuItem(
                         value: _churchId, 
                         child: Text(_churchName, style: TextStyle(fontWeight: FontWeight.bold))
                       ),
                       DropdownMenuItem(
                         value: 'OUTRA', 
                         child: Text('Outras / Nenhuma')
                       ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedChurchId = val);
                    },
                    validator: (v) => v == null ? 'Por favor, selecione uma opção' : null,
                  ),
                ),

              const SizedBox(height: 30),
              
              if (_isLoading || userProvider.isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);
                        try {
                          // Tratamento do churchId
                          // Se for OUTRA, salvamos como null no banco (conforme requisito)
                          final finalChurchId = _selectedChurchId == 'OUTRA' ? null : _selectedChurchId;

                          // Assemble partial user model
                          final partialUser = UserModel(
                            uid: '', // Provider will fill this from Auth
                            nome: _nomeController.text.trim(),
                            email: '', // Provider will fill from Auth
                            cpf: _cpfController.text.trim(),
                            telefone: _telefoneController.text.trim(),
                            endereco: _enderecoController.text.trim(),
                            estado: _selectedUF,
                            cidade: _selectedCity,
                            churchId: finalChurchId,
                            // role defaults to USER
                          );

                          await userProvider.completeRegistration(
                            userModel: partialUser,
                            imageFile: _imageFile != null ? File(_imageFile!.path) : null,
                          );

                          // Success! AuthWrapper or logic can handle it. 
                          // We also navigate explicitly to / to be sure.
                          if (mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                          
                        } catch (e) {
                          if (mounted) {
                             if (e.toString().contains("CPF já possui")) {
                               _handleError(e.toString().replaceAll('Exception: ', ''));
                             } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text("Erro: ${e.toString()}"), backgroundColor: Colors.red),
                               );
                             }
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('FINALIZAR CADASTRO'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
