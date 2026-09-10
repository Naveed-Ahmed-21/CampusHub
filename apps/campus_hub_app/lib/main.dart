import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/media_storage_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaStorageService.ensureInitialized();

  runApp(
    const ProviderScope(
      child: CampusHubApp(),
    ),
  );
}