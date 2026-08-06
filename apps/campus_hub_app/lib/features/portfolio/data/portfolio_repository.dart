import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/portfolio_models.dart';

class PortfolioRepository {
  final Dio _dio;

  PortfolioRepository(this._dio);

  Future<PortfolioModel> getUserPortfolio() async {
    final response = await _dio.get('/api/v1/portfolio/me');
    return PortfolioModel.fromJson(response.data['data']);
  }

  Future<PortfolioModel> getPublicPortfolio(String identifier) async {
    final response = await _dio.get('/api/v1/portfolio/public/$identifier');
    return PortfolioModel.fromJson(response.data['data']);
  }

  Future<PortfolioModel> updatePortfolio({
    String? bio,
    String? githubUrl,
    String? linkedinUrl,
    String? websiteUrl,
    String? resumeUrl,
    double? cgpa,
    String? customUsername,
    bool? isPublic,
  }) async {
    final response = await _dio.patch(
      '/api/v1/portfolio/me',
      data: {
        'bio': bio,
        'github_url': githubUrl,
        'linkedin_url': linkedinUrl,
        'website_url': websiteUrl,
        'resume_url': resumeUrl,
        'cgpa': cgpa,
        'custom_username': customUsername,
        'is_public': isPublic,
      },
    );
    return PortfolioModel.fromJson(response.data['data']);
  }

  Future<void> addProject({
    required String title,
    String? description,
    List<String>? techStack,
    String? projectUrl,
    String? repoUrl,
    String? imageUrl,
  }) async {
    await _dio.post(
      '/api/v1/portfolio/projects',
      data: {
        'title': title,
        'description': description,
        'tech_stack': techStack,
        'project_url': projectUrl,
        'repo_url': repoUrl,
        'image_url': imageUrl,
      },
    );
  }

  Future<void> deleteProject(String projectId) async {
    await _dio.delete('/api/v1/portfolio/projects/$projectId');
  }

  Future<void> addSkill({
    required String skillName,
    String? category,
    String? proficiency,
  }) async {
    await _dio.post(
      '/api/v1/portfolio/skills',
      data: {
        'skill_name': skillName,
        'category': category,
        'proficiency': proficiency,
      },
    );
  }

  Future<void> deleteSkill(String skillId) async {
    await _dio.delete('/api/v1/portfolio/skills/$skillId');
  }

  Future<void> addCertificate({
    required String title,
    required String issuer,
    String? issueDate,
    String? credentialUrl,
    String? credentialId,
  }) async {
    await _dio.post(
      '/api/v1/portfolio/certificates',
      data: {
        'title': title,
        'issuer': issuer,
        'issue_date': issueDate,
        'credential_url': credentialUrl,
        'credential_id': credentialId,
      },
    );
  }

  Future<void> deleteCertificate(String certId) async {
    await _dio.delete('/api/v1/portfolio/certificates/$certId');
  }

  Future<void> addAchievement({
    required String title,
    String? category,
    String? description,
    String? dateAchieved,
    String? proofUrl,
  }) async {
    await _dio.post(
      '/api/v1/portfolio/achievements',
      data: {
        'title': title,
        'category': category,
        'description': description,
        'date_achieved': dateAchieved,
        'proof_url': proofUrl,
      },
    );
  }

  Future<void> deleteAchievement(String achievementId) async {
    await _dio.delete('/api/v1/portfolio/achievements/$achievementId');
  }
}

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PortfolioRepository(dio);
});
