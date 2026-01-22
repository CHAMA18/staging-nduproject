import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/app_strings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ndu_project/firebase_options.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/providers/app_content_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  // Suppress specific framework warnings and inspector errors
  final previousHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    final stackTrace = details.stack?.toString() ?? '';

    // Suppress inspector selection errors (common in Dreamflow preview)
    if (message.contains('Id does not exist.')) {
      debugPrint('Inspector selection error suppressed: $message');
      return;
    }

    // Comprehensive suppression of RestorableNode/ModalScope warnings
    if (message.contains('_RestorableNode') ||
        message.contains('RestorableNode') ||
        message.contains('_DialogScope') ||
        message.contains('ModalScopeStatus') ||
        message.contains('ModalScope') ||
        message.contains('Nested arrays are not supported') ||
        message.contains('Remote arrays are not supported') ||
        message.contains('listening Function with') ||
        message.contains('listening to Function') ||
        message.contains('called with invalid state') ||
        message.contains('saved with invalid state') ||
        message.contains('invalid state. Nested arrays') ||
        stackTrace.contains('mode#') ||
        (message.contains('listening to') && message.contains('invalid state'))) {
      debugPrint('Route state warning suppressed: $message');
      return;
    }

    // Log other errors for debugging
    debugPrint('Flutter error: $message');
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
    previousHandler?.call(details);
  };

  // Override the error widget builder to hide specific warnings from UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    final stackTrace = details.stack?.toString() ?? '';

    // Don't show error widgets for these suppressed warnings
    if (message.contains('Id does not exist.') ||
        message.contains('_RestorableNode') ||
        message.contains('RestorableNode') ||
        message.contains('_DialogScope') ||
        message.contains('ModalScopeStatus') ||
        message.contains('ModalScope') ||
        message.contains('Nested arrays are not supported') ||
        message.contains('Remote arrays are not supported') ||
        message.contains('listening Function with') ||
        message.contains('listening to Function') ||
        message.contains('called with invalid state') ||
        message.contains('saved with invalid state') ||
        message.contains('invalid state. Nested arrays') ||
        stackTrace.contains('mode#') ||
        (message.contains('listening to') && message.contains('invalid state'))) {
      return const SizedBox.shrink(); // Return empty widget for suppressed errors
    }

    // For other errors, show a friendly error screen
    return _FriendlyErrorScreen(
      title: 'Something went wrong',
      message: message,
      stack: details.stack?.toString(),
    );
  };

  Object? firebaseInitError;
  try {
    debugPrint('Starting Firebase.initializeApp...');
    // Prevent Preview from hanging indefinitely if Firebase JS is slow/blocked on web
    await Firebase
        .initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 12));
    debugPrint('Firebase initialized');
  } on TimeoutException catch (e, st) {
    firebaseInitError = e;
    debugPrint('Firebase init timeout: $e');
    debugPrint(st.toString());
  } catch (e, st) {
    firebaseInitError = e;
    debugPrint('Firebase init error: $e');
    debugPrint(st.toString());
  }

  // Initialize OpenAI API key from environment (if provided)
  ApiKeyManager.initializeApiKey();

  runZonedGuarded(() {
    runApp(MyApp(firebaseInitError: firebaseInitError));
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error');
    debugPrint(stack.toString());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.firebaseInitError});

  final Object? firebaseInitError;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectDataProvider()),
        ChangeNotifierProvider(create: (_) => AppContentProvider()..watchContent()..loadLocalOverrides()),
      ],
      child: Builder(
        builder: (context) {
          final projectProvider = Provider.of<ProjectDataProvider>(context, listen: false);
          return ProjectDataInherited(
            provider: projectProvider,
            child: MaterialApp.router(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: ThemeMode.system,
              routerConfig: _routerFor(firebaseInitError),
              // Performance optimizations
              builder: (context, child) {
                final media = MediaQuery.of(context).copyWith(boldText: false);
                return MediaQuery(
                  // Disable unnecessary animations and transitions on slow devices
                  data: media,
                  child: child ?? const SizedBox.shrink(),
                );
              },
              // Reduce checkerboard opacity for better performance
              checkerboardRasterCacheImages: false,
              checkerboardOffscreenLayers: false,
            ),
          );
        },
      ),
    );
  }
}


GoRouter _routerFor(Object? firebaseInitError) {
  if (firebaseInitError != null) {
    // Minimal router that just shows the friendly error page
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => _FriendlyErrorScreen(
            title: 'Unable to connect to the cloud',
            message: 'Firebase failed to initialize. Some features may be unavailable.',
            stack: firebaseInitError.toString(),
          ),
        ),
      ],
    );
  }
  return AppRouter.main;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FriendlyErrorScreen extends StatelessWidget {
  const _FriendlyErrorScreen({required this.title, required this.message, this.stack});

  final String title;
  final String message;
  final String? stack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(title, style: theme.textTheme.titleLarge),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(message, style: theme.textTheme.bodyMedium),
                    if (stack != null) ...[
                      const SizedBox(height: 12),
                      ExpansionTile(
                        leading: const Icon(Icons.bug_report, color: Colors.red),
                        title: const Text('Technical details'),
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              stack!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          // Try to navigate back safely, or do nothing if Navigator isn't available
                          try {
                            final nav = Navigator.maybeOf(context, rootNavigator: true);
                            if (nav != null && nav.canPop()) {
                              nav.pop();
                            } else {
                              debugPrint('No Navigator available or cannot pop. Please refresh the app manually.');
                            }
                          } catch (e) {
                            debugPrint('Error during retry: $e');
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
