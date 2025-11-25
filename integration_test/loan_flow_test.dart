import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:biblioteca_guiar/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Loan Flow Integration Test', (WidgetTester tester) async {
    // 1. Setup
    app.main();
    await tester.pumpAndSettle();

    // 2. Mock/Login (Assuming we are already logged in or can login easily)
    // For integration tests on real device, we might need to rely on existing auth state
    // or perform a login flow. Here we assume the user is logged in as a Reader (Leitor).
    // If not, we would need to find login fields and enter credentials.
    
    // Check if we are at login screen
    if (find.text('Email').evaluate().isNotEmpty) {
      // Perform login
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'leitor@teste.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), '123456');
      await tester.tap(find.text('ENTRAR'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // 3. Action: Tap on the first book
    // Wait for books to load
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    final bookFinder = find.byType(Card).first;
    expect(bookFinder, findsOneWidget, reason: 'Should find at least one book card');
    
    await tester.tap(bookFinder);
    await tester.pumpAndSettle();

    // 4. Action: Tap "Solicitar Empréstimo"
    final loanButtonFinder = find.text('SOLICITAR EMPRÉSTIMO');
    expect(loanButtonFinder, findsOneWidget, reason: 'Should find loan button');
    
    await tester.tap(loanButtonFinder);
    
    // Wait for async operation (dialog or snackbar)
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 5. Verification
    // Check for success message
    final successMessageFinder = find.textContaining('Empréstimo realizado com sucesso');
    final permissionErrorFinder = find.textContaining('Erro de permissão');

    if (permissionErrorFinder.evaluate().isNotEmpty) {
      fail('Permission denied error occurred!');
    }

    expect(successMessageFinder, findsOneWidget, reason: 'Should show success message');
    
    // Optional: Check if quantity decreased (requires knowing initial quantity)
    // This is hard to verify without reading the specific widget state before and after
  });
}
