import 'balance.dart';

abstract final class Checkpoints {
  static const normalLevels = [10, 20, 30];
  static const normalPriceMultiplier = 100.0;
  static const rarePriceMultiplier = 1000.0;
  // A purchased rare starts with the same base value as a rare found at +30.
  static double get rareBase => Balance.salePrices[30] * 3;
  static double get rarePrice => rareBase * rarePriceMultiplier;
  static double normalPrice(int level) =>
      Balance.salePrices[level] * normalPriceMultiplier;
  static bool isNormalLevel(int level) =>
      level == 0 || normalLevels.contains(level);
}
