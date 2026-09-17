class ProfileStat {
  const ProfileStat({required this.label, required this.value});
  final String label, value;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.provider,
    required this.stats,
  });
  final String name, email, role, provider;
  final List<ProfileStat> stats;
}
