import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryService {
  /// Richiedi permessi e restituisci true se concessi.
  ///
  /// - Prima prova tramite `photo_manager` (dialog nativo galleria).
  /// - Se fallisce, fa un secondo tentativo con `permission_handler`
  ///   (Storage / Foto), poi ricontrolla lo stato di `photo_manager`.
  Future<bool> requestPermission() async {
    final status = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(),
    );
    debugPrint('[GalleryService] requestPermission PhotoManager -> '
        'isAuth=${status.isAuth}, hasAccess=${status.hasAccess}');
    if (status.isAuth || status.hasAccess) return true;

    // Tentativo extra con permission_handler (alcuni device/OEM sono più "capricciosi")
    final ph = await Permission.photos.request();
    debugPrint('[GalleryService] Permission.photos.request() -> $ph');

    final stateAfter = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
    debugPrint('[GalleryService] after permission_handler PhotoManager -> '
        'isAuth=${stateAfter.isAuth}, hasAccess=${stateAfter.hasAccess}');
    return stateAfter.isAuth || stateAfter.hasAccess;
  }

  /// Controlla se abbiamo accesso effettivo alla galleria.
  Future<bool> hasAccess() async {
    final state = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
    debugPrint('[GalleryService] hasAccess PhotoManager -> '
        'isAuth=${state.isAuth}, hasAccess=${state.hasAccess}');
    return state.isAuth || state.hasAccess;
  }

  /// Numero totale immagini nel primo album di sistema (tipicamente “Recenti” = tutte le foto).
  Future<int> getTotalImageCount() async {
    final hasPermission = await hasAccess();
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) return 0;
    }
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return 0;
    return await albums.first.assetCountAsync;
  }

  /// Carica asset foto dalla galleria (solo immagini). [limit] null = tutte da [start] in poi.
  Future<List<AssetEntity>> getImageAssets({int? limit, int start = 0}) async {
    final hasPermission = await hasAccess();
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) return [];
    }
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return [];
    final path = albums.first;
    final total = await path.assetCountAsync;
    final end = limit != null ? (start + limit).clamp(0, total) : total;
    if (start >= end) return [];
    final list = await path.getAssetListRange(start: start, end: end);
    return list;
  }

  /// Ottieni file da AssetEntity (path o file)
  Future<String?> getFilePath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path;
  }
}
