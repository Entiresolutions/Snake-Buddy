// ignore_for_file: avoid_print

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/images/snake_logo_raw.png').readAsBytesSync();
  final image = img.decodePng(bytes);
  if (image == null) {
    print('Failed to decode image');
    return;
  }
  print(
      'Decoded image: width=${image.width}, height=${image.height}, channels=${image.numChannels}');

  // Sample corner pixels
  final p00 = image.getPixel(0, 0);
  final pTopRight = image.getPixel(image.width - 1, 0);
  final pBottomLeft = image.getPixel(0, image.height - 1);
  final pBottomRight = image.getPixel(image.width - 1, image.height - 1);

  print('Pixel (0,0): r=${p00.r}, g=${p00.g}, b=${p00.b}, a=${p00.a}');
  print(
      'Pixel TopRight: r=${pTopRight.r}, g=${pTopRight.g}, b=${pTopRight.b}, a=${pTopRight.a}');
  print(
      'Pixel BottomLeft: r=${pBottomLeft.r}, g=${pBottomLeft.g}, b=${pBottomLeft.b}, a=${pBottomLeft.a}');
  print(
      'Pixel BottomRight: r=${pBottomRight.r}, g=${pBottomRight.g}, b=${pBottomRight.b}, a=${pBottomRight.a}');

  // Find bounding box of non-white pixels (where r,g,b are not all 255)
  int minX = image.width;
  int minY = image.height;
  int maxX = 0;
  int maxY = 0;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final isWhite = (p.r > 250 && p.g > 250 && p.b > 250);
      if (!isWhite) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  print('Non-white content bounding box: x=[$minX, $maxX], y=[$minY, $maxY]');
  print('Content width = ${maxX - minX + 1}, height = ${maxY - minY + 1}');
}
