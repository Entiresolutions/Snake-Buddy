// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:collection';
import 'package:image/image.dart' as img;

void main() {
  print('Loading snake_logo_raw.png...');
  final rawBytes = File('assets/images/snake_logo_raw.png').readAsBytesSync();
  final src = img.decodePng(rawBytes)!;

  // 1. First, create a version with transparent background
  // Using flood fill from the borders with white threshold
  final visited = List<bool>.filled(src.width * src.height, false);
  final queue = Queue<int>();

  void add(int x, int y) {
    if (x < 0 || x >= src.width || y < 0 || y >= src.height) return;
    final idx = y * src.width + x;
    if (visited[idx]) return;
    final p = src.getPixel(x, y);
    // Background is near white (r,g,b > 240)
    if (p.r > 240 && p.g > 240 && p.b > 240) {
      visited[idx] = true;
      queue.add(idx);
    }
  }

  for (int x = 0; x < src.width; x++) {
    add(x, 0);
    add(x, src.height - 1);
  }
  for (int y = 0; y < src.height; y++) {
    add(0, y);
    add(src.width - 1, y);
  }

  while (queue.isNotEmpty) {
    final idx = queue.removeFirst();
    final x = idx % src.width;
    final y = idx ~/ src.width;
    add(x + 1, y);
    add(x - 1, y);
    add(x, y + 1);
    add(x, y - 1);
  }

  final transparentSrc = img.Image(
    width: src.width,
    height: src.height,
    numChannels: 4,
  );

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final idx = y * src.width + x;
      final p = src.getPixel(x, y);
      if (visited[idx]) {
        transparentSrc.setPixelRgba(x, y, 255, 255, 255, 0);
      } else {
        transparentSrc.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }
  }

  // Find exact content bounding box of non-transparent pixels
  int minX = transparentSrc.width, maxX = 0;
  int minY = transparentSrc.height, maxY = 0;
  for (int y = 0; y < transparentSrc.height; y++) {
    for (int x = 0; x < transparentSrc.width; x++) {
      if (transparentSrc.getPixel(x, y).a > 0) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  print('Content bbox: [$minX, $minY] to [$maxX, $maxY]');
  final cropW = maxX - minX + 1;
  final cropH = maxY - minY + 1;
  final cropped = img.copyCrop(transparentSrc, x: minX, y: minY, width: cropW, height: cropH);

  // 2. Generate standard app_icon.png (1024x1024, white background, no alpha for iOS/standard)
  // Target width for cropped logo: ~840px
  final iconCanvas = img.Image(width: 1024, height: 1024, numChannels: 3);
  img.fill(iconCanvas, color: img.ColorRgb8(255, 255, 255));

  final scaledW1 = 860;
  final scaledH1 = (cropH * (scaledW1 / cropW)).round();
  final resized1 = img.copyResize(cropped, width: scaledW1, height: scaledH1, interpolation: img.Interpolation.linear);

  final destX1 = (1024 - scaledW1) ~/ 2;
  final destY1 = (1024 - scaledH1) ~/ 2;
  img.compositeImage(iconCanvas, resized1, dstX: destX1, dstY: destY1);

  File('assets/images/app_icon.png').writeAsBytesSync(img.encodePng(iconCanvas));
  print('Saved assets/images/app_icon.png');

  // 3. Generate Android Adaptive Icon Foreground (1024x1024, transparent background)
  // Target width for cropped logo inside safe zone: ~640px
  final fgCanvas = img.Image(width: 1024, height: 1024, numChannels: 4);
  img.fill(fgCanvas, color: img.ColorRgba8(0, 0, 0, 0));

  final scaledW2 = 640;
  final scaledH2 = (cropH * (scaledW2 / cropW)).round();
  final resized2 = img.copyResize(cropped, width: scaledW2, height: scaledH2, interpolation: img.Interpolation.linear);

  final destX2 = (1024 - scaledW2) ~/ 2;
  final destY2 = (1024 - scaledH2) ~/ 2;
  img.compositeImage(fgCanvas, resized2, dstX: destX2, dstY: destY2);

  File('assets/images/app_icon_foreground.png').writeAsBytesSync(img.encodePng(fgCanvas));
  print('Saved assets/images/app_icon_foreground.png');
}
