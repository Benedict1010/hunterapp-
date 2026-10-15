import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/job_preference_service.dart';
import '../domain/job_preference.dart';

enum JobPreferenceStateStatus { initial, loading, loaded, saving, error }

class JobPreferenceController extends ChangeNotifier {
  final JobPreferenceService preferenceService;

  JobPreferenceStateStatus _status = JobPreferenceStateStatus.initial;
  JobPreference _preference;
  String? _errorMessage;

  static const defaultPreference = JobPreference(
    preferredRoles: ['Product Designer', 'Frontend Engineer'],
    jobType: 'Full-time',
    workMode: 'Remote',
    minSalary: 25000,
    preferredLocations: ['Bangalore, KA', 'Mumbai, MH', 'Remote'],
    minMatchThreshold: 85,
  );

  JobPreferenceController({
    required this.preferenceService,
    JobPreference? initialPreference,
    JobPreferenceStateStatus initialStatus = JobPreferenceStateStatus.initial,
  }) : _preference = initialPreference ?? defaultPreference,
       _status = initialStatus;

  JobPreferenceStateStatus get status => _status;
  JobPreference get preference => _preference;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == JobPreferenceStateStatus.loading;
  bool get isSaving => _status == JobPreferenceStateStatus.saving;
  bool get hasError => _status == JobPreferenceStateStatus.error;

  void clearError() {
    _errorMessage = null;
    if (_status == JobPreferenceStateStatus.error) {
      _status = JobPreferenceStateStatus.loaded;
    }
    notifyListeners();
  }

  void updateLocalPreference(JobPreference updated) {
    _preference = updated;
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    _status = JobPreferenceStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await preferenceService.apiClient.tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        final loaded = await preferenceService.getPreferences();
        if (loaded != null) {
          _preference = loaded;
        } else {
          _preference = defaultPreference;
        }
      } else {
        _preference = defaultPreference;
      }
      _status = JobPreferenceStateStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = JobPreferenceStateStatus.error;
    } catch (_) {
      _errorMessage = 'Failed to load preferences.';
      _status = JobPreferenceStateStatus.error;
    }

    notifyListeners();
  }

  Future<bool> savePreferences() async {
    _status = JobPreferenceStateStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await preferenceService.apiClient.tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Please sign in to save job search preferences.';
        _status = JobPreferenceStateStatus.error;
        notifyListeners();
        return false;
      }

      final saved = await preferenceService.updatePreferences(_preference);
      _preference = saved;
      _status = JobPreferenceStateStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _status = JobPreferenceStateStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to save job search preferences.';
      _status = JobPreferenceStateStatus.error;
      notifyListeners();
      return false;
    }
  }
}
