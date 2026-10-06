// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

/// Clears redirect query parameters (such as `code`) from the web browser URL
/// after successful OAuth logins, avoiding stale PKCE exchanges on page reloads.
void clearUrlParams() {
  try {
    final href = html.window.location.href;
    final uri = Uri.parse(href);
    if (uri.queryParameters.isNotEmpty) {
      final cleanUri = uri.replace(queryParameters: {});
      html.window.history.replaceState(null, '', cleanUri.toString());
    }
  } catch (_) {
    // Safely swallow any environment-related exceptions on web platforms
  }
}

/// Checks if there is an active Supabase session stored in browser localStorage.
bool hasSessionInLocalStorage() {
  try {
    final localStorage = html.window.localStorage;
    for (final key in localStorage.keys) {
      if (key.startsWith('sb-') && key.endsWith('-auth-token')) {
        final val = localStorage[key];
        if (val != null && val.isNotEmpty && val != 'null') {
          return true;
        }
      }
    }
  } catch (_) {}
  return false;
}

/// Triggers a browser file download using Blob and AnchorElement.
void downloadFile({
  required String content,
  required String fileName,
  String mimeType = 'text/csv',
}) {
  try {
    final bytes = const Utf8Encoder().convert(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    // ignore: unused_local_variable
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  } catch (_) {}
}
