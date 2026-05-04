import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../screens/profile/profile_screen.dart';

/// Moodle-style circular avatar showing user initials.
/// Taps open the profile screen (or login if not signed in).
class UserAvatar extends StatelessWidget {
  final double radius;
  final double fontSize;
  final bool interactive;

  const UserAvatar({
    super.key,
    this.radius = 18,
    this.fontSize = 14,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final initials = user?.initials ?? '?';

        // Initials always sit in the back; image is overlaid with a
        // transparent background so initials show through on error.
        Widget avatar = Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[300],
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
              CircleAvatar(
                radius: radius,
                backgroundImage: NetworkImage(user.avatarUrl!),
                backgroundColor: Colors.transparent,
                onBackgroundImageError: (_, _) {},
              ),
          ],
        );

        if (!interactive) {
          return avatar;
        }

        return GestureDetector(
          onTap: () {
            if (auth.isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            } else {
              Navigator.pushNamed(context, '/login');
            }
          },
          child: avatar,
        );
      },
    );
  }
}
