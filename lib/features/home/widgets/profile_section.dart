// lib/features/home/widgets/profile_section.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/utils/image_utils.dart';

/// Displays the user's and partner's profile pictures side by side inside
/// a glassmorphic container, with their names below. Tapping on a picture
/// allows changing it via the image picker.
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.yourName,
    required this.partnerName,
    required this.yourProfilePath,
    required this.partnerProfilePath,
    required this.onYourPicTap,
    required this.onPartnerPicTap,
  });

  final String yourName;
  final String partnerName;
  final String yourProfilePath;
  final String partnerProfilePath;
  final VoidCallback onYourPicTap;
  final VoidCallback onPartnerPicTap;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ProfileAvatar(
            name: yourName.isEmpty ? 'You' : yourName,
            imagePath: yourProfilePath,
            onTap: onYourPicTap,
          ),
          // Heart icon between avatars
          Icon(
            Icons.favorite,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
          _ProfileAvatar(
            name: partnerName.isEmpty ? 'Partner' : partnerName,
            imagePath: partnerProfilePath,
            onTap: onPartnerPicTap,
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.imagePath,
    required this.onTap,
  });

  final String name;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = AppConstants.profilePictureSize;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.6),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: imagePath.isNotEmpty && File(imagePath).existsSync()
                  ? Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultPlaceholder(theme),
                    )
                  : _defaultPlaceholder(theme),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size,
            child: Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Icon(
        Icons.person,
        size: 48,
        color: theme.colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }
}