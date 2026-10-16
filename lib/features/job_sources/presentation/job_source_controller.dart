import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/job_source_service.dart';
import '../domain/job_source.dart';

enum JobSourceStateStatus { initial, loading, loaded, saving, error }

class JobSourceController extends ChangeNotifier {
  final JobSourceService jobSourceService;

  JobSourceStateStatus _status = JobSourceStateStatus.initial;
  List<JobSourceItem> _sources = const [];
  Set<String> _selectedIds = {};
  String? _errorMessage;

  JobSourceController({
    required this.jobSourceService,
    List<JobSourceItem>? initialSources,
    Set<String>? initialSelectedIds,
    JobSourceStateStatus initialStatus = JobSourceStateStatus.initial,
  }) : _sources = initialSources ?? const [],
       _selectedIds = initialSelectedIds ?? {},
       _status = initialStatus;

  JobSourceStateStatus get status => _status;
  List<JobSourceItem> get sources => List.unmodifiable(_sources);
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == JobSourceStateStatus.loading;
  bool get isSaving => _status == JobSourceStateStatus.saving;
  bool get hasError => _status == JobSourceStateStatus.error;

  void clearError() {
    _errorMessage = null;
    if (_status == JobSourceStateStatus.error) {
      _status = JobSourceStateStatus.loaded;
    }
    notifyListeners();
  }

  void toggleSource(String sourceId) {
    final next = Set<String>.from(_selectedIds);
    if (next.contains(sourceId)) {
      next.remove(sourceId);
    } else {
      next.add(sourceId);
    }
    _selectedIds = next;
    notifyListeners();
  }

  void toggleSourceByName(String sourceName) {
    final match = _sources.where((s) => s.name == sourceName);
    if (match.isNotEmpty) {
      toggleSource(match.first.id);
    }
  }

  bool isSelected(String sourceId) => _selectedIds.contains(sourceId);

  bool isSelectedByName(String sourceName) {
    final match = _sources.where((s) => s.name == sourceName);
    if (match.isNotEmpty) {
      return _selectedIds.contains(match.first.id);
    }
    return false;
  }

  Future<void> loadSources() async {
    _status = JobSourceStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final available = await jobSourceService.fetchAvailableSources();
      _sources = available;

      final token = await jobSourceService.apiClient.tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        final selected = await jobSourceService.fetchSelectedSourceIds();
        _selectedIds = selected.toSet();
      } else {
        _selectedIds = {};
      }
      _status = JobSourceStateStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = JobSourceStateStatus.error;
    } catch (_) {
      _errorMessage = 'Failed to load job sources.';
      _status = JobSourceStateStatus.error;
    }

    notifyListeners();
  }

  Future<bool> saveSelections() async {
    _status = JobSourceStateStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await jobSourceService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Please sign in to save job source preferences.';
        _status = JobSourceStateStatus.error;
        notifyListeners();
        return false;
      }

      final saved = await jobSourceService.updateSelectedSourceIds(
        _selectedIds.toList(),
      );
      _selectedIds = saved.toSet();
      _status = JobSourceStateStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = JobSourceStateStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to save job sources.';
      _status = JobSourceStateStatus.error;
      notifyListeners();
      return false;
    }
  }
}
