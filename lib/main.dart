import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/book_provider.dart';
import 'providers/loan_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/book/add_edit_book_screen.dart';
import 'screens/loans/my_loans_screen.dart';
import 'screens/loans/manage_loans_screen.dart';
import 'screens/admin/users_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
          title: 'Biblioteca Guiar',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
    
    // Check if user is authenticated (this logic might need refinement based on how UserProvider initializes)
    // For now, we rely on the stream listener in UserProvider which updates userModel.
    // However, UserProvider might take a moment to initialize. 
    // A better approach is to use a StreamBuilder here on authStateChanges directly or check userProvider.userModel
    
    return StreamBuilder(
      stream: userProvider.authService.authStateChanges, // Accessing authService directly
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}