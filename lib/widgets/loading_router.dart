// lib/widgets/loading_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/widgets/fast_loading_screen.dart';
import 'package:sales_app_mvp/widgets/loading_gate.dart';

class LoadingRouter extends ConsumerWidget {
  const LoadingRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NO LISTENERS. This widget only builds UI.

    final appDataState = ref.watch(appDataProvider);

    switch (appDataState.loadingType) {
      case LoadingType.fromNetwork:
        return const LoadingGate();
      case LoadingType.fromCache:
        return const FastLoadingScreen();
      case LoadingType.unknown:
        return const FastLoadingScreen();
    }
  }
}