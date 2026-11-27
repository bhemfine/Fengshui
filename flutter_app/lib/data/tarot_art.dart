/// Bundled style-D card art. Paths are relative to the app's asset bundle.
abstract final class TarotArt {
  static const String backAsset = 'assets/tarot/card-back.webp';

  /// Asset path for a catalog card [id] (for example `the-fool`).
  static String assetFor(String id) => 'assets/tarot/$id.webp';
}
