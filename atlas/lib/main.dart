import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/atlas_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AtlasStorage.bootstrap();
  runApp(const ProviderScope(child: AtlasApp()));
}
