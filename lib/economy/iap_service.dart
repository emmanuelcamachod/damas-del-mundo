// Servicio de compras integradas (IAP) desacoplado para monedas virtuales (GEM V4.0).
// Cumple Negative Space Programming y anidamiento <= 2.

import 'dart:async';
import 'coin_pack.dart';

abstract class InAppPurchaseService {
  /// Inicia el flujo de compra para un paquete de monedas.
  Future<bool> buyCoinPackage(CoinPackage pack);

  /// Flujo de compras completadas y validadas exitosamente.
  Stream<CoinPackage> get onPurchaseCompleted;

  /// Libera recursos del servicio.
  void dispose();
}

class MockInAppPurchaseService implements InAppPurchaseService {
  final _purchaseController = StreamController<CoinPackage>.broadcast();

  @override
  Stream<CoinPackage> get onPurchaseCompleted => _purchaseController.stream;

  @override
  Future<bool> buyCoinPackage(CoinPackage pack) async {
    // Simula la confirmación de Google Play / App Store tras 400ms
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _purchaseController.add(pack);
    return true;
  }

  @override
  void dispose() {
    _purchaseController.close();
  }
}
