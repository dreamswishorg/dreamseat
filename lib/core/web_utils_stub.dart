/// Stub function to clear redirect query parameters.
/// Doing nothing on mobile/desktop platforms.
void clearUrlParams() {}

/// Stub function to check if there is an active session in local storage.
/// Returns false on mobile/desktop platforms.
bool hasSessionInLocalStorage() => false;

/// Stub function to trigger a file download.
/// Doing nothing on mobile/desktop platforms.
void downloadFile({
  required String content,
  required String fileName,
  String mimeType = 'text/csv',
}) {}
