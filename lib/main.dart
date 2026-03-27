import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 ONLY FIX — does NOT affect mobile
  if (kIsWeb) {
    final uri = Uri.base;

    // Remove Supabase OAuth fragment so GoRouter doesn't crash
    if (uri.fragment.contains('access_token')) {
      html.window.history.replaceState(null, '', '/');
    }
  }

  await Supabase.initialize(
    url: 'https://fdbiqskcifqfbogexfbi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkYmlxc2tjaWZxZmJvZ2V4ZmJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MzQzODIsImV4cCI6MjA4ODQxMDM4Mn0.ZdISRpYOry_iW4maMmFrB0OGbTHSRWjMeLVsMDV2Xpc',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    print("🔥 AUTH EVENT: ${data.event}");
  });

  runApp(const CodeNyxApp());
}
