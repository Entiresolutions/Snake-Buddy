/// Service providing the Second Chance feature.
/// Future-proof hook for rewarded ads or coin spending.
class ChanceService {
  static const int kMaxChancesPerAttempt = 2;

  Future<bool> requestChance() async {
    // Default: instantly available (free)
    return true;
  }
}

