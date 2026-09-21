import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motoq11_saver/app.dart';
import 'package:motoq11_saver/core/providers/app_providers.dart';
import 'package:motoq11_saver/core/storage/q11_local_storage.dart';

void main() {
  testWidgets('Q11SaverApp smoke test and navigation verify', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = Q11LocalStorage(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
        ],
        child: const Q11SaverApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify app title or step card rendered
    expect(find.textContaining('Moto Q11'), findsWidgets);
    expect(find.textContaining('Setup Wizard'), findsWidgets);
  });
}
