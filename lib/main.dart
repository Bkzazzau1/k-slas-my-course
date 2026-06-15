import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'app/app.dart';
import 'data/services/distance_learning_migration_service.dart';
import 'features/identity_trust/services/identity_trust_demo_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await DistanceLearningMigrationService.run();
  IdentityTrustDemoBootstrap.register();
  runApp(const StudentAIApp());
}
