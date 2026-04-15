import 'package:certipath_app/features/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/login_page.dart';
import 'features/auth/application/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: authState.status == AuthStatus.authenticated
          ? const MainPage()
          : const LoginPage(),
    );
  }
}
