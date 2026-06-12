import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course_material_model.dart';
import 'course_catalog_service.dart';
import 'live_session_runtime_mode_service.dart';

abstract class CourseMaterialGateway {
  Future<List<CourseMaterialModel>> fetchMaterials({
    required String courseCode,
  });
}

class CourseMaterialService {
  CourseMaterialService._();

  static final CourseMaterialGateway gateway = RemoteCourseMaterialGateway(
    fallback: LocalCourseMaterialGateway.instance,
  );
}

class LocalCourseMaterialGateway implements CourseMaterialGateway {
  LocalCourseMaterialGateway._();

  static final LocalCourseMaterialGateway instance =
      LocalCourseMaterialGateway._();

  @override
  Future<List<CourseMaterialModel>> fetchMaterials({
    required String courseCode,
  }) async {
    final code = courseCode.trim().toUpperCase();
    return _seeded
        .where((item) => item.courseCode.trim().toUpperCase() == code)
        .toList();
  }

  static const _seeded = [
    CourseMaterialModel(
      id: 'mat-csc305-graph-notes',
      courseCode: 'CSC 305',
      title: 'Graph Traversal Lecture Notes',
      description: 'BFS, DFS, adjacency lists, and traversal complexity.',
      materialType: 'document',
    ),
    CourseMaterialModel(
      id: 'mat-csc305-lab-sheet',
      courseCode: 'CSC 305',
      title: 'Week 6 Lab Sheet',
      description: 'Practice tasks for graph representation and traversal.',
      materialType: 'document',
    ),
    CourseMaterialModel(
      id: 'mat-mth202-eigen-notes',
      courseCode: 'MTH 202',
      title: 'Eigenvalues Lecturer Notes',
      description: 'Characteristic equation, eigenvectors, and worked steps.',
      materialType: 'document',
    ),
    CourseMaterialModel(
      id: 'mat-mth202-tutorial-link',
      courseCode: 'MTH 202',
      title: 'Matrix Drill Reference Link',
      description: 'Lecturer-approved reference for extra worked examples.',
      materialType: 'link',
      externalUrl: 'https://example.edu/mth202/matrix-drill',
    ),
    CourseMaterialModel(
      id: 'mat-gst201-writing-guide',
      courseCode: 'GST 201',
      title: 'Academic Writing Guide',
      description: 'Essay structure, citation language, and common errors.',
      materialType: 'document',
    ),
  ];
}

class RemoteCourseMaterialGateway implements CourseMaterialGateway {
  RemoteCourseMaterialGateway({
    http.Client? client,
    CourseCatalogBackendConfig? config,
    required CourseMaterialGateway fallback,
  }) : _client = client ?? http.Client(),
       _config = config ?? CourseCatalogBackendConfig.fromRuntime(),
       _fallback = fallback;

  final http.Client _client;
  final CourseCatalogBackendConfig _config;
  final CourseMaterialGateway _fallback;

  bool get isConfigured =>
      LiveSessionRuntimeModeStore.load() == LiveSessionRuntimeMode.production &&
      _config.isConfigured;

  @override
  Future<List<CourseMaterialModel>> fetchMaterials({
    required String courseCode,
  }) async {
    if (!isConfigured) return _fallback.fetchMaterials(courseCode: courseCode);
    try {
      final uri = _uri(
        ['api', 'materials'],
        queryParameters: {'course_code': courseCode},
      );
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback.fetchMaterials(courseCode: courseCode);
      }
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic>
          ? decoded['items']
          : decoded;
      if (items is! List) {
        return _fallback.fetchMaterials(courseCode: courseCode);
      }
      return items
          .whereType<Map>()
          .map(
            (item) =>
                CourseMaterialModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return _fallback.fetchMaterials(courseCode: courseCode);
    }
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_config.accessToken}',
  };

  Uri _uri(List<String> segments, {Map<String, String>? queryParameters}) {
    final base = Uri.parse(_config.apiBaseUrl);
    final baseSegments = base.pathSegments.where((s) => s.isNotEmpty);
    return base.replace(
      pathSegments: [...baseSegments, ...segments],
      queryParameters: queryParameters,
    );
  }
}
