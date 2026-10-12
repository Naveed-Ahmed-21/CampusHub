import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_skill/flutter_skill.dart';
import 'core/services/media_storage_service.dart';
import 'core/services/local_notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    FlutterSkillBinding.ensureInitialized(autoEnableIndicators: false);
  }
  await MediaStorageService.ensureInitialized();
  await LocalNotificationService.initialize();

  runApp(
    const ProviderScope(
      child: CampusHubApp(),
    ),
  );
}
