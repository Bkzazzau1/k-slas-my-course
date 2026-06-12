class CourseMaterialModel {
  const CourseMaterialModel({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.materialType,
    this.externalUrl,
    this.allowDownload = true,
  });

  final String id;
  final String courseCode;
  final String title;
  final String description;
  final String materialType;
  final String? externalUrl;
  final bool allowDownload;

  factory CourseMaterialModel.fromJson(Map<String, dynamic> json) {
    return CourseMaterialModel(
      id: json['id']?.toString() ?? json['uuid']?.toString() ?? '',
      courseCode: json['course_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      materialType: json['material_type']?.toString() ?? 'document',
      externalUrl: json['external_url']?.toString(),
      allowDownload: json['allow_download'] != false,
    );
  }
}
