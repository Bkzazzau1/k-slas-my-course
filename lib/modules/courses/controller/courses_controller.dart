import 'package:get/get.dart';

import '../../../data/models/course_model.dart';
import '../../../data/services/course_catalog_service.dart';

class CoursesController extends GetxController {
  CoursesController({CourseCatalogGateway? gateway})
    : _gateway = gateway ?? RemoteCourseCatalogGateway();

  final CourseCatalogGateway _gateway;

  final courses = <CourseModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  String get providerLabel => _gateway.providerLabel;

  @override
  void onInit() {
    super.onInit();
    loadCourses();
  }

  Future<void> loadCourses() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final items = await _gateway.fetchCourses();
      courses.assignAll(items);
    } catch (error) {
      errorMessage.value = error.toString();
      courses.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
