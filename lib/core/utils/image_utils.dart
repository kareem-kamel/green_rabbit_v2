import 'package:flutter/foundation.dart';

class ImageUtils {
  /// Wraps an image URL with a CORS proxy if running on web to avoid CORS issues.
  static String getSafeImageUrl(String url) {
    if (url.isEmpty) return url;
    
    // Only apply proxy on web
    if (kIsWeb) {
      // If it's already a proxy or a data URL, don't wrap it
      if (url.startsWith('data:') || url.contains('cors-anywhere') || url.contains('proxy')) {
        return url;
      }
      
      // Using a public CORS proxy as a workaround for Flutter Web CanvasKit CORS issues
      // Note: In production, you should use your own proxy server.
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    }
    
    return url;
  }
}
