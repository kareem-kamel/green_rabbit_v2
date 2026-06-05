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

  static List<StochasticValue> calculateStochRSI(
    List<CandleData> candles,
    int rsiPeriod,
    int stochPeriod,
    int kSmoothing,
    int dSmoothing,
  ) {
    List<StochasticValue> stochRsi = List.filled(candles.length, StochasticValue(null, null));
    if (candles.length < rsiPeriod + stochPeriod) return stochRsi;

    // 1. Calculate RSI
    List<double?> rsiValues = calculateRSI(candles, rsiPeriod);

    // 2. Calculate raw %K
    List<double?> rawK = List.filled(candles.length, null);
    for (int i = rsiPeriod + stochPeriod - 1; i < candles.length; i++) {
      double minRsi = double.infinity;
      double maxRsi = double.negativeInfinity;
      bool valid = true;

      for (int j = 0; j < stochPeriod; j++) {
        final rsi = rsiValues[i - j];
        if (rsi == null) {
          valid = false;
          break;
        }
        if (rsi < minRsi) minRsi = rsi;
        if (rsi > maxRsi) maxRsi = rsi;
      }

      if (valid) {
        final currentRsi = rsiValues[i]!;
        if (maxRsi - minRsi == 0) {
          rawK[i] = 100.0;
        } else {
          rawK[i] = 100.0 * ((currentRsi - minRsi) / (maxRsi - minRsi));
        }
      }
    }

    // 3. Smooth raw %K to get K (kSmoothing SMA)
    List<double?> kValues = List.filled(candles.length, null);
    for (int i = 0; i < candles.length; i++) {
      if (i < kSmoothing - 1) continue;
      double sum = 0;
      bool valid = true;
      for (int j = 0; j < kSmoothing; j++) {
        if (rawK[i - j] == null) {
          valid = false;
          break;
        }
        sum += rawK[i - j]!;
      }
      if (valid) {
        kValues[i] = sum / kSmoothing;
      }
    }

    // 4. Smooth K to get D (dSmoothing SMA)
    for (int i = 0; i < candles.length; i++) {
      if (i < kSmoothing - 1 + dSmoothing - 1) continue;
      double sum = 0;
      bool valid = true;
      for (int j = 0; j < dSmoothing; j++) {
        if (kValues[i - j] == null) {
          valid = false;
          break;
        }
        sum += kValues[i - j]!;
      }
      if (valid) {
        stochRsi[i] = StochasticValue(kValues[i], sum / dSmoothing);
      }
    }

    return stochRsi;
  }

  static List<AdxValue> calculateADX(List<CandleData> candles, int period) {
    List<AdxValue> adxValues = List.filled(candles.length, AdxValue(null, null, null));
    if (candles.length < period * 2) return adxValues;

    List<double> tr = List.filled(candles.length, 0.0);
    List<double> plusDM = List.filled(candles.length, 0.0);
    List<double> minusDM = List.filled(candles.length, 0.0);

    // 1. Calculate TR, +DM, -DM
    for (int i = 1; i < candles.length; i++) {
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double prevHigh = candles[i - 1].high ?? 0.0;
      double prevLow = candles[i - 1].low ?? 0.0;
      double prevClose = candles[i - 1].close ?? 0.0;

      // TR
      tr[i] = [
        high - low,
        (high - prevClose).abs(),
        (low - prevClose).abs()
      ].reduce(max);

      // +DM & -DM
      double upMove = high - prevHigh;
      double downMove = prevLow - low;

      if (upMove > downMove && upMove > 0.0) {
        plusDM[i] = upMove;
      } else {
        plusDM[i] = 0.0;
      }

      if (downMove > upMove && downMove > 0.0) {
        minusDM[i] = downMove;
      } else {
        minusDM[i] = 0.0;
      }
    }

    // 2. Smooth TR, +DM, -DM using Wilder's smoothing
    List<double> smoothedTR = List.filled(candles.length, 0.0);
    List<double> smoothedPlusDM = List.filled(candles.length, 0.0);
    List<double> smoothedMinusDM = List.filled(candles.length, 0.0);

    double trSum = 0.0;
    double plusDmSum = 0.0;
    double minusDmSum = 0.0;

    for (int i = 1; i <= period; i++) {
      trSum += tr[i];
      plusDmSum += plusDM[i];
      minusDmSum += minusDM[i];
    }

    smoothedTR[period] = trSum;
    smoothedPlusDM[period] = plusDmSum;
    smoothedMinusDM[period] = minusDmSum;

    for (int i = period + 1; i < candles.length; i++) {
      smoothedTR[i] = smoothedTR[i - 1] - (smoothedTR[i - 1] / period) + tr[i];
      smoothedPlusDM[i] = smoothedPlusDM[i - 1] - (smoothedPlusDM[i - 1] / period) + plusDM[i];
      smoothedMinusDM[i] = smoothedMinusDM[i - 1] - (smoothedMinusDM[i - 1] / period) + minusDM[i];
    }

    // 3. Calculate +DI, -DI, DX
    List<double?> plusDI = List.filled(candles.length, null);
    List<double?> minusDI = List.filled(candles.length, null);
    List<double?> dx = List.filled(candles.length, null);

    for (int i = period; i < candles.length; i++) {
      double trVal = smoothedTR[i];
      if (trVal == 0.0) {
        plusDI[i] = 0.0;
        minusDI[i] = 0.0;
      } else {
        plusDI[i] = 100.0 * smoothedPlusDM[i] / trVal;
        minusDI[i] = 100.0 * smoothedMinusDM[i] / trVal;
      }

      double diSum = plusDI[i]! + minusDI[i]!;
      double diDiff = (plusDI[i]! - minusDI[i]!).abs();
      if (diSum == 0.0) {
        dx[i] = 0.0;
      } else {
        dx[i] = 100.0 * diDiff / diSum;
      }
    }

    // 4. Smooth DX to get ADX (Wilder's smoothing)
    List<double?> adx = List.filled(candles.length, null);
    int firstDxIndex = period;
    double dxSum = 0.0;
    for (int i = firstDxIndex; i < firstDxIndex + period; i++) {
      dxSum += dx[i] ?? 0.0;
    }
    adx[firstDxIndex + period - 1] = dxSum / period;

    for (int i = firstDxIndex + period; i < candles.length; i++) {
      if (adx[i - 1] != null && dx[i] != null) {
        adx[i] = (adx[i - 1]! * (period - 1) + dx[i]!) / period;
      }
    }

    // Combine into AdxValue list
    for (int i = 0; i < candles.length; i++) {
      adxValues[i] = AdxValue(adx[i], plusDI[i], minusDI[i]);
    }

    return adxValues;
  }

  static List<double?> calculateCCI(List<CandleData> candles, int period) {
    List<double?> cci = List.filled(candles.length, null);
    if (candles.length < period) return cci;

    // 1. Calculate Typical Price (TP)
    List<double> tp = List.filled(candles.length, 0.0);
    for (int i = 0; i < candles.length; i++) {
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double close = candles[i].close ?? 0.0;
      tp[i] = (high + low + close) / 3.0;
    }

    // 2. Calculate SMA of TP and Mean Deviation
    for (int i = period - 1; i < candles.length; i++) {
      double tpSum = 0.0;
      for (int j = 0; j < period; j++) {
        tpSum += tp[i - j];
      }
      double tpSma = tpSum / period;

      double meanDevSum = 0.0;
      for (int j = 0; j < period; j++) {
        meanDevSum += (tp[i - j] - tpSma).abs();
      }
      double meanDev = meanDevSum / period;

      if (meanDev == 0.0) {
        cci[i] = 0.0;
      } else {
        cci[i] = (tp[i] - tpSma) / (0.015 * meanDev);
      }
    }

    return cci;
  }

  static List<double?> calculateWilliamsR(List<CandleData> candles, int period) {
    List<double?> williamsR = List.filled(candles.length, null);
    if (candles.length < period) return williamsR;

    for (int i = period - 1; i < candles.length; i++) {
      double highestHigh = double.negativeInfinity;
      double lowestLow = double.infinity;
      for (int j = 0; j < period; j++) {
        double high = candles[i - j].high ?? 0.0;
        double low = candles[i - j].low ?? 0.0;
        if (high > highestHigh) highestHigh = high;
        if (low < lowestLow) lowestLow = low;
      }
      double close = candles[i].close ?? 0.0;
      if (highestHigh - lowestLow == 0.0) {
        williamsR[i] = -50.0;
      } else {
        williamsR[i] = -100.0 * (highestHigh - close) / (highestHigh - lowestLow);
      }
    }
    return williamsR;
  }

  static List<double?> calculateROC(List<CandleData> candles, int period) {
    List<double?> roc = List.filled(candles.length, null);
    if (candles.length <= period) return roc;

    for (int i = period; i < candles.length; i++) {
      double prevClose = candles[i - period].close ?? 0.0;
      double currentClose = candles[i].close ?? 0.0;
      if (prevClose == 0.0) {
        roc[i] = 0.0;
      } else {
        roc[i] = ((currentClose - prevClose) / prevClose) * 100.0;
      }
    }
    return roc;
  }

  static List<double?> calculateOBV(List<CandleData> candles) {
    List<double?> obv = List.filled(candles.length, null);
    if (candles.isEmpty) return obv;

    obv[0] = (candles[0].volume ?? 0.0).toDouble();
    for (int i = 1; i < candles.length; i++) {
      double prevObv = obv[i - 1] ?? 0.0;
      double currentClose = candles[i].close ?? 0.0;
      double prevClose = candles[i - 1].close ?? 0.0;
      double vol = (candles[i].volume ?? 0.0).toDouble();

      if (currentClose > prevClose) {
        obv[i] = prevObv + vol;
      } else if (currentClose < prevClose) {
        obv[i] = prevObv - vol;
      } else {
        obv[i] = prevObv;
      }
    }
    return obv;
  }

  static List<double?> calculateMFI(List<CandleData> candles, int period) {
    List<double?> mfi = List.filled(candles.length, null);
    if (candles.length < period) return mfi;

    List<double> tp = List.filled(candles.length, 0.0);
    List<double> mf = List.filled(candles.length, 0.0);
    for (int i = 0; i < candles.length; i++) {
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double close = candles[i].close ?? 0.0;
      tp[i] = (high + low + close) / 3.0;
      mf[i] = tp[i] * (candles[i].volume ?? 0.0);
    }

    for (int i = period; i < candles.length; i++) {
      double posMF = 0.0;
      double negMF = 0.0;

      for (int j = 0; j < period; j++) {
        int idx = i - j;
        if (idx == 0) continue;
        if (tp[idx] > tp[idx - 1]) {
          posMF += mf[idx];
        } else if (tp[idx] < tp[idx - 1]) {
          negMF += mf[idx];
        }
      }

      if (negMF == 0.0) {
        mfi[i] = 100.0;
      } else {
        double mr = posMF / negMF;
        mfi[i] = 100.0 - (100.0 / (1.0 + mr));
      }
    }
    return mfi;
  }

  static List<double?> calculateVWAP(List<CandleData> candles) {
    List<double?> vwap = List.filled(candles.length, null);
    if (candles.isEmpty) return vwap;

    double cumVolume = 0.0;
    double cumTPVol = 0.0;

    for (int i = 0; i < candles.length; i++) {
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double close = candles[i].close ?? 0.0;
      double tp = (high + low + close) / 3.0;
      double vol = (candles[i].volume ?? 0.0).toDouble();

      // Check if timeframe is intraday and there is a day boundary change
      if (i > 0) {
        final d1 = DateTime.fromMillisecondsSinceEpoch(candles[i - 1].timestamp);
        final d2 = DateTime.fromMillisecondsSinceEpoch(candles[i].timestamp);
        final isNewDay = d1.day != d2.day || d1.month != d2.month || d1.year != d2.year;
        if (isNewDay) {
          cumVolume = 0.0;
          cumTPVol = 0.0;
        }
      }

      cumVolume += vol;
      cumTPVol += tp * vol;

      if (cumVolume == 0.0) {
        vwap[i] = tp;
      } else {
        vwap[i] = cumTPVol / cumVolume;
      }
    }
    return vwap;
  }

  static List<IchimokuValue> calculateIchimoku(List<CandleData> candles) {
    List<IchimokuValue> ichimoku = List.filled(
      candles.length,
      IchimokuValue(null, null, null, null, null),
    );
    if (candles.length < 26) return ichimoku;

    double? getHighLowMidpoint(int idx, int period) {
      if (idx < period - 1) return null;
      double highMax = double.negativeInfinity;
      double lowMin = double.infinity;
      for (int j = 0; j < period; j++) {
        double high = candles[idx - j].high ?? 0.0;
        double low = candles[idx - j].low ?? 0.0;
        if (high > highMax) highMax = high;
        if (low < lowMin) lowMin = low;
      }
      return (highMax + lowMin) / 2.0;
    }

    List<double?> tenkan = List.filled(candles.length, null);
    List<double?> kijun = List.filled(candles.length, null);
    List<double?> senkouA = List.filled(candles.length, null);
    List<double?> senkouB = List.filled(candles.length, null);

    for (int i = 0; i < candles.length; i++) {
      tenkan[i] = getHighLowMidpoint(i, 9);
      kijun[i] = getHighLowMidpoint(i, 26);
      senkouB[i] = getHighLowMidpoint(i, 52);

      if (tenkan[i] != null && kijun[i] != null) {
        senkouA[i] = (tenkan[i]! + kijun[i]!) / 2.0;
      }
    }

    for (int i = 0; i < candles.length; i++) {
      double? sA;
      double? sB;
      // Shift Senkou Span A and B 26 periods ahead
      if (i >= 26) {
        sA = senkouA[i - 26];
        sB = senkouB[i - 26];
      }
      double? chikou;
      // Shift Chikou Span 26 periods back
      if (i + 26 < candles.length) {
        chikou = candles[i + 26].close;
      }

      ichimoku[i] = IchimokuValue(tenkan[i], kijun[i], sA, sB, chikou);
    }
    return ichimoku;
  }

  static List<SuperTrendValue> calculateSuperTrend(List<CandleData> candles, int period, double multiplier) {
    List<SuperTrendValue> superTrend = List.filled(
      candles.length,
      SuperTrendValue(null, 1),
    );
    if (candles.length < period) return superTrend;

    List<double?> atr = calculateATR(candles, period);

    List<double> upperBand = List.filled(candles.length, 0.0);
    List<double> lowerBand = List.filled(candles.length, 0.0);
    List<int> trend = List.filled(candles.length, 1);
    List<double> value = List.filled(candles.length, 0.0);

    for (int i = period; i < candles.length; i++) {
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double close = candles[i].close ?? 0.0;
      double prevClose = candles[i - 1].close ?? 0.0;
      double atrVal = atr[i] ?? 0.0;

      double mid = (high + low) / 2.0;
      double basicUpper = mid + multiplier * atrVal;
      double basicLower = mid - multiplier * atrVal;

      upperBand[i] = (basicUpper < upperBand[i - 1] || prevClose > upperBand[i - 1])
          ? basicUpper
          : upperBand[i - 1];

      lowerBand[i] = (basicLower > lowerBand[i - 1] || prevClose < lowerBand[i - 1])
          ? basicLower
          : lowerBand[i - 1];

      if (i == period) {
        trend[i] = 1;
        value[i] = lowerBand[i];
      } else {
        trend[i] = trend[i - 1];
        if (trend[i - 1] == 1 && close < lowerBand[i]) {
          trend[i] = -1;
          value[i] = upperBand[i];
        } else if (trend[i - 1] == -1 && close > upperBand[i]) {
          trend[i] = 1;
          value[i] = lowerBand[i];
        } else {
          value[i] = trend[i] == 1 ? lowerBand[i] : upperBand[i];
        }
      }
      superTrend[i] = SuperTrendValue(value[i], trend[i]);
    }
    return superTrend;
  }

  static List<ParabolicSarValue> calculateParabolicSar(List<CandleData> candles) {
    List<ParabolicSarValue> sarList = List.filled(candles.length, ParabolicSarValue(null, true));
    if (candles.length < 2) return sarList;

    bool isUp = (candles[1].close ?? 0.0) > (candles[0].close ?? 0.0);
    double sar = isUp ? (candles[0].low ?? 0.0) : (candles[0].high ?? 0.0);
    double ep = isUp ? (candles[1].high ?? 0.0) : (candles[1].low ?? 0.0);
    double af = 0.02;

    sarList[0] = ParabolicSarValue((candles[0].low ?? 0.0).toDouble(), true);
    sarList[1] = ParabolicSarValue(sar, isUp);

    for (int i = 2; i < candles.length; i++) {
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double prevHigh = candles[i - 1].high ?? 0.0;
      double prevLow = candles[i - 1].low ?? 0.0;
      double prevPrevHigh = candles[i - 2].high ?? 0.0;
      double prevPrevLow = candles[i - 2].low ?? 0.0;

      double nextSar = sar + af * (ep - sar);

      if (isUp) {
        // Guard against SAR breaching previous lows
        double minLow = prevLow < prevPrevLow ? prevLow : prevPrevLow;
        if (nextSar > minLow) nextSar = minLow;

        // Check reversal
        if (low < nextSar) {
          isUp = false;
          sar = ep;
          ep = low;
          af = 0.02;
        } else {
          sar = nextSar;
          if (high > ep) {
            ep = high;
            af = (af + 0.02).clamp(0.02, 0.2);
          }
        }
      } else {
        // Guard against SAR breaching previous highs
        double maxHigh = prevHigh > prevPrevHigh ? prevHigh : prevPrevHigh;
        if (nextSar < maxHigh) nextSar = maxHigh;

        // Check reversal
        if (high > nextSar) {
          isUp = true;
          sar = ep;
          ep = high;
          af = 0.02;
        } else {
          sar = nextSar;
          if (low < ep) {
            ep = low;
            af = (af + 0.02).clamp(0.02, 0.2);
          }
        }
      }
      sarList[i] = ParabolicSarValue(sar, isUp);
    }
    return sarList;
  }

  static List<AroonValue> calculateAroon(List<CandleData> candles, int period) {
    List<AroonValue> aroon = List.filled(candles.length, AroonValue(null, null));
    if (candles.length < period) return aroon;

    for (int i = period - 1; i < candles.length; i++) {
      double highestHigh = double.negativeInfinity;
      double lowestLow = double.infinity;
      int highestIdx = 0;
      int lowestIdx = 0;

      for (int j = 0; j < period; j++) {
        int idx = i - j;
        double high = candles[idx].high ?? 0.0;
        double low = candles[idx].low ?? 0.0;

        if (high > highestHigh) {
          highestHigh = high;
          highestIdx = idx;
        }
        if (low < lowestLow) {
          lowestLow = low;
          lowestIdx = idx;
        }
      }

      double aroonUp = ((period - (i - highestIdx)) / period) * 100.0;
      double aroonDown = ((period - (i - lowestIdx)) / period) * 100.0;

      aroon[i] = AroonValue(aroonUp, aroonDown);
    }
    return aroon;
  }

  static List<double?> calculateUltimateOscillator(List<CandleData> candles) {
    List<double?> uo = List.filled(candles.length, null);
    if (candles.length < 28) return uo;

    List<double> bp = List.filled(candles.length, 0.0);
    List<double> tr = List.filled(candles.length, 0.0);

    for (int i = 1; i < candles.length; i++) {
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double close = candles[i].close ?? 0.0;
      double prevClose = candles[i - 1].close ?? 0.0;

      double minLowPrevClose = low < prevClose ? low : prevClose;
      double maxHighPrevClose = high > prevClose ? high : prevClose;

      bp[i] = close - minLowPrevClose;
      tr[i] = maxHighPrevClose - minLowPrevClose;
    }

    for (int i = 28; i < candles.length; i++) {
      double sumBP7 = 0.0, sumTR7 = 0.0;
      double sumBP14 = 0.0, sumTR14 = 0.0;
      double sumBP28 = 0.0, sumTR28 = 0.0;

      for (int j = 0; j < 28; j++) {
        int idx = i - j;
        if (j < 7) {
          sumBP7 += bp[idx];
          sumTR7 += tr[idx];
        }
        if (j < 14) {
          sumBP14 += bp[idx];
          sumTR14 += tr[idx];
        }
        sumBP28 += bp[idx];
        sumTR28 += tr[idx];
      }

      if (sumTR7 == 0.0 || sumTR14 == 0.0 || sumTR28 == 0.0) {
        uo[i] = 50.0;
      } else {
        double avg7 = sumBP7 / sumTR7;
        double avg14 = sumBP14 / sumTR14;
        double avg28 = sumBP28 / sumTR28;

        uo[i] = 100.0 * ((4.0 * avg7) + (2.0 * avg14) + avg28) / 7.0;
      }
    }
    return uo;
  }

  static List<BullBearPowerValue> calculateBullBearPower(List<CandleData> candles, int period) {
    List<BullBearPowerValue> values = List.filled(
      candles.length,
      BullBearPowerValue(null, null),
    );
    if (candles.length < period) return values;

    List<double?> ema = calculateEMA(candles, period);

    for (int i = period - 1; i < candles.length; i++) {
      if (ema[i] == null) continue;
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double bullPower = high - ema[i]!;
      double bearPower = low - ema[i]!;
      values[i] = BullBearPowerValue(bullPower, bearPower);
    }
    return values;
  }

  static List<double?> calculateADL(List<CandleData> candles) {
    List<double?> adl = List.filled(candles.length, null);
    if (candles.isEmpty) return adl;

    double runningADL = 0.0;
    for (int i = 0; i < candles.length; i++) {
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double close = candles[i].close ?? 0.0;
      double vol = (candles[i].volume ?? 0.0).toDouble();

      double mfm = 0.0;
      if (high - low != 0.0) {
        mfm = ((close - low) - (high - close)) / (high - low);
      }
      double mfv = mfm * vol;
      runningADL += mfv;
      adl[i] = runningADL;
    }
    return adl;
  }

  static List<double?> calculateCMF(List<CandleData> candles, int period) {
    List<double?> cmf = List.filled(candles.length, null);
    if (candles.length < period) return cmf;

    List<double> mfv = List.filled(candles.length, 0.0);
    List<double> volume = List.filled(candles.length, 0.0);

    for (int i = 0; i < candles.length; i++) {
      double high = candles[i].high ?? 0.0;
      double low = candles[i].low ?? 0.0;
      double close = candles[i].close ?? 0.0;
      double vol = (candles[i].volume ?? 0.0).toDouble();

      double mfm = 0.0;
      if (high - low != 0.0) {
        mfm = ((close - low) - (high - close)) / (high - low);
      }
      mfv[i] = mfm * vol;
      volume[i] = vol;
    }

    for (int i = period - 1; i < candles.length; i++) {
      double sumMFV = 0.0;
      double sumVol = 0.0;
      for (int j = 0; j < period; j++) {
        sumMFV += mfv[i - j];
        sumVol += volume[i - j];
      }
      if (sumVol == 0.0) {
        cmf[i] = 0.0;
      } else {
        cmf[i] = sumMFV / sumVol;
      }
    }
    return cmf;
  }

  static List<DonchianChannelValue> calculateDonchianChannels(List<CandleData> candles, int period) {
    List<DonchianChannelValue> dc = List.filled(
      candles.length,
      DonchianChannelValue(null, null, null),
    );
    if (candles.length < period) return dc;

    for (int i = period - 1; i < candles.length; i++) {
      double highestHigh = double.negativeInfinity;
      double lowestLow = double.infinity;
      for (int j = 0; j < period; j++) {
        double high = candles[i - j].high ?? 0.0;
        double low = candles[i - j].low ?? 0.0;
        if (high > highestHigh) highestHigh = high;
        if (low < lowestLow) lowestLow = low;
      }
      double basis = (highestHigh + lowestLow) / 2.0;
      dc[i] = DonchianChannelValue(highestHigh, basis, lowestLow);
    }
    return dc;
  }

  static List<KeltnerChannelValue> calculateKeltnerChannels(List<CandleData> candles, int period, double multiplier) {
    List<KeltnerChannelValue> kc = List.filled(
      candles.length,
      KeltnerChannelValue(null, null, null),
    );
    if (candles.length < period) return kc;

    List<double?> ema = calculateEMA(candles, period);
    List<double?> atr = calculateATR(candles, period);

    for (int i = period - 1; i < candles.length; i++) {
      if (ema[i] == null || atr[i] == null) continue;
      double upper = ema[i]! + (multiplier * atr[i]!);
      double lower = ema[i]! - (multiplier * atr[i]!);
      kc[i] = KeltnerChannelValue(upper, ema[i], lower);
    }
    return kc;
  }

  static List<PivotPointsValue> calculatePivotPoints(List<CandleData> candles) {
    List<PivotPointsValue> pivots = List.filled(
      candles.length,
      PivotPointsValue(null, null, null, null, null, null, null),
    );
    if (candles.length < 2) return pivots;

    double currentDayHigh = candles[0].high ?? 0.0;
    double currentDayLow = candles[0].low ?? 0.0;
    double currentDayClose = candles[0].close ?? 0.0;

    double prevDayHigh = currentDayHigh;
    double prevDayLow = currentDayLow;
    double prevDayClose = currentDayClose;

    void updatePivots(int i) {
      double p = (prevDayHigh + prevDayLow + prevDayClose) / 3.0;
      double r1 = (2.0 * p) - prevDayLow;
      double s1 = (2.0 * p) - prevDayHigh;
      double r2 = p + (prevDayHigh - prevDayLow);
      double s2 = p - (prevDayHigh - prevDayLow);
      double r3 = prevDayHigh + 2.0 * (p - prevDayLow);
      double s3 = prevDayLow - 2.0 * (prevDayHigh - p);
      pivots[i] = PivotPointsValue(p, r1, s1, r2, s2, r3, s3);
    }

    updatePivots(0);

    for (int i = 1; i < candles.length; i++) {
      final d1 = DateTime.fromMillisecondsSinceEpoch(candles[i - 1].timestamp);
      final d2 = DateTime.fromMillisecondsSinceEpoch(candles[i].timestamp);
      final isNewDay = d1.day != d2.day || d1.month != d2.month || d1.year != d2.year;

      if (isNewDay) {
        prevDayHigh = currentDayHigh;
        prevDayLow = currentDayLow;
        prevDayClose = currentDayClose;

        currentDayHigh = candles[i].high ?? 0.0;
        currentDayLow = candles[i].low ?? 0.0;
        currentDayClose = candles[i].close ?? 0.0;
      } else {
        double high = candles[i].high ?? 0.0;
        double low = candles[i].low ?? 0.0;
        if (high > currentDayHigh) currentDayHigh = high;
        if (low < currentDayLow) currentDayLow = low;
        currentDayClose = candles[i].close ?? 0.0;
      }

      updatePivots(i);
    }

    return pivots;
  }

  static List<double?> calculateDPO(List<CandleData> candles, int period) {
    List<double?> dpo = List.filled(candles.length, null);
    final int halfPeriod = (period / 2).floor() + 1;
    if (candles.length < period + halfPeriod) return dpo;

    List<double?> sma = calculateSMA(candles, period);

    for (int i = 0; i < candles.length; i++) {
      if (i + halfPeriod >= candles.length) continue;
      final double? smaVal = sma[i + halfPeriod];
      if (smaVal == null) continue;
      double close = candles[i].close ?? 0.0;
      dpo[i] = close - smaVal;
    }
    return dpo;
  }

  static List<double?> calculateSTC(List<CandleData> candles, int fastPeriod, int slowPeriod, int cyclePeriod, int smoothing) {
    List<double?> stc = List.filled(candles.length, null);
    if (candles.length < slowPeriod + cyclePeriod + smoothing) return stc;

    List<double?> fastEma = calculateEMA(candles, fastPeriod);
    List<double?> slowEma = calculateEMA(candles, slowPeriod);
    List<double> macd = List.filled(candles.length, 0.0);
    for (int i = 0; i < candles.length; i++) {
      if (fastEma[i] != null && slowEma[i] != null) {
        macd[i] = fastEma[i]! - slowEma[i]!;
      }
    }

    List<double?> fastK1 = List.filled(candles.length, null);
    for (int i = cyclePeriod - 1; i < candles.length; i++) {
      double minMacd = double.infinity;
      double maxMacd = double.negativeInfinity;
      for (int j = 0; j < cyclePeriod; j++) {
        double val = macd[i - j];
        if (val < minMacd) minMacd = val;
        if (val > maxMacd) maxMacd = val;
      }
      if (maxMacd - minMacd == 0.0) {
        fastK1[i] = 100.0;
      } else {
        fastK1[i] = 100.0 * (macd[i] - minMacd) / (maxMacd - minMacd);
      }
    }

    List<double?> pfK1 = List.filled(candles.length, null);
    int firstK1 = fastK1.indexWhere((v) => v != null);
    if (firstK1 == -1) return stc;

    double multiplier = 2.0 / (smoothing + 1);
    pfK1[firstK1] = fastK1[firstK1];
    for (int i = firstK1 + 1; i < candles.length; i++) {
      if (fastK1[i] != null && pfK1[i - 1] != null) {
        pfK1[i] = (fastK1[i]! - pfK1[i - 1]!) * multiplier + pfK1[i - 1]!;
      }
    }

    List<double?> fastK2 = List.filled(candles.length, null);
    for (int i = firstK1 + cyclePeriod - 1; i < candles.length; i++) {
      double minK1 = double.infinity;
      double maxK1 = double.negativeInfinity;
      bool valid = true;
      for (int j = 0; j < cyclePeriod; j++) {
        double? val = pfK1[i - j];
        if (val == null) {
          valid = false;
          break;
        }
        if (val < minK1) minK1 = val;
        if (val > maxK1) maxK1 = val;
      }
      if (valid) {
        if (maxK1 - minK1 == 0.0) {
          fastK2[i] = 100.0;
        } else {
          fastK2[i] = 100.0 * (pfK1[i]! - minK1) / (maxK1 - minK1);
        }
      }
    }

    int firstK2 = fastK2.indexWhere((v) => v != null);
    if (firstK2 == -1) return stc;

    stc[firstK2] = fastK2[firstK2];
    for (int i = firstK2 + 1; i < candles.length; i++) {
      if (fastK2[i] != null && stc[i - 1] != null) {
        stc[i] = (fastK2[i]! - stc[i - 1]!) * multiplier + stc[i - 1]!;
      }
    }

    return stc;
  }
}

class IchimokuValue {
  final double? tenkan;
  final double? kijun;
  final double? senkouA;
  final double? senkouB;
  final double? chikou;
  IchimokuValue(this.tenkan, this.kijun, this.senkouA, this.senkouB, this.chikou);
}

class SuperTrendValue {
  final double? value;
  final int trend; // 1 for up, -1 for down
  SuperTrendValue(this.value, this.trend);
}

class ParabolicSarValue {
  final double? sar;
  final bool isUp;
  ParabolicSarValue(this.sar, this.isUp);
}

class AroonValue {
  final double? up;
  final double? down;
  AroonValue(this.up, this.down);
}

class AdxValue {
  final double? adx;
  final double? plusDI;
  final double? minusDI;
  AdxValue(this.adx, this.plusDI, this.minusDI);
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

class BullBearPowerValue {
  final double? bull;
  final double? bear;
  BullBearPowerValue(this.bull, this.bear);
}

class DonchianChannelValue {
  final double? upper;
  final double? middle;
  final double? lower;
  DonchianChannelValue(this.upper, this.middle, this.lower);
}

class KeltnerChannelValue {
  final double? upper;
  final double? middle;
  final double? lower;
  KeltnerChannelValue(this.upper, this.middle, this.lower);
}

class PivotPointsValue {
  final double? p;
  final double? r1;
  final double? s1;
  final double? r2;
  final double? s2;
  final double? r3;
  final double? s3;
  PivotPointsValue(this.p, this.r1, this.s1, this.r2, this.s2, this.r3, this.s3);
}
