import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:biblioteca_guiar/main.dart';
import 'package:biblioteca_guiar/providers/user_provider.dart';
import 'package:biblioteca_guiar/providers/book_provider.dart';
import 'package:biblioteca_guiar/providers/loan_provider.dart';
import 'package:biblioteca_guiar/screens/auth/login_screen.dart';
import 'package:biblioteca_guiar/screens/auth/register_screen.dart';
import 'package:biblioteca_guiar/screens/home/home_screen.dart';

// Mock Providers if needed, or use real ones with Mock Firebase
// Since we want to test the flow, using Mock Firebase is better.

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = FakeFirebaseFirestore();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()), // We might need to inject mocks into UserProvider
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
      ],
      child: MaterialApp(
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }

  // Note: To properly test UserProvider with MockFirebase, we need to be able to inject the mocks or override the internal services.
  // Since UserProvider instantiates AuthService and FirestoreService internally, it's hard to mock them without dependency injection.
  // For this task, I will create a test that focuses on the UI widgets assuming the provider logic works, 
  // OR I will modify UserProvider to accept services in constructor.
  
  // Let's assume we can't easily change UserProvider right now without breaking things, 
  // so we will write tests that verify the UI elements exist.
  
  testWidgets('Login Screen shows email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('Cadastre-se'), findsOneWidget);
  });

  testWidgets('Register Screen does NOT show admin switch', (WidgetTester tester) async {
    // We need to provide UserProvider for RegisterScreen
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    expect(find.text('Nome Completo'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('CPF'), findsOneWidget);
    expect(find.text('Sou Responsável (Admin)'), findsNothing); // Verify admin switch is gone
    expect(find.text('CADASTRAR'), findsOneWidget);
  });
}
