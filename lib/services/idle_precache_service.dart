// lib/services/idle_precache_service.dart

import 'dart:async'; // Correct import for Timer
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';

class IdlePrecacheService {
  final Ref _ref;
  Timer? _idleTimer;
  final Set<String> _precacheQueue = {};

  // We now require a BuildContext for our operations.
  BuildContext? _context;

  IdlePrecacheService(this._ref);

  // The UI will call this once to provide a valid context.
  void setContext(BuildContext context) {
    _context = context;
    // Now that we have a context, we can kick off the initial cache.
    _runIdlePrecache();
  }

  /// The UI calls this method on every scroll event.
  void onUserScroll() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 1), () {
      _runIdlePrecache();
    });
  }

  void _runIdlePrecache() {
    // Use the stored context. If it's not set yet, we can't do anything.
    if (_context == null) {
      debugPrint("[IDLE PRECACHE] Could not run: BuildContext is not yet set.");
      return;
    }

    final groups = _ref.read(homePageProductsProvider).value ?? [];
    if (groups.isEmpty) return;

    const int idleBatchSize = 20;
    int itemsToCache = 0;
    debugPrint("[IDLE PRECACHE] User is idle. Looking for next batch of images...");

    final allProducts = groups.expand((g) => g.products);

    for (final product in allProducts) {
      if (itemsToCache >= idleBatchSize) break;

      if (product.imageUrl.isNotEmpty && !_precacheQueue.contains(product.imageUrl)) {
        precacheImage(
          CachedNetworkImageProvider(product.imageUrl),
          _context!, // We know it's not null here because of the check above.
        );
        _precacheQueue.add(product.imageUrl);
        itemsToCache++;
      }
    }

    if (itemsToCache > 0) {
      debugPrint("[IDLE PRECACHE] Triggered background caching for $itemsToCache new images.");
    }
  }

  void dispose() {
    _idleTimer?.cancel();
  }
}

/// The provider remains the same.
final idlePrecacheServiceProvider = Provider.autoDispose<IdlePrecacheService>((ref) {
  final service = IdlePrecacheService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

// We no longer need the navigatorKeyProvider. You can delete it.