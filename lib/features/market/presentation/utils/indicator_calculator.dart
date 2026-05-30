import 'dart:math';
import 'package:interactive_chart/interactive_chart.dart'; // For CandleData model

class IndicatorCalculator {
  static List<double?> calculateSMA(List<CandleData> candles, int period) {
    List<double?> sma = List.filled(candles.length, null);
    if (candles.length < period) return sma;

    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += candles[i].close ?? 0;
    }
    sma[period - 1] = sum / period;

    for (int i = period; i < candles.length; i++) {
      sum += (candles[i].close ?? 0) - (candles[i - period].close ?? 0);
      sma[i] = sum / period;
    }
    return sma;
  }

  static List<double?> calculateEMA(List<CandleData> candles, int period) {
    List<double?> ema = List.filled(candles.length, null);
    if (candles.length < period) return ema;

    double multiplier = 2 / (period + 1);
    
    // Initial SMA for first EMA
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += candles[i].close ?? 0;
    }
    ema[period - 1] = sum / period;

    for (int i = period; i < candles.length; i++) {
      double close = candles[i].close ?? 0;
      ema[i] = (close - ema[i - 1]!) * multiplier + ema[i - 1]!;
    }
    return ema;
  }

  static List<BollingerBandValue> calculateBollingerBands(List<CandleData> candles, int period, double stdDevMultiplier) {
    List<BollingerBandValue> bands = List.filled(candles.length, BollingerBandValue(null, null, null));
    if (candles.length < period) return bands;

    for (int i = period - 1; i < candles.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += candles[i - j].close ?? 0;
      }
      double sma = sum / period;

      double varianceSum = 0;
      for (int j = 0; j < period; j++) {
        double close = candles[i - j].close ?? 0;
        varianceSum += pow(close - sma, 2);
      }
      double stdDev = sqrt(varianceSum / period);

      bands[i] = BollingerBandValue(
        sma + (stdDev * stdDevMultiplier),
        sma,
        sma - (stdDev * stdDevMultiplier),
      );
    }
    return bands;
  }

  static List<double?> calculateRSI(List<CandleData> candles, int period) {
    List<double?> rsi = List.filled(candles.length, null);
    if (candles.length <= period) return rsi;

    double avgGain = 0;
    double avgLoss = 0;

    for (int i = 1; i <= period; i++) {
      double change = (candles[i].close ?? 0) - (candles[i - 1].close ?? 0);
      if (change > 0) {
        avgGain += change;
      } else {
        avgLoss += change.abs();
      }
    }
    avgGain /= period;
    avgLoss /= period;

    if (avgLoss == 0) {
      rsi[period] = 100;
    } else {
      double rs = avgGain / avgLoss;
      rsi[period] = 100 - (100 / (1 + rs));
    }

    for (int i = period + 1; i < candles.length; i++) {
      double change = (candles[i].close ?? 0) - (candles[i - 1].close ?? 0);
      double gain = change > 0 ? change : 0;
      double loss = change < 0 ? change.abs() : 0;

      avgGain = ((avgGain * (period - 1)) + gain) / period;
      avgLoss = ((avgLoss * (period - 1)) + loss) / period;

      if (avgLoss == 0) {
        rsi[i] = 100;
      } else {
        double rs = avgGain / avgLoss;
        rsi[i] = 100 - (100 / (1 + rs));
      }
    }
    return rsi;
  }

  static List<MacdValue> calculateMACD(List<CandleData> candles, int fastPeriod, int slowPeriod, int signalPeriod) {
    List<MacdValue> macdValues = List.filled(candles.length, MacdValue(null, null, null));
    
    List<double?> fastEma = calculateEMA(candles, fastPeriod);
    List<double?> slowEma = calculateEMA(candles, slowPeriod);
    
    List<double?> macdLine = List.filled(candles.length, null);
    for (int i = 0; i < candles.length; i++) {
      if (fastEma[i] != null && slowEma[i] != null) {
        macdLine[i] = fastEma[i]! - slowEma[i]!;
      }
    }

    // Calculate signal line (EMA of MACD line)
    List<double?> signalLine = List.filled(candles.length, null);
    
    // Find first valid MACD index
    int firstMacdIndex = macdLine.indexWhere((val) => val != null);
    if (firstMacdIndex == -1 || firstMacdIndex + signalPeriod > candles.length) return macdValues;

    double multiplier = 2 / (signalPeriod + 1);
    double sum = 0;
    for (int i = firstMacdIndex; i < firstMacdIndex + signalPeriod; i++) {
      sum += macdLine[i]!;
    }
    signalLine[firstMacdIndex + signalPeriod - 1] = sum / signalPeriod;

    for (int i = firstMacdIndex + signalPeriod; i < candles.length; i++) {
      signalLine[i] = (macdLine[i]! - signalLine[i - 1]!) * multiplier + signalLine[i - 1]!;
    }

    for (int i = 0; i < candles.length; i++) {
      if (macdLine[i] != null && signalLine[i] != null) {
        macdValues[i] = MacdValue(macdLine[i], signalLine[i], macdLine[i]! - signalLine[i]!);
      }
    }

    return macdValues;
  }

  static List<double?> calculateATR(List<CandleData> candles, int period) {
    List<double?> atr = List.filled(candles.length, null);
    if (candles.length <= period) return atr;

    List<double> tr = List.filled(candles.length, 0);
    for (int i = 1; i < candles.length; i++) {
      double high = candles[i].high ?? 0;
      double low = candles[i].low ?? 0;
      double prevClose = candles[i - 1].close ?? 0;
      tr[i] = [
        high - low,
        (high - prevClose).abs(),
        (low - prevClose).abs()
      ].reduce(max);
    }

    double sum = 0;
    for (int i = 1; i <= period; i++) {
      sum += tr[i];
    }
    atr[period] = sum / period;

    for (int i = period + 1; i < candles.length; i++) {
      atr[i] = (atr[i - 1]! * (period - 1) + tr[i]) / period;
    }
    return atr;
  }

  static List<StochasticValue> calculateStochastic(List<CandleData> candles, int kPeriod, int dPeriod) {
    List<StochasticValue> stoch = List.filled(candles.length, StochasticValue(null, null));
    if (candles.length < kPeriod) return stoch;

    List<double?> kValues = List.filled(candles.length, null);

    for (int i = kPeriod - 1; i < candles.length; i++) {
      double highestHigh = double.negativeInfinity;
      double lowestLow = double.infinity;
      
      for (int j = 0; j < kPeriod; j++) {
        double high = candles[i - j].high ?? 0;
        double low = candles[i - j].low ?? 0;
        if (high > highestHigh) highestHigh = high;
        if (low < lowestLow) lowestLow = low;
      }
      
      double close = candles[i].close ?? 0;
      if (highestHigh - lowestLow == 0) {
        kValues[i] = 100;
      } else {
        kValues[i] = 100 * ((close - lowestLow) / (highestHigh - lowestLow));
      }
    }

    for (int i = kPeriod - 1 + dPeriod - 1; i < candles.length; i++) {
      double sum = 0;
      bool valid = true;
      for (int j = 0; j < dPeriod; j++) {
        if (kValues[i - j] == null) {
          valid = false;
          break;
        }
        sum += kValues[i - j]!;
      }
      if (valid) {
        stoch[i] = StochasticValue(kValues[i], sum / dPeriod);
      } else {
        stoch[i] = StochasticValue(kValues[i], null);
      }
    }

    return stoch;
  }
}

class BollingerBandValue {
  final double? upper;
  final double? middle;
  final double? lower;
  BollingerBandValue(this.upper, this.middle, this.lower);
}

class MacdValue {
  final double? macd;
  final double? signal;
  final double? histogram;
  MacdValue(this.macd, this.signal, this.histogram);
}

class StochasticValue {
  final double? k;
  final double? d;
  StochasticValue(this.k, this.d);
}
