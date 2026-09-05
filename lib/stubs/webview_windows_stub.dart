// Stub for non-Windows platforms.
// Provides the same public API as webview_windows so the code compiles,
// but throws at runtime if accidentally called outside Windows.
class WebviewController {
  WebviewController();
  WebviewValue get value => const WebviewValue(isInitialized: false);
  Stream<LoadingState> get loadingState => const Stream.empty();
  Future<void> initialize() => throw UnsupportedError('WebviewController is only supported on Windows.');
  Future<void> loadStringContent(String html) => throw UnsupportedError('WebviewController is only supported on Windows.');
  Future<void> loadUrl(String url) => throw UnsupportedError('WebviewController is only supported on Windows.');
  Future<void> executeScript(String script) => throw UnsupportedError('WebviewController is only supported on Windows.');
  void dispose() {}
}

class WebviewValue {
  final bool isInitialized;
  const WebviewValue({required this.isInitialized});
}

enum LoadingState { none, loading, navigationCompleted }

class Webview extends Object {
  final WebviewController controller;
  const Webview(this.controller);
}
