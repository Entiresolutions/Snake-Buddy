import 'dart:math' as math;

/// Core rules and constants for the 30-level campaign.
class LevelRules {
  static const int totalLevels = 30;
  static const int targetScore = 100;
  static const int boardCols = 15;
  static const int boardRows = 20;
  static const int maxChancesPerAttempt = 2;
  static const int snapshotBufferSize = 8;

  // Starting snake coordinates (cols: 0-14, rows: 0-19)
  static const List<List<int>> initialSnake = [
    [7, 9],  // Head
    [7, 10], // Body
    [7, 11], // Tail
  ];

  static const String initialDirection = 'up';

  /// Safe starting zone where hazards and patrol paths are prohibited:
  /// cols 6-8, rows 4-12
  static bool isInStartSafeZone(int col, int row) {
    return col >= 6 && col <= 8 && row >= 4 && row <= 12;
  }

  /// Calculates tick duration for a level and difficulty base tick.
  /// tickMs = max(90, baseTick * (1 - 0.01 * (level - 1)))
  static int calculateTickMs(int baseTick, int level) {
    final double factor = 1.0 - 0.01 * (level - 1);
    final int computed = (baseTick * factor).round();
    return math.max(90, computed);
  }
}

/// Movement pattern for patrol blocks.
enum PatrolMode {
  pingPong,
  loop,
}

/// Patrol block specification.
class PatrolConfig {
  final List<List<int>> path; // sequence of [x, y] coordinates
  final PatrolMode mode;
  final int stepEveryTicks; // steps 1 cell every N ticks
  final int size; // 1 for 1x1, 2 for 1x2

  const PatrolConfig({
    required this.path,
    this.mode = PatrolMode.pingPong,
    this.stepEveryTicks = 2,
    this.size = 1,
  });
}

/// Spike group timing and cycle parameters.
class SpikeGroupConfig {
  final int id; // 1..4
  final int offTicks;
  final int warnTicks;
  final int onTicks;
  final int phaseOffset;

  const SpikeGroupConfig({
    required this.id,
    required this.offTicks,
    this.warnTicks = 2,
    required this.onTicks,
    this.phaseOffset = 0,
  });

  int get cycleLength => offTicks + warnTicks + onTicks;

  /// Returns current state for a given tick index: 'off', 'warn', or 'on'.
  String stateAtTick(int tick) {
    if (cycleLength <= 0) return 'off';
    final mod = (tick + phaseOffset) % cycleLength;
    if (mod < offTicks) return 'off';
    if (mod < offTicks + warnTicks) return 'warn';
    return 'on';
  }
}

/// Configuration for a single level in the 30-level campaign.
class LevelConfig {
  final int id; // 1..30
  final String name;
  final int tier; // 1..6
  final String tierName;
  final bool isBoss;
  final bool isMiniBoss;
  final String? newMechanicHint;
  final List<String> asciiMap; // exactly 20 lines of 15 characters
  final List<SpikeGroupConfig> spikeGroups;
  final List<PatrolConfig> patrols;

  const LevelConfig({
    required this.id,
    required this.name,
    required this.tier,
    required this.tierName,
    this.isBoss = false,
    this.isMiniBoss = false,
    this.newMechanicHint,
    required this.asciiMap,
    this.spikeGroups = const [],
    this.patrols = const [],
  });

  /// Derived tick duration in milliseconds for this level given a base tick.
  int tickMs(int baseTick) => LevelRules.calculateTickMs(baseTick, id);
}
