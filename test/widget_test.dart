import 'package:flutter_test/flutter_test.dart';
import 'package:glucare_app/calculators/dose_calculator.dart';
import 'package:glucare_app/models/models.dart';

void main() {
  test('DoseCalculator calculates correctly with typical values', () {
    final config = UserConfig(
      targetGlucoseMin: 5.0,
      targetGlucoseMax: 7.2,
      isf: 2.5,
      icr: 12.0,
    );

    final result = DoseCalculator.calculateBolus(
      currentGlucose: 8.5,
      carbs: 45,
      config: config,
      iob: 1.2,
    );

    // 食物: 45/12 = 3.75
    // 校正: (8.5-7.2)/2.5 = 0.52
    // IOB: -1.2
    // 总: 3.75 + 0.52 - 1.2 = 3.07
    expect(result.foodDose, closeTo(3.75, 0.01));
    expect(result.correctionDose, closeTo(0.52, 0.01));
    expect(result.totalDose, closeTo(3.07, 0.1));
  });
}
