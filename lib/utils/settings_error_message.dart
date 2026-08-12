class SettingsErrorMessage {
  static String getMessage(Object error) {
    final message = error.toString().toLowerCase();

    // Network / connectivity errors
    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('network is unreachable')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    // Timeout errors
    if (message.contains('timeout') || message.contains('timed out')) {
      return 'The request took too long. Please try again.';
    }

    // Authentication/session errors
    if (message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('unauthenticated')) {
      return 'Your session has expired. Please sign in again.';
    }

    // Permission errors
    if (message.contains('403') || message.contains('forbidden')) {
      return 'You do not have permission to perform this action.';
    }

    // Not found
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested information could not be found.';
    }

    // Validation
    if (message.contains('422') || message.contains('validation')) {
      return 'Some of the information provided is invalid.';
    }

    // Server errors
    if (message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('504')) {
      return 'The server is currently unavailable. Please try again later.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }
}
