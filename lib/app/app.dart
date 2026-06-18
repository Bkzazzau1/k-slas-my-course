import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/routes/app_pages.dart';
import '../app/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../data/services/storage_service.dart';

class StudentAIApp extends StatelessWidget {
  const StudentAIApp({super.key});

  static const _demoExamFaceOnly = bool.fromEnvironment(
    'KSLAS_DEMO_EXAM_FACE_ONLY',
  );

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: _demoExamFaceOnly ? 'K-SLAS Exam Demo' : 'K-SLAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: StorageService.getDarkMode()
          ? ThemeMode.dark
          : ThemeMode.light,
      getPages: AppPages.pages,
      initialRoute: _demoExamFaceOnly
          ? Routes.demoExamFaceOnly
          : Routes.mainNav,
    );
  }
}
