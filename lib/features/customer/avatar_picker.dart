import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/ds_kit.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';
import '../../services/supabase_service.dart';

/// The one flow for changing a customer's profile photo: choose a source, pick,
/// upload, refresh the signed-in user so the new photo shows everywhere.
///
/// [onBusy] reports the upload running; [onPreview] receives the picked bytes
/// straight away (or null again if the upload fails).
Future<void> changeProfilePhoto(
  BuildContext context,
  WidgetRef ref, {
  required ValueChanged<bool> onBusy,
  ValueChanged<Uint8List?>? onPreview,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.hairline, borderRadius: AppRadius.rPill),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            const Text(
              'Update profile photo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.charcoal, letterSpacing: -0.4),
            ),
            const SizedBox(height: AppSpace.xs),
            const Text(
              'Choose how you\'d like to add your photo',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedGrey),
            ),
            const SizedBox(height: AppSpace.xl),
            DsMenuGroup(
              margin: EdgeInsets.zero,
              children: [
                DsMenuTile(
                  icon: Icons.photo_camera_rounded,
                  label: 'Take a photo',
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                DsMenuTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Choose from gallery',
                  tone: DsTone.info,
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
  );
  if (picked == null) return;
  final bytes = await picked.readAsBytes();

  onPreview?.call(bytes);
  onBusy(true);
  try {
    final url = await SupabaseService().uploadAvatar(fileBytes: bytes, fileName: '${const Uuid().v4()}.jpg');
    await SupabaseService().updateProfile(avatarUrl: url);
    await ref.read(appStateProvider.notifier).refreshCurrentUser();
    if (context.mounted) AppToast.success(context, 'Profile photo updated');
  } catch (e) {
    debugPrint('Avatar upload failed: $e');
    onPreview?.call(null);
    if (context.mounted) {
      AppToast.error(context, 'We couldn\'t upload your photo. Please try again in a moment.');
    }
  } finally {
    onBusy(false);
  }
}
