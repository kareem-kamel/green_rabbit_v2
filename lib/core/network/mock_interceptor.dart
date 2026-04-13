import 'package:dio/dio.dart';
import 'dart:async';

class MockInterceptor extends Interceptor {
  // Simple in-memory storage for mock realism
  static final List<Map<String, dynamic>> _mockWatchlistInstruments = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Simulated delay for realism
    await Future.delayed(const Duration(milliseconds: 800));

    final path = options.path;

    // --- Market Overview ---
    if (path.contains('market/overview/')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'type': path.split('/').last,
              'marketStatus': 'open',
              'lastUpdatedAt': '2025-03-08T14:30:00.000Z',
              'instruments': _generateMockInstruments(path.split('/').last),
            },
            'meta': {
              'page': 1,
              'limit': 20,
              'totalItems': 156,
              'totalPages': 8,
              'hasNext': true,
              'hasPrev': false
            }
          },
          statusCode: 200,
        ),
      );
    }

    // --- Trending ---
    if (path.contains('market/trending')) {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'period': '24h',
              'region': 'global',
              'trending': [
                {'rank': 1, 'instrument': _mockBTC, 'trendingReason': 'top gainer', 'volume': 108297},
                {'rank': 2, 'instrument': _mockAAPL, 'trendingReason': 'top gainer', 'volume': 108297},
                {'rank': 3, 'instrument': _mockNVDA, 'trendingReason': 'top gainer', 'volume': 108297},
                {'rank': 4, 'instrument': _mockETH, 'trendingReason': 'top gainer', 'volume': 108297},
                {'rank': 5, 'instrument': _mockMSFT, 'trendingReason': 'top gainer', 'volume': 108297},
              ]
            }
          },
          statusCode: 200,
        ),
      );
    }

    // --- Watchlists ---
    if ((path == 'watchlists' || path == '/watchlists') && options.method == 'GET') {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'watchlists': _mockWatchlistInstruments.isEmpty ? [] : [{
                'id': 'wl_1',
                'name': 'My Watchlist',
                'description': 'Default watchlist',
                'is_default': true,
                'instruments_count': _mockWatchlistInstruments.length,
                'instruments': _mockWatchlistInstruments,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              }]
            },
            'meta': {
              'total': _mockWatchlistInstruments.isEmpty ? 0 : 1
            }
          },
          statusCode: 200,
        ),
      );
    }

    // --- Instrument Details & Sub-paths ---
    if (path.contains('market/instruments/')) {
      final segments = path.split('/');
      // Path format: /market/instruments/{id} or /market/instruments/{id}/{subpath}
      
      String id;
      String? subPath;
      
      if (segments.length >= 5) {
        // e.g., /market/instruments/stock:AAPL/chart
        id = segments[segments.length - 2];
        subPath = segments.last;
      } else {
        // e.g., /market/instruments/stock:AAPL
        id = segments.last;
      }
      
      // News
      if (subPath == 'news') {
        return handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'success': true,
              'data': {
                'instrumentId': id,
                'articles': [
                  {
                    'id': 'news:1',
                    'title': 'The United States is bracing for a winter storm that will impact the energy sector.',
                    'summary': 'Major energy producers are adjusting operations as the storm approaches the Gulf Coast...',
                    'source': {'name': 'Reuters', 'id': 'reuters', 'logoUrl': 'https://picsum.photos/seed/reuters/100'},
                    'publishedAt': '2024-03-25T13:45:00.000Z',
                    'imageUrl': 'https://picsum.photos/seed/storm/400/300',
                    'tickers': 'UST -0.47% ENRG -0.22',
                    'commentCount': 0,
                  },
                  {
                    'id': 'news:2',
                    'title': "Apple Reports Record Services Revenue in Q1 2025",
                    'summary': "Apple's services division posted a record 23.1 billion in revenue...",
                    'source': {'name': 'Bloomberg', 'id': 'bloomberg', 'logoUrl': 'https://picsum.photos/seed/bloomberg/100'},
                    'publishedAt': '2024-03-25T11:20:00.000Z',
                    'imageUrl': 'https://picsum.photos/seed/apple2/400/300',
                    'tickers': 'ATCOa -0.47% ATLCY -0.22',
                    'commentCount': 2,
                  },
                ]
              }
            },
            statusCode: 200,
          ),
        );
      }
      
      // Chart
      if (subPath == 'chart') {
        return handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'success': true,
              'data': {
                'instrumentId': id,
                'symbol': id.split(':').last,
                'currency': 'USD',
                'candles': () {
                  final List<Map<String, dynamic>> candles = [];
                  double lastClose = 176.15;
                  final now = DateTime.now();
                  
                  for (int i = 0; i < 120; i++) {
                    final open = lastClose + (double.parse((i % 3 == 0 ? 0.05 : -0.03).toString()) * (i % 5));
                    final close = open + (double.parse(((i % 2 == 0 ? 0.4 : -0.3)).toString()) * (i % 4 == 0 ? 1.5 : 1.0));
                    final high = (open > close ? open : close) + 0.2;
                    final low = (open < close ? open : close) - 0.2;
                    
                    candles.add({
                      'timestamp': now.subtract(Duration(minutes: (120 - i) * 5)).toIso8601String(),
                      'open': open,
                      'high': high,
                      'low': low,
                      'close': close,
                      'volume': 1000000 + (i * 20000) + (i % 3 * 200000),
                    });
                    lastClose = close;
                  }
                  return candles;
                }(),
              }
            },
            statusCode: 200,
          ),
        );
      }

      // Stats
      if (subPath == 'stats') {
         return handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'success': true,
              'data': {
                'instrumentId': id,
                'performance': { 
                  'return1d': 2.07, 
                  'return1w': 3.58, 
                  'return1m': 5.82 
                },
                'volatility': { 
                  'beta': 1.24, 
                  'standardDeviation30d': 1.85 
                },
              }
            },
            statusCode: 200,
          ),
        );
      }

      // Default Detail
      return handler.resolve(
         Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'instrument': _getMockDetail(id),
            }
          },
          statusCode: 200,
        ),
      );
    }

    // --- Add to Watchlist ---
    if (path.contains('watchlists/') && path.endsWith('/instruments') && options.method == 'POST') {
      final id = options.data['instrumentId'];
      final instrument = _getMockBase(id);
      
      // Update in-memory mock
      if (!_mockWatchlistInstruments.any((i) => i['id'] == id)) {
        _mockWatchlistInstruments.add({
          ...instrument,
          'current_price': instrument['price'],
          'price_change': instrument['change'],
          'price_change_percent': instrument['changePercent'],
          'logo_url': instrument['logoUrl'],
          'added_at': DateTime.now().toIso8601String(),
        });
      }

      return handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'instrument': _mockWatchlistInstruments.firstWhere((i) => i['id'] == id),
              'watchlist_id': path.split('/')[2],
              'instruments_count': _mockWatchlistInstruments.length,
            }
          },
          statusCode: 200,
        ),
      );
    }

    // --- Remove from Watchlist ---
    if (path.contains('watchlists/') && options.method == 'DELETE') {
      final segments = path.split('/');
      if (segments.contains('instruments')) {
        final instrumentId = segments.last;
        _mockWatchlistInstruments.removeWhere((i) => i['id'] == instrumentId);
        
        return handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'success': true,
              'data': {
                'message': 'Instrument removed from watchlist',
                'removed_instrument_id': instrumentId,
                'watchlist_id': segments[2],
                'instruments_count': _mockWatchlistInstruments.length,
              }
            },
            statusCode: 200,
          ),
        );
      }
    }

    // --- Subscription Plans ---
    if ((path == 'subscriptions/plans' || path == '/subscriptions/plans') && options.method == 'GET') {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': _mockSubscriptionPlans,
          },
          statusCode: 200,
        ),
      );
    }

    // --- Current Subscription ---
    if ((path == 'subscriptions/current' || path == '/subscriptions/current') && options.method == 'GET') {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': _currentSubscription,
          },
          statusCode: 200,
        ),
      );
    }

    // --- Checkout Session ---
    if ((path == 'subscriptions/checkout' || path == '/subscriptions/checkout') && options.method == 'POST') {
      final planId = options.data['planId'];
      final plan = _mockSubscriptionPlans.firstWhere((p) => p['id'] == planId, orElse: () => _mockSubscriptionPlans.first);

      return handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'checkoutId': 'chk_mf_${DateTime.now().millisecondsSinceEpoch}',
              'paymentUrl': 'https://demo.myfatoorah.com/En/KWT/PayInvoice/Result?paymentId=100202312345678',
              'expiresAt': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
              'plan': {
                'id': plan['id'],
                'name': plan['name'],
                'price': plan['price'],
                'currency': plan['currency'],
              },
              'totalAmount': plan['price']
            }
          },
          statusCode: 200,
        ),
      );
    }

    // --- Subscription Cancel ---
    if ((path == 'subscriptions/cancel' || path == '/subscriptions/cancel') && options.method == 'POST') {
      _currentSubscription['status'] = 'canceled';
      _currentSubscription['cancelAtPeriodEnd'] = true;
      
      return handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'subscriptionId': _currentSubscription['id'],
              'status': 'canceled',
              'cancelAtPeriodEnd': true,
              'currentPeriodEnd': _currentSubscription['currentPeriodEnd'],
              'message': 'Your subscription has been canceled. You will retain access until the end of the period.'
            }
          },
          statusCode: 200,
        ),
      );
    }

    // --- Webhook (Public) ---
    if ((path == 'subscriptions/webhook' || path == '/subscriptions/webhook') && options.method == 'POST') {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'received': true,
              'processedAt': DateTime.now().toIso8601String(),
            }
          },
          statusCode: 200,
        ),
      );
    }

    // For other paths, proceed as normal (or return error if needed)
    return handler.next(options);
  }

  // --- Mock Data Helpers ---

  static final Map<String, dynamic> _currentSubscription = {
    'id': 'sub_abc123',
    'planId': 'plan_premium_monthly',
    'planName': 'Premium Monthly',
    'status': 'active',
    'currentPeriodStart': '2024-01-01T00:00:00Z',
    'currentPeriodEnd': '2024-02-01T00:00:00Z',
    'cancelAtPeriodEnd': false,
    'features': [
        'unlimited_ai_chat',
        'advanced_analytics',
        'no_ads',
        'priority_support'
    ],
    'paymentMethod': {
        'type': 'card',
        'last4': '4242',
        'brand': 'visa'
    }
  };

  static final List<Map<String, dynamic>> _mockSubscriptionPlans = [
    {
      'id': 'plan_free',
      'name': 'Free',
      'description': 'Basic access with limited features',
      'tier': 'free',
      'billingPeriod': 'monthly',
      'price': 0.0,
      'currency': 'KWD',
      'features': [
        {'id': 'limited_ai', 'name': 'Limited AI Chat', 'included': true},
        {'id': 'ads', 'name': 'Ad-Supported', 'included': true},
      ],
      'active': true,
    },
    {
      'id': 'plan_premium_monthly',
      'name': 'Premium Monthly',
      'description': 'Full access to all premium features with monthly billing',
      'tier': 'premium',
      'billingPeriod': 'monthly',
      'price': 9.99,
      'currency': 'KWD',
      'originalPrice': 12.99,
      'discount': {
        'percentage': 23,
        'validUntil': '2024-02-01T00:00:00Z'
      },
      'features': [
        {'id': 'unlimited_ai_chat', 'name': 'Unlimited AI Chat', 'included': true},
        {'id': 'no_ads', 'name': 'No Ads', 'included': true},
      ],
      'trialDays': 7,
      'popular': true,
      'active': true
    },
    {
      'id': 'plan_premium_yearly',
      'name': 'Premium Yearly',
      'description': 'Save more with yearly billing',
      'tier': 'premium',
      'billingPeriod': 'yearly',
      'price': 99.99,
      'currency': 'KWD',
      'originalPrice': 119.88,
      'features': [
        {'id': 'unlimited_ai_chat', 'name': 'Unlimited AI Chat', 'included': true},
        {'id': 'no_ads', 'name': 'No Ads', 'included': true},
      ],
      'trialDays': 7,
      'active': true
    }
  ];

  static final _mockBTC = {
    'id': 'crypto:BTC-USD',
    'symbol': 'BTC/USD',
    'name': 'Bitcoin',
    'type': 'crypto',
    'currency': 'USD',
    'price': 67842.5,
    'previousClose': 66210.0,
    'change': 1632.5,
    'changePercent': 2.47,
    'logoUrl': 'https://picsum.photos/seed/btc/200',
    'sparkline7d': [63200, 64100, 64800, 66210, 67100, 67500, 67842.5]
  };

  static final _mockETH = {
    'id': 'crypto:ETH-USD',
    'symbol': 'ETH/USD',
    'name': 'Ethereum',
    'type': 'crypto',
    'currency': 'USD',
    'price': 3842.75,
    'previousClose': 3780.0,
    'change': 62.75,
    'changePercent': 1.66,
    'logoUrl': 'https://picsum.photos/seed/eth/200',
    'sparkline7d': [3680, 3710.5, 3740, 3780, 3810.3, 3830, 3842.75]
  };

  static final _mockAAPL = {
    'id': 'stock:AAPL',
    'symbol': 'AAPL',
    'name': 'Apple Inc.',
    'type': 'stock',
    'exchange': 'NASDAQ',
    'sector': 'technology',
    'currency': 'USD',
    'price': 178.72,
    'previousClose': 175.1,
    'change': 3.62,
    'changePercent': 2.07,
    'dayHigh': 179.43,
    'dayLow': 175.82,
    'volume': 58432100,
    'marketCap': 2780000000000,
    'logoUrl': 'https://picsum.photos/seed/aapl/200',
    'sparkline7d': [172.5, 173.2, 174.8, 175.1, 176.3, 177.9, 178.72]
  };

  static final _mockNVDA = {
    'id': 'stock:NVDA',
    'symbol': 'NVDA',
    'name': 'NVIDIA Corporation',
    'type': 'stock',
    'exchange': 'NASDAQ',
    'sector': 'technology',
    'currency': 'USD',
    'price': 875.3,
    'previousClose': 860.0,
    'change': 15.3,
    'changePercent': 1.78,
    'dayHigh': 882.15,
    'dayLow': 858.4,
    'volume': 45230800,
    'marketCap': 2160000000000,
    'logoUrl': 'https://picsum.photos/seed/nvda/200',
    'sparkline7d': [840.2, 845.6, 852.3, 860, 868.5, 872.1, 875.3]
  };

  static final _mockMSFT = {
    'id': 'stock:MSFT',
    'symbol': 'MSFT',
    'name': 'Microsoft Corporation',
    'type': 'stock',
    'exchange': 'NASDAQ',
    'sector': 'technology',
    'currency': 'USD',
    'price': 415.6,
    'previousClose': 412.35,
    'change': 3.25,
    'changePercent': 0.79,
    'dayHigh': 417.2,
    'dayLow': 411.8,
    'volume': 22145600,
    'marketCap': 3090000000000,
    'logoUrl': 'https://picsum.photos/seed/msft/200',
    'sparkline7d': [408.3, 409.5, 410.8, 412.35, 413.7, 414.9, 415.6]
  };

  List<Map<String, dynamic>> _generateMockInstruments(String type) {
    if (type == 'crypto') return [_mockBTC, _mockETH];
    if (type == 'stocks') return [_mockAAPL, _mockNVDA, _mockMSFT];
    return [_mockBTC, _mockAAPL, _mockETH, _mockNVDA, _mockMSFT];
  }

  Map<String, dynamic> _getMockDetail(String id) {
    final base = _getMockBase(id);
    return {
      ...base,
      'industry': base['type'] == 'stock' ? 'Technology' : null,
      'description': '${base['name']} is a leading ${base['type']} in its sector, known for innovation and market impact.',
      'website': 'https://www.google.com',
      'country': 'US',
      'price': {
        'current': base['price'],
        'previousClose': base['previousClose'],
        'open': (base['price'] as double) * 0.99,
        'dayHigh': base['dayHigh'] ?? (base['price'] as double) * 1.02,
        'dayLow': base['dayLow'] ?? (base['price'] as double) * 0.98,
        'week52High': (base['price'] as double) * 1.2,
        'week52Low': (base['price'] as double) * 0.8,
        'change': base['change'],
        'changePercent': base['changePercent'],
        'lastUpdatedAt': '2025-03-08T14:30:00.000Z',
      },
      'volume': {
        'current': base['volume'] ?? 58432100,
        'average10d': 52100000,
        'average3m': 48700000,
      },
      'fundamentals': {
        'marketCap': base['marketCap'] ?? 2780000000000,
        'enterpriseValue': 2850000000000.0,
        'peRatio': 28.45,
        'forwardPeRatio': 26.12,
        'pegRatio': 1.85,
        'priceToBook': 45.2,
        'priceToSales': 7.35,
        'eps': 6.28,
        'dividendYield': 0.55,
        'dividendPerShare': 0.96,
        'beta': 1.24,
        'sharesOutstanding': 15550000000,
        'floatShares': 15480000000,
        'revenue': 383290000000.0,
        'revenueGrowth': 2.07,
        'grossMargin': 45.96,
        'operatingMargin': 30.74,
        'profitMargin': 25.31,
        'earningsDate': '2025-04-24T00:00:00.000Z',
        'exDividendDate': '2025-02-10T00:00:00.000Z',
      },
      'marketStatus': 'open',
      'tradingHours': {
        'timezone': 'America/New_York',
        'regularOpen': '09:30',
        'regularClose': '16:00',
        'preMarketOpen': '04:00',
        'afterHoursClose': '20:00',
      },
      'relatedInstruments': [
        {'id': 'stock:MSFT', 'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'changePercent': 0.79},
        {'id': 'stock:GOOGL', 'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'changePercent': 1.23},
      ],
      'technicals': [
        {'label': '1 Min.', 'signal': 'Unlock', 'color': 'gray', 'isLocked': true},
        {'label': '5 Min.', 'signal': 'Unlock', 'color': 'gray', 'isLocked': true},
        {'label': '15 Min.', 'signal': 'Unlock', 'color': 'gray', 'isLocked': true},
        {'label': '30 Min.', 'signal': 'Strong Bearish', 'color': 'red', 'isLocked': false},
        {'label': 'Hourly', 'signal': 'Strong Bearish', 'color': 'red', 'isLocked': false},
        {'label': 'Daily', 'signal': 'Neutral', 'color': 'gray', 'isLocked': false},
        {'label': 'Weekly', 'signal': 'Strong Bullish', 'color': 'green', 'isLocked': false},
        {'label': 'Monthly', 'signal': 'Strong Bullish', 'color': 'green', 'isLocked': false},
      ],
      'contracts': [
        {'month': 'Jan 26', 'price': 109.935, 'change': -5.145, 'volume': 5},
        {'month': 'Feb 26', 'price': 109.935, 'change': -5.145, 'volume': 5},
        {'month': 'Mar 26', 'price': 112.165, 'change': -3.339, 'volume': 78867},
      ],
      'comments': [
        {'user': 'Alex Trader', 'time': '2h ago', 'text': 'Bullish on this technical setup. Targeting the 170 resistance level.', 'avatar': 'https://i.pravatar.cc/150?u=alex'},
        {'user': 'Market Watcher', 'time': '4h ago', 'text': 'Wait for the hourly confirmation before jumping in.', 'avatar': 'https://i.pravatar.cc/150?u=market'},
      ],
    };
  }

  Map<String, dynamic> _getMockBase(String id) {
    if (id.contains('BTC')) return _mockBTC;
    if (id.contains('ETH')) return _mockETH;
    if (id.contains('AAPL')) return _mockAAPL;
    if (id.contains('NVDA')) return _mockNVDA;
    if (id.contains('MSFT')) return _mockMSFT;
    return _mockAAPL;
  }
}
