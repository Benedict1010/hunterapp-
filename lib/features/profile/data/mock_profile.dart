import '../domain/user_profile.dart';

const mockProfile = UserProfile(
  name: 'Alex Rivera',
  email: 'alex.rivera@email.com',
  role: 'Developer',
  provider: 'Lumina GPT-4o',
  stats: [
    ProfileStat(label: 'Profile completion', value: '85%'),
    ProfileStat(label: 'Skills added', value: '12'),
  ],
);
