import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fdbiqskcifqfbogexfbi.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkYmlxc2tjaWZxZmJvZ2V4ZmJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MzQzODIsImV4cCI6MjA4ODQxMDM4Mn0.ZdISRpYOry_iW4maMmFrB0OGbTHSRWjMeLVsMDV2Xpc',
  );

  runApp(const CodeNyxApp());
}
