import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('debug rootBundle.load', () async {
    for (final p in [
      'assets/images/apple.png',
      'assets/images/banana.png',
      'assets/images/blueberry.png',
      'assets/images/grape.png',
    ]) {
      try {
        final b = await rootBundle.load(p);
        // ignore: avoid_print
        print('$p SUCCESS: ${b.lengthInBytes}');
      } catch (e, st) {
        // ignore: avoid_print
        print('$p ERROR: $e\n$st');
      }
    }
  });
}
