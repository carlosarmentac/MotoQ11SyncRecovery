import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/storage/q11_local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent on-device storage
  final prefs = await SharedPreferences.getInstance();
  final localStorage = Q11LocalStorage(prefs);

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
      ],
      child: const Q11SaverApp(),
    ),
  );
}
