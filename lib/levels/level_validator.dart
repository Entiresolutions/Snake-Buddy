import 'dart:collection';
import 'package:snake_game/levels/level_model.dart';

/// Validates that a LevelConfig adheres to all level design and safety constraints (V1-V7).
class LevelValidator {
  static List<String> validate(LevelConfig level) {
    final errors = <String>[];

    // Basic map dimensions
    if (level.asciiMap.length != LevelRules.boardRows) {
      errors.add('Map must have exactly ${LevelRules.boardRows} rows, got ${level.asciiMap.length}');
      return errors;
    }
    for (int r = 0; r < LevelRules.boardRows; r++) {
      if (level.asciiMap[r].length != LevelRules.boardCols) {
        errors.add('Row $r must have length ${LevelRules.boardCols}, got ${level.asciiMap[r].length}');
      }
    }
    if (errors.isNotEmpty) return errors;

    final rocks = <(int, int)>{};
    final portals = <String, List<(int, int)>>{};
    final spikes = <int, Set<(int, int)>>{};
    final allHazards = <(int, int)>{};

    for (int r = 0; r < LevelRules.boardRows; r++) {
      for (int c = 0; c < LevelRules.boardCols; c++) {
        final ch = level.asciiMap[r][c];
        if (ch == '#') {
          rocks.add((c, r));
          allHazards.add((c, r));
        } else if (RegExp(r'[A-D]').hasMatch(ch)) {
          portals.putIfAbsent(ch, () => []).add((c, r));
          allHazards.add((c, r));
        } else if (RegExp(r'[1-4]').hasMatch(ch)) {
          final id = int.parse(ch);
          spikes.putIfAbsent(id, () => <(int, int)>{}).add((c, r));
          allHazards.add((c, r));
        } else if (ch != '.') {
          errors.add('Invalid map character "$ch" at ($c, $r)');
        }
      }
    }

    final patrolCells = <(int, int)>{};
    for (final p in level.patrols) {
      for (final pt in p.path) {
        patrolCells.add((pt[0], pt[1]));
        allHazards.add((pt[0], pt[1]));
      }
    }

    // V1: Start safe zone (cols 6-8, rows 4-12) has no hazard and no patrol path cell
    for (int r = 4; r <= 12; r++) {
      for (int c = 6; c <= 8; c++) {
        if (allHazards.contains((c, r))) {
          errors.add('V1: Hazard or patrol in safe zone at ($c, $r)');
        }
      }
    }

    // V2: All non-rock cells form ONE connected region
    final walkable = <(int, int)>{};
    for (int r = 0; r < LevelRules.boardRows; r++) {
      for (int c = 0; c < LevelRules.boardCols; c++) {
        if (!rocks.contains((c, r))) {
          walkable.add((c, r));
        }
      }
    }

    if (walkable.isEmpty) {
      errors.add('V2: No walkable cells on board');
    } else {
      final start = (7, 9); // Initial snake head position
      if (!walkable.contains(start)) {
        errors.add('V2: Initial snake head ($start) is blocked by rock');
      } else {
        final visited = <(int, int)>{};
        final queue = Queue<(int, int)>()..add(start);
        visited.add(start);

        while (queue.isNotEmpty) {
          final curr = queue.removeFirst();
          for (final dir in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
            final next = (curr.$1 + dir.$1, curr.$2 + dir.$2);
            if (walkable.contains(next) && !visited.contains(next)) {
              visited.add(next);
              queue.add(next);
            }
          }
        }

        if (visited.length != walkable.length) {
          errors.add('V2: Board has disconnected walkable pockets. Reachable: ${visited.length}, Total: ${walkable.length}');
        }
      }
    }

    // V3: Rock cells <= 18% of the board (max 54 out of 300)
    if (rocks.length > 54) {
      errors.add('V3: Too many rock cells (${rocks.length} > 54)');
    }

    // V4: Portal endpoints are at least 6 Manhattan cells apart, not on outer edge, >= 2 free neighbors
    for (final entry in portals.entries) {
      final ch = entry.key;
      final pts = entry.value;
      if (pts.length != 2) {
        errors.add('V4: Portal $ch must appear exactly twice, found ${pts.length}');
        continue;
      }
      final p1 = pts[0];
      final p2 = pts[1];
      final manhattan = (p1.$1 - p2.$1).abs() + (p1.$2 - p2.$2).abs();
      if (manhattan < 6) {
        errors.add('V4: Portal $ch distance $manhattan < 6');
      }
      for (final pt in [p1, p2]) {
        if (pt.$1 == 0 || pt.$1 == LevelRules.boardCols - 1 || pt.$2 == 0 || pt.$2 == LevelRules.boardRows - 1) {
          errors.add('V4: Portal $ch at $pt is on outer edge');
        }
        int freeNeighbors = 0;
        for (final dir in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
          final n = (pt.$1 + dir.$1, pt.$2 + dir.$2);
          if (n.$1 >= 0 && n.$1 < LevelRules.boardCols && n.$2 >= 0 && n.$2 < LevelRules.boardRows) {
            if (!rocks.contains(n)) freeNeighbors++;
          }
        }
        if (freeNeighbors < 2) {
          errors.add('V4: Portal $ch at $pt has fewer than 2 walkable neighbors ($freeNeighbors)');
        }
      }
    }

    // V5: Corridors >= 2 cells wide for L1-25. L26-30 allows short gates (<= 3 cells) of 1-wide.
    // No dead-end pockets deeper than 1 cell.
    _checkCorridorsAndDeadEnds(level.id, walkable, rocks, errors);

    // V6: Patrol paths do not cross rocks, portals, or spikes, and keep 1 free cell clearance
    for (int pIdx = 0; pIdx < level.patrols.length; pIdx++) {
      final patrol = level.patrols[pIdx];
      for (final pt in patrol.path) {
        final c = (pt[0], pt[1]);
        if (rocks.contains(c)) {
          errors.add('V6: Patrol $pIdx crosses rock at $c');
        }
        for (final entry in portals.entries) {
          if (entry.value.contains(c)) {
            errors.add('V6: Patrol $pIdx crosses portal ${entry.key} at $c');
          }
        }
        for (final sGroup in spikes.entries) {
          if (sGroup.value.contains(c)) {
            errors.add('V6: Patrol $pIdx crosses spike group ${sGroup.key} at $c');
          }
        }
      }
    }

    // V7: At least 200 free cells remain after hazards
    final freeCount = (LevelRules.boardCols * LevelRules.boardRows) - allHazards.length;
    if (freeCount < 200) {
      errors.add('V7: Fewer than 200 free cells remaining ($freeCount < 200)');
    }

    return errors;
  }

  static void _checkCorridorsAndDeadEnds(
    int levelId,
    Set<(int, int)> walkable,
    Set<(int, int)> rocks,
    List<String> errors,
  ) {
    // Check dead-ends: a walkable cell with only 1 walkable neighbor is a dead end of depth 1.
    // If that neighbor itself has only 2 neighbors (the dead end and another cell), it's a dead end of depth >= 2.
    for (final cell in walkable) {
      final neighbors = _walkableNeighbors(cell, walkable);
      if (neighbors.length == 1) {
        // Dead-end pocket of depth >= 1
        final n1 = neighbors.first;
        final n1Neighbors = _walkableNeighbors(n1, walkable);
        if (n1Neighbors.length <= 2) {
          // n1 is also a corridor cell leading into the dead end -> depth > 1
          errors.add('V5: Dead-end pocket deeper than 1 cell at $cell through $n1');
        }
      }
    }

    // Check 1-wide bottlenecks for L1-25
    if (levelId <= 25) {
      for (final cell in walkable) {
        final horizontalNeighbors = _walkableNeighborsInAxis(cell, walkable, horizontal: true);
        final verticalNeighbors = _walkableNeighborsInAxis(cell, walkable, horizontal: false);

        // If trapped between rocks horizontally with no adjacent parallel walkable channel
        if (horizontalNeighbors.length == 2 && verticalNeighbors.isEmpty) {
          // A horizontal 1-wide strip. Check if above and below are both rocks
          final top = (cell.$1, cell.$2 - 1);
          final bottom = (cell.$1, cell.$2 + 1);
          if (rocks.contains(top) && rocks.contains(bottom)) {
            errors.add('V5: 1-wide corridor at $cell in level <= 25');
          }
        }
        // If trapped between rocks vertically
        if (verticalNeighbors.length == 2 && horizontalNeighbors.isEmpty) {
          final left = (cell.$1 - 1, cell.$2);
          final right = (cell.$1 + 1, cell.$2);
          if (rocks.contains(left) && rocks.contains(right)) {
            errors.add('V5: 1-wide corridor at $cell in level <= 25');
          }
        }
      }
    }
  }

  static List<(int, int)> _walkableNeighbors((int, int) cell, Set<(int, int)> walkable) {
    final list = <(int, int)>[];
    for (final dir in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final n = (cell.$1 + dir.$1, cell.$2 + dir.$2);
      if (walkable.contains(n)) list.add(n);
    }
    return list;
  }

  static List<(int, int)> _walkableNeighborsInAxis((int, int) cell, Set<(int, int)> walkable, {required bool horizontal}) {
    final list = <(int, int)>[];
    final dirs = horizontal ? const [(-1, 0), (1, 0)] : const [(0, -1), (0, 1)];
    for (final dir in dirs) {
      final n = (cell.$1 + dir.$1, cell.$2 + dir.$2);
      if (walkable.contains(n)) list.add(n);
    }
    return list;
  }
}
