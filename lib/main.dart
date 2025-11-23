import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BibliotecaGuiarApp());
}

class BibliotecaGuiarApp extends StatelessWidget {
  const BibliotecaGuiarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblioteca Guiar',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Biblioteca Guiar')),
        body: const Center(
          child: Text("Firebase conectado com sucesso!"),
        ),
      ),
    );
  }
}
