import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/application_service.dart';
import '../data/mock_applications.dart';
import '../domain/job_application.dart';

enum ApplicationStateStatus { initial, loading, loaded, error }

enum ApplicationDetailStatus { initial, loading, loaded, error }

class ApplicationController extends ChangeNotifier {
  final ApplicationService applicationService;

  ApplicationStateStatus _status;
  ApplicationDetailStatus _detailStatus;

  List<Application> _applications;
  Application? _selectedApplication;
  List<ApplicationTimelineEvent> _timelineEvents = [];

  String? _errorMessage;
  String? _detailErrorMessage;

  ApplicationController({
    required this.applicationService,
    List<Application>? initialApplications,
    ApplicationStateStatus initialStatus = ApplicationStateStatus.loaded,
  }) : _applications = initialApplications ?? List.of(mockApplicationList),
       _status = initialStatus,
       _detailStatus = ApplicationDetailStatus.loaded,
       _selectedApplication =
           (initialApplications ?? mockApplicationList).isNotEmpty
           ? (initialApplications ?? mockApplicationList).first
           : null;

  ApplicationStateStatus get status => _status;
  ApplicationDetailStatus get detailStatus => _detailStatus;

  List<Application> get applications => List.unmodifiable(_applications);
  Application? get selectedApplication => _selectedApplication;
  List<ApplicationTimelineEvent> get timelineEvents =>
      List.unmodifiable(_timelineEvents);

  String? get errorMessage => _errorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  bool get isLoading => _status == ApplicationStateStatus.loading;
  bool get isLoadingDetail => _detailStatus == ApplicationDetailStatus.loading;
  bool get hasError => _status == ApplicationStateStatus.error;

  void selectApplication(Application? app) {
    _selectedApplication = app;
    _timelineEvents = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _detailErrorMessage = null;
    if (_status == ApplicationStateStatus.error) {
      _status = ApplicationStateStatus.loaded;
    }
    notifyListeners();
  }

  Future<void> loadApplications({ApplicationStatus? statusFilter}) async {
    _status = ApplicationStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await applicationService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        _status = ApplicationStateStatus.loaded;
        notifyListeners();
        return;
      }

      final list = await applicationService.listApplications(
        status: statusFilter,
      );
      _applications = list;
      _status = ApplicationStateStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = ApplicationStateStatus.error;
    } catch (e) {
      _errorMessage = 'Failed to load applications.';
      _status = ApplicationStateStatus.error;
    }

    notifyListeners();
  }

  Future<Application?> loadApplicationDetail(String applicationId) async {
    _detailStatus = ApplicationDetailStatus.loading;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final token = await applicationService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        final matches = _applications.where((a) => a.id == applicationId);
        _selectedApplication = matches.isNotEmpty
            ? matches.first
            : mockApplicationList.first;
        _timelineEvents = List.of(mockTimelineList);
        _detailStatus = ApplicationDetailStatus.loaded;
        notifyListeners();
        return _selectedApplication;
      }

      final app = await applicationService.getApplication(applicationId);
      _selectedApplication = app;

      try {
        _timelineEvents = await applicationService.listTimeline(applicationId);
      } catch (_) {
        _timelineEvents = [];
      }

      _detailStatus = ApplicationDetailStatus.loaded;
      notifyListeners();
      return app;
    } on ApiException catch (e) {
      _detailErrorMessage = e.userFriendlyMessage;
      _detailStatus = ApplicationDetailStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _detailErrorMessage = 'Failed to load application detail.';
      _detailStatus = ApplicationDetailStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<Application?> createApplication({
    required String jobId,
    required String resumeVersionId,
    String? applicationUrl,
    String? source,
    ApplicationStatus status = ApplicationStatus.applied,
    DateTime? appliedAt,
  }) async {
    _status = ApplicationStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final newApp = await applicationService.createApplication(
        jobId: jobId,
        resumeVersionId: resumeVersionId,
        applicationUrl: applicationUrl,
        source: source,
        status: status,
        appliedAt: appliedAt,
      );

      _applications.insert(0, newApp);
      _selectedApplication = newApp;
      _status = ApplicationStateStatus.loaded;
      notifyListeners();
      return newApp;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = ApplicationStateStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to track application.';
      _status = ApplicationStateStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<Application?> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status, {
    String? applicationUrl,
    String? source,
    DateTime? appliedAt,
  }) async {
    _detailStatus = ApplicationDetailStatus.loading;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final token = await applicationService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        if (_selectedApplication?.id == applicationId) {
          _selectedApplication = Application(
            id: _selectedApplication!.id,
            userId: _selectedApplication!.userId,
            jobId: _selectedApplication!.jobId,
            resumeVersionId: _selectedApplication!.resumeVersionId,
            status: status,
            applicationUrl:
                applicationUrl ?? _selectedApplication!.applicationUrl,
            source: source ?? _selectedApplication!.source,
            appliedAt: appliedAt ?? _selectedApplication!.appliedAt,
            createdAt: _selectedApplication!.createdAt,
            updatedAt: DateTime.now(),
            job: _selectedApplication!.job,
            matchScore: _selectedApplication!.matchScore,
          );
        }
        _detailStatus = ApplicationDetailStatus.loaded;
        notifyListeners();
        return _selectedApplication;
      }

      final updated = await applicationService.updateApplicationStatus(
        applicationId,
        status,
        applicationUrl: applicationUrl,
        source: source,
        appliedAt: appliedAt,
      );

      _selectedApplication = updated;
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        _applications[index] = updated;
      }

      try {
        _timelineEvents = await applicationService.listTimeline(applicationId);
      } catch (_) {}

      _detailStatus = ApplicationDetailStatus.loaded;
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      _detailErrorMessage = e.userFriendlyMessage;
      _detailStatus = ApplicationDetailStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _detailErrorMessage = 'Failed to update application status.';
      _detailStatus = ApplicationDetailStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addTimelineNote(
    String applicationId,
    ApplicationStatus status, {
    required String note,
  }) async {
    _detailStatus = ApplicationDetailStatus.loading;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      await applicationService.addTimelineEvent(
        applicationId,
        status,
        note: note,
      );

      await loadApplicationDetail(applicationId);
      return true;
    } on ApiException catch (e) {
      _detailErrorMessage = e.userFriendlyMessage;
      _detailStatus = ApplicationDetailStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _detailErrorMessage = 'Failed to add timeline event.';
      _detailStatus = ApplicationDetailStatus.error;
      notifyListeners();
      return false;
    }
  }
}
