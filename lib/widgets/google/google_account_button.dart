import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/services/google/google_bootstrap.dart';
import 'package:paperclip2/services/google/identity/google_identity_service.dart';

class GoogleAccountButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool showAvatar;
  final Color? backgroundColor;
  final Color? textColor;
  final bool fullWidth;
  final bool compact;

  const GoogleAccountButton({
    super.key,
    required this.onPressed,
    this.showAvatar = true,
    this.backgroundColor,
    this.textColor,
    this.fullWidth = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Consommer uniquement GoogleIdentityService
    final GoogleIdentityService identity =
        context.watch<GoogleServicesBundle>().identity;

    final String label = _buildLabel(identity);
    final Widget? trailing = showAvatar ? _buildAvatar(identity) : null;

    final bool enabled = onPressed != null;

    final EdgeInsetsGeometry padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

    final button = ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: backgroundColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: enabled ? 3 : 0,
          disabledBackgroundColor: (backgroundColor ?? Colors.grey)
              .withOpacity(0.6),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 6 : 8),
              decoration: BoxDecoration(
                color: (textColor ?? Colors.white).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_circle),
            ),
            SizedBox(width: compact ? 8 : 16),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) Flexible(child: trailing),
          ],
        ),
      );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  String _buildLabel(GoogleIdentityService identity) {
    if (identity.status.name == 'signedIn') {
      final name = (identity.displayName ?? '').trim();
      if (name.isNotEmpty) {
        return 'Connecté · $name';
      }
      return 'Connecté à Google Play Games';
    }
    return 'Se connecter à Google Play Games';
  }

  Widget? _buildAvatar(GoogleIdentityService identity) {
    final url = identity.avatarUrl ?? '';
    if (url.isEmpty || !(url.startsWith('http://') || url.startsWith('https://'))) {
      return null;
    }
    return CircleAvatar(
      radius: 14,
      backgroundImage: NetworkImage(url),
      backgroundColor: Colors.transparent,
    );
  }
}
