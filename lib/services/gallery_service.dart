import 'package:photo_manager/photo_manager.dart';

class GalleryService {
  /// Richiedi permessi e restituisci true se concessi
  Future<bool> requestPermission() async {
    final status = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(),
    );
    return status.isAuth;
  }

  /// Controlla se abbiamo accesso
  Future<bool> hasAccess() async {
    final state = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
    return state.isAuth;
  }

  /// Carica asset foto dalla galleria (solo immagini)
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
    final list = await path.getAssetListRange(start: start, end: end);
    return list;
  }

  /// Ottieni file da AssetEntity (path o file)
  Future<String?> getFilePath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path;
  }
}
