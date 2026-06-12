import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/result_model.dart';
import 'course_catalog_service.dart';
import 'live_session_runtime_mode_service.dart';

abstract class ResultGateway {
  Future<List<ResultModel>> fetchResults();
  Future<ResultModel> saveMark(ResultModel result);
  Future<ResultModel> approve(ResultModel result);
  Future<ResultModel> publish(ResultModel result);
  String get providerLabel;
}

class ResultService {
  ResultService._();

  static final ResultGateway gateway = RemoteResultGateway(
    fallbackGateway: LocalResultGateway.instance,
  );

  static Future<List<ResultModel>> fetchResults() => gateway.fetchResults();
  static Future<ResultModel> saveMark(ResultModel result) =>
      gateway.saveMark(result);
  static Future<ResultModel> approve(ResultModel result) =>
      gateway.approve(result);
  static Future<ResultModel> publish(ResultModel result) =>
      gateway.publish(result);
}

class LocalResultGateway implements ResultGateway {
  LocalResultGateway._();

  static final LocalResultGateway instance = LocalResultGateway._();

  @override
  String get providerLabel => 'Demo gradebook';

  @override
  Future<List<ResultModel>> fetchResults() async {
    final now = DateTime.now();
    return [
      ResultModel(
        id: 'res-csc305-exam-zainab',
        courseCode: 'CSC 305',
        courseTitle: 'Data Structures',
        studentId: 1001,
        studentName: 'Zainab Ibrahim',
        assessmentType: 'exam',
        title: 'Main Examination',
        score: 78,
        maxScore: 100,
        gradedAssessmentScore: 18,
        assignmentScore: 12,
        groupAssignmentScore: 8,
        peerReviewScore: 5,
        examinationScore: 35,
        totalScore: 78,
        grade: 'A',
        remark: 'Passed',
        status: ResultWorkflowStatus.published,
        publishedAt: now.subtract(const Duration(days: 1)),
      ),
      const ResultModel(
        id: 'res-csc305-assignment-sani',
        courseCode: 'CSC 305',
        courseTitle: 'Data Structures',
        studentId: 1004,
        studentName: 'Sani Abdullahi',
        assessmentType: 'assignment',
        title: 'Graph Algorithms Coursework',
        score: 66,
        maxScore: 100,
        gradedAssessmentScore: 15,
        assignmentScore: 14,
        groupAssignmentScore: 7,
        peerReviewScore: 4,
        examinationScore: 26,
        totalScore: 66,
        grade: 'B',
        remark: 'Passed',
        status: ResultWorkflowStatus.submitted,
      ),
      const ResultModel(
        id: 'res-mth202-exam-isa',
        courseCode: 'MTH 202',
        courseTitle: 'Linear Algebra',
        studentId: 1212,
        studentName: 'Isa Muhammad',
        assessmentType: 'exam',
        title: 'Semester Examination',
        score: 71,
        maxScore: 100,
        gradedAssessmentScore: 16,
        assignmentScore: 10,
        groupAssignmentScore: 0,
        peerReviewScore: 5,
        examinationScore: 40,
        totalScore: 71,
        grade: 'A',
        remark: 'Passed',
        status: ResultWorkflowStatus.approved,
      ),
      const ResultModel(
        id: 'res-gst201-cbt-zainab',
        courseCode: 'GST 201',
        courseTitle: 'Use of English',
        studentId: 1001,
        studentName: 'Zainab Ibrahim',
        assessmentType: 'quiz',
        title: 'CBT Continuous Assessment',
        score: 18,
        maxScore: 20,
        gradedAssessmentScore: 18,
        assignmentScore: 0,
        groupAssignmentScore: 0,
        peerReviewScore: 0,
        examinationScore: 0,
        totalScore: 18,
        grade: 'A',
        remark: 'Passed',
        status: ResultWorkflowStatus.published,
      ),
    ];
  }

  @override
  Future<ResultModel> saveMark(ResultModel result) async => result.copyWith(
    status: result.status == ResultWorkflowStatus.published
        ? ResultWorkflowStatus.published
        : ResultWorkflowStatus.submitted,
  );

  @override
  Future<ResultModel> approve(ResultModel result) async =>
      result.copyWith(status: ResultWorkflowStatus.approved);

  @override
  Future<ResultModel> publish(ResultModel result) async => result.copyWith(
    status: ResultWorkflowStatus.published,
    publishedAt: DateTime.now(),
  );
}

class RemoteResultGateway implements ResultGateway {
  RemoteResultGateway({
    http.Client? client,
    CourseCatalogBackendConfig? config,
    required ResultGateway fallbackGateway,
  }) : _client = client ?? http.Client(),
       _config = config ?? CourseCatalogBackendConfig.fromRuntime(),
       _fallbackGateway = fallbackGateway;

  final http.Client _client;
  final CourseCatalogBackendConfig _config;
  final ResultGateway _fallbackGateway;

  bool get isConfigured =>
      LiveSessionRuntimeModeStore.load() == LiveSessionRuntimeMode.production &&
      _config.isConfigured;

  @override
  String get providerLabel =>
      isConfigured ? 'Go results API' : _fallbackGateway.providerLabel;

  @override
  Future<List<ResultModel>> fetchResults() async {
    if (!isConfigured) return _fallbackGateway.fetchResults();
    try {
      final response = await _client.get(
        _uri(['api', 'results']),
        headers: _headers,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackGateway.fetchResults();
      }
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic>
          ? decoded['items']
          : decoded;
      if (items is! List) return _fallbackGateway.fetchResults();
      return items
          .whereType<Map>()
          .map((item) => ResultModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return _fallbackGateway.fetchResults();
    }
  }

  @override
  Future<ResultModel> saveMark(ResultModel result) async {
    if (!isConfigured) return _fallbackGateway.saveMark(result);
    try {
      final isUpdate = result.isRemoteId;
      final response = isUpdate
          ? await _client.put(
              _uri(['api', 'results', result.id]),
              headers: _jsonHeaders,
              body: jsonEncode(result.toUpdateJson()),
            )
          : await _client.post(
              _uri(['api', 'results']),
              headers: _jsonHeaders,
              body: jsonEncode(result.toCreateJson()),
            );
      return _decodeOrFallback(
        response,
        () => _fallbackGateway.saveMark(result),
      );
    } catch (_) {
      return _fallbackGateway.saveMark(result);
    }
  }

  @override
  Future<ResultModel> approve(ResultModel result) async {
    if (!isConfigured || !result.isRemoteId) {
      return _fallbackGateway.approve(result);
    }
    try {
      final response = await _client.post(
        _uri(['api', 'results', result.id, 'approve']),
        headers: _headers,
      );
      return _decodeOrFallback(
        response,
        () => _fallbackGateway.approve(result),
      );
    } catch (_) {
      return _fallbackGateway.approve(result);
    }
  }

  @override
  Future<ResultModel> publish(ResultModel result) async {
    if (!isConfigured || !result.isRemoteId) {
      return _fallbackGateway.publish(result);
    }
    try {
      final response = await _client.post(
        _uri(['api', 'results', result.id, 'publish']),
        headers: _headers,
      );
      return _decodeOrFallback(
        response,
        () => _fallbackGateway.publish(result),
      );
    } catch (_) {
      return _fallbackGateway.publish(result);
    }
  }

  Future<ResultModel> _decodeOrFallback(
    http.Response response,
    Future<ResultModel> Function() fallback,
  ) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return fallback();
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return fallback();
    return ResultModel.fromJson(decoded);
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_config.accessToken}',
  };

  Map<String, String> get _jsonHeaders => {
    ..._headers,
    'Content-Type': 'application/json',
  };

  Uri _uri(List<String> segments) {
    final base = Uri.parse(_config.apiBaseUrl);
    final baseSegments = base.pathSegments.where((s) => s.isNotEmpty);
    return base.replace(pathSegments: [...baseSegments, ...segments]);
  }
}
