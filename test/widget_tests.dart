import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:biblioteca_guiar/main.dart';
import 'package:biblioteca_guiar/providers/user_provider.dart';
import 'package:biblioteca_guiar/providers/book_provider.dart';
import 'package:biblioteca_guiar/providers/loan_provider.dart';
import 'package:biblioteca_guiar/screens/auth/login_screen.dart';
import 'package:biblioteca_guiar/screens/auth/register_screen.dart';
import 'package:biblioteca_guiar/screens/home/home_screen.dart';
import 'package:biblioteca_guiar/services/auth_service.dart';
import 'package:biblioteca_guiar/services/firestore_service.dart';
import 'package:biblioteca_guiar/models/user_model.dart';
import 'package:biblioteca_guiar/models/book_model.dart';
import 'package:biblioteca_guiar/models/loan_model.dart';

// Manual Mocks
class MockAuthService implements AuthService {
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  
  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  void emitUser(User? user) {
    _authStateController.add(user);
  }

  @override
  Future<User?> signIn(String email, String password) async {
    return null; 
  }

  @override
  Future<User?> signUp(String email, String password, UserModel userModel) async {
    return null; 
  }

  @override
  Future<void> signOut() async {
    emitUser(null);
  }
}

class MockFirestoreService implements FirestoreService {
  @override
  Future<UserModel?> getUser(String uid) async {
    return UserModel(
      uid: uid,
      nome: 'Test User',
      email: 'test@example.com',
      cpf: '12345678900',
      telefone: '123456789',
      endereco: 'Test Address',
      isAdmin: false,
    );
  }
  

  
  @override
  Future<List<UserModel>> getAllUsers() async => [];

  @override
  Future<void> updateUser(UserModel user) async {}

  @override
  Stream<List<BookModel>> getBooks({bool showInactive = false}) => Stream.value([]);

  @override
  Future<bool> checkBookHasLoans(String bookId) async => false;

  @override
  Future<void> softDeleteBook(String bookId) async {}

  @override
  Future<void> deleteBook(String bookId) async {}

  @override
  Future<void> addBook(BookModel book) async {}

  @override
  Future<void> updateBook(BookModel book) async {}

  @override
  Future<void> reserveBook(LoanModel loan) async {}

  @override
  Future<void> activateLoan(String loanId, String bookId) async {}

  @override
  Future<void> returnBook(String loanId, String bookId) async {}

  @override
  Future<void> renewLoan(String loanId, DateTime newDate) async {}

  @override
  Stream<List<LoanModel>> getUserLoans(String uid) => Stream.value([]);

  @override
  Stream<List<LoanModel>> getAllLoans() => Stream.value([]);
}

class MockBookProvider extends ChangeNotifier implements BookProvider {
  @override
  Stream<List<BookModel>> getBooksStream({bool showInactive = false}) => Stream.value([]);

  @override
  Future<void> deleteBook(String bookId) async {}
  
  @override
  Future<void> addBook(BookModel book, File? imageFile) async {}

  @override
  Future<void> updateBook(BookModel book, File? imageFile) async {}
}

class MockLoanProvider extends ChangeNotifier implements LoanProvider {
  @override
  Stream<List<LoanModel>> getUserLoans(String uid) => Stream.value([]);

  @override
  Stream<List<LoanModel>> getAllLoans() => Stream.value([]);

  @override
  Future<void> reserveBook(LoanModel loan) async {}

  @override
  Future<void> activateLoan(String loanId, String bookId) async {}

  @override
  Future<void> returnBook(String loanId, String bookId) async {}

  @override
  Future<void> renewLoan(String loanId, DateTime newDate) async {}
}

void main() {
  late MockAuthService mockAuthService;
  late MockFirestoreService mockFirestoreService;
  late NavigatorObserver mockObserver;

  setUp(() {
    mockAuthService = MockAuthService();
    mockFirestoreService = MockFirestoreService();
    mockObserver = NavigatorObserver();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(
            authService: mockAuthService,
            firestoreService: mockFirestoreService,
          ),
        ),
        ChangeNotifierProvider<BookProvider>(create: (_) => MockBookProvider()),
        ChangeNotifierProvider<LoanProvider>(create: (_) => MockLoanProvider()),
      ],
      child: MaterialApp(
        home: const AuthWrapper(),
        navigatorObservers: [mockObserver],
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/my_loans': (context) => const Scaffold(body: Text('My Loans')),
          '/manage_loans': (context) => const Scaffold(body: Text('Manage Loans')),
          '/add_book': (context) => const Scaffold(body: Text('Add Book')),
        },
      ),
    );
  }

  testWidgets('Login Screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    mockAuthService.emitUser(null); // Emit after listener is attached
    await tester.pump(); 

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });

  testWidgets('Register Screen does NOT show admin switch', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    mockAuthService.emitUser(null);
    await tester.pump();

    // Navigate to register
    await tester.tap(find.text('Quero me cadastrar'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Sou Responsável (Admin)'), findsNothing);
    expect(find.text('Nome Completo'), findsOneWidget);
  });

  testWidgets('Registration flow pops back to login/home', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    mockAuthService.emitUser(null);
    await tester.pump();

    // Go to register
    await tester.tap(find.text('Quero me cadastrar'));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.widgetWithText(TextFormField, 'Nome Completo'), 'Test User');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'CPF'), '12345678900');
    await tester.enterText(find.widgetWithText(TextFormField, 'Telefone (WhatsApp)'), '123456789');
    await tester.enterText(find.widgetWithText(TextFormField, 'Endereço'), 'Test Address');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'password123');

    // Tap register
    await tester.tap(find.text('CADASTRAR'));
    await tester.pump(); 

    await tester.pumpAndSettle();

    // Verify we are back at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
  });
}
