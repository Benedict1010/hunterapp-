import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/resume_service.dart';
import '../domain/resume.dart';
import '../domain/resume_version.dart';

enum ResumeStateStatus {
  initial,
  loading,
  loaded,
  uploading,
  updating,
  deleting,
  error,
}

class ResumeController extends ChangeNotifier {
  final ResumeService resumeService;

  ResumeStateStatus _status = ResumeStateStatus.initial;
  List<Resume> _resumes = [];
  Resume? _selectedResume;
  List<ResumeVersion> _versions = [];
  String? _errorMessage;

  ResumeController({required this.resumeService});

  ResumeStateStatus get status => _status;
  List<Resume> get resumes => List.unmodifiable(_resumes);
  Resume? get selectedResume => _selectedResume;
  List<ResumeVersion> get versions => List.unmodifiable(_versions);
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == ResumeStateStatus.loading;
  bool get isUploading => _status == ResumeStateStatus.uploading;
  bool get isUpdating => _status == ResumeStateStatus.updating;
  bool get isDeleting => _status == ResumeStateStatus.deleting;
  bool get hasError => _status == ResumeStateStatus.error;

  Resume? get primaryResume {
    try {
      return _resumes.firstWhere((r) => r.isPrimary);
    } catch (_) {
      return _resumes.isNotEmpty ? _resumes.first : null;
    }
  }

  void selectResume(Resume? resume) {
    _selectedResume = resume;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == ResumeStateStatus.error) {
      _status = ResumeStateStatus.loaded;
    }
    notifyListeners();
  }

  Future<void> loadResumes() async {
    _status = ResumeStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await resumeService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        _resumes = [];
        _status = ResumeStateStatus.loaded;
        notifyListeners();
        return;
      }

      _resumes = await resumeService.listResumes();
      if (_selectedResume != null) {
        final match = _resumes.where((r) => r.id == _selectedResume!.id);
        _selectedResume = match.isNotEmpty ? match.first : primaryResume;
      } else {
        _selectedResume = primaryResume;
      }
      _status = ResumeStateStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = ResumeStateStatus.error;
    } catch (e) {
      _errorMessage = 'Failed to load resumes.';
      _status = ResumeStateStatus.error;
    }

    notifyListeners();
  }

  Future<Resume?> uploadResume({
    required String filePath,
    String? fileName,
    List<int>? bytes,
  }) async {
    _status = ResumeStateStatus.uploading;
    _errorMessage = null;
    notifyListeners();

    try {
      final newResume = await resumeService.uploadResume(
        filePath: filePath,
        fileName: fileName,
        bytes: bytes,
      );
      await loadResumes();
      _selectedResume = newResume;
      _status = ResumeStateStatus.loaded;
      notifyListeners();
      return newResume;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = ResumeStateStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to upload resume.';
      _status = ResumeStateStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<Resume?> updateResume(
    String id, {
    required String filePath,
    String? fileName,
    List<int>? bytes,
  }) async {
    _status = ResumeStateStatus.updating;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await resumeService.updateResume(
        id,
        filePath: filePath,
        fileName: fileName,
        bytes: bytes,
      );
      await loadResumes();
      _selectedResume = updated;
      _status = ResumeStateStatus.loaded;
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = ResumeStateStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to update resume.';
      _status = ResumeStateStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteResume(String id) async {
    _status = ResumeStateStatus.deleting;
    _errorMessage = null;
    notifyListeners();

    try {
      await resumeService.deleteResume(id);
      if (_selectedResume?.id == id) {
        _selectedResume = null;
      }
      await loadResumes();
      _status = ResumeStateStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = ResumeStateStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete resume.';
      _status = ResumeStateStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPrimary(String id) async {
    _status = ResumeStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await resumeService.setPrimary(id);
      await loadResumes();
      _selectedResume = updated;
      _status = ResumeStateStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = ResumeStateStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to set primary resume.';
      _status = ResumeStateStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<Resume?> extractResume(String id) async {
    _status = ResumeStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await resumeService.extractResume(id);
      await loadResumes();
      _selectedResume = updated;
      _status = ResumeStateStatus.loaded;
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = ResumeStateStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to extract resume text.';
      _status = ResumeStateStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<List<ResumeVersion>> loadVersions(String id) async {
    _status = ResumeStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _versions = await resumeService.listVersions(id);
      _status = ResumeStateStatus.loaded;
      notifyListeners();
      return _versions;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = ResumeStateStatus.error;
      notifyListeners();
      return [];
    } catch (e) {
      _errorMessage = 'Failed to load resume versions.';
      _status = ResumeStateStatus.error;
      notifyListeners();
      return [];
    }
  }

  Future<List<int>?> downloadResume(String id) async {
    try {
      return await resumeService.downloadResume(id);
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to download resume.';
      notifyListeners();
      return null;
    }
  }
}
