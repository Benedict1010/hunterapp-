class AppSettings {
  const AppSettings({
    required this.smartTailoring,
    required this.realTimeSuggestions,
    required this.smartAlerts,
    required this.remoteOnly,
    required this.publicProfile,
    required this.shareUsageData,
  });
  final bool smartTailoring,
      realTimeSuggestions,
      smartAlerts,
      remoteOnly,
      publicProfile,
      shareUsageData;
}
