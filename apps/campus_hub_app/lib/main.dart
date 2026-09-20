import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/media_storage_service.dart';
import 'core/services/local_notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaStorageService.ensureInitialized();
  await LocalNotificationService.initialize();

  runApp(
    const ProviderScope(
      child: CampusHubApp(),
    ),
  );
}
