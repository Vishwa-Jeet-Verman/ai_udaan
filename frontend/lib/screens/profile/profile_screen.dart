import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isUploadingAvatar = false;
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  String? _lastValidatedName;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.displayName;
    }
    _nameFocusNode.addListener(_handleNameFocusChange);
    _nameController.addListener(_handleNameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshProfile();
      if (!mounted) return;
      final refreshedUser = authProvider.user;
      if (refreshedUser != null) {
        _nameController.text = refreshedUser.displayName;
      }
    });
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_handleNameFocusChange);
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String? _getNameValidationMessage(String name) {
    final normalizedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedName.isEmpty) return 'Name is required';
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(normalizedName)) {
      return 'Name can contain only letters and spaces';
    }
    if (normalizedName.replaceAll(' ', '').length < 3) {
      return 'Name must be at least 3 characters long';
    }
    return null;
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  bool _validateName({bool showToast = false}) {
    final errorMessage = _getNameValidationMessage(_nameController.text);
    if (errorMessage != null) {
      if (showToast) _showErrorToast(errorMessage);
      if (mounted) setState(() => _lastValidatedName = null);
      return false;
    }
    if (mounted) setState(() => _lastValidatedName = _nameController.text);
    return true;
  }

  void _handleNameFocusChange() {
    if (!_nameFocusNode.hasFocus) {
      _validateName(showToast: true);
    }
  }

  void _handleNameChanged() {
    final currentName = _nameController.text;
    if (_lastValidatedName != null && _lastValidatedName != currentName) {
      setState(() => _lastValidatedName = null);
    }
  }

  bool get _hasValidatedName {
    final currentName = _nameController.text;
    return _lastValidatedName != null && _lastValidatedName == currentName;
  }

  Future<void> _saveProfile() async {
    if (!_validateName(showToast: true)) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileUpdated),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? AppLocalizations.of(context)!.failedToUpdateProfile),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAvatarFromDevice() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        return;
      }

      if (!mounted) return;
      setState(() => _isUploadingAvatar = true);

      // readAsBytes works on both web and native (avoids dart:io on web)
      // Capture the provider before async gaps to avoid using BuildContext
      // across an `await` (prevents use_build_context_synchronously lint).
      final authProvider = context.read<AuthProvider>();
      final imageBytes = await pickedFile.readAsBytes();

      final success = await authProvider.uploadAvatar(
        imagePath: pickedFile.path,
        imageBytes: imageBytes,
      );

      if (!mounted) return;

      setState(() => _isUploadingAvatar = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileImageUpdated),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? AppLocalizations.of(context)!.failedToUploadImage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotPickImage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 20,
      tablet: 28,
      desktop: 36,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 760,
      desktop: 920,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return Center(child: Text(AppLocalizations.of(context)!.notLoggedIn));
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  24,
                ),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Initials are always shown underneath; image overlays
                        // with transparent background so initials show through on
                        // network failure (e.g. Moodle avatar CORS/load errors).
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                user.initials,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            if (user.avatarUrl != null &&
                                user.avatarUrl!.isNotEmpty)
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(user.avatarUrl!),
                                backgroundColor: Colors.transparent,
                                onBackgroundImageError: (_, _) {},
                              ),
                          ],
                        ),
                        if (_isUploadingAvatar)
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                height: 28,
                                width: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: Theme.of(context).colorScheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isUploadingAvatar
                                  ? null
                                  : _pickAvatarFromDevice,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isUploadingAvatar
                          ? null
                          : _pickAvatarFromDevice,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                        _isUploadingAvatar
                            ? AppLocalizations.of(context)!.uploadingImage
                            : AppLocalizations.of(context)!.chooseImageFromDevice,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info / Edit form
                    if (_isEditing) ...[
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.name,
                          prefixIcon: const Icon(Icons.person_outline),
                          suffixIcon: _hasValidatedName
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          helperText: _hasValidatedName ? AppLocalizations.of(context)!.looksGood : null,
                          helperStyle: const TextStyle(color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _nameController.text = user.displayName;
                                setState(() => _isEditing = false);
                              },
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _saveProfile,
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(AppLocalizations.of(context)!.save),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _ProfileInfoTile(
                        icon: Icons.person,
                        label: AppLocalizations.of(context)!.name,
                        value: user.displayName,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.email,
                        label: AppLocalizations.of(context)!.email,
                        value: user.email,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.badge,
                        label: AppLocalizations.of(context)!.role,
                        value: user.role.toUpperCase(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
