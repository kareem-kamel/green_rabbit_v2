import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:green_rabbit/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TradingViewChartWebView extends StatefulWidget {
  final String symbol;

  const TradingViewChartWebView({
    super.key,
    required this.symbol,
  });

  @override
  State<TradingViewChartWebView> createState() => _TradingViewChartWebViewState();
}

class _TradingViewChartWebViewState extends State<TradingViewChartWebView> with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _saveCurrentDrawings();
    super.dispose();
  }

  Future<void> _saveCurrentDrawings() async {
    try {
      if (_isInitialized) {
        await _controller.runJavaScript("window.saveDrawings();");
      }
    } catch (e) {
      // Ignore if controller is already disposed or javascript fails
    }
  }

  Future<void> _initWebView() async {
    // Clean and format the symbol for TradingView search.
    // If it's a forex pair or crypto e.g. BTC/USD, we replace slashes.
    String cleanSymbol = widget.symbol.replaceAll('/', '').replaceAll('-', '').toUpperCase();
    
    // Let's provide fallback or direct conversions for specific commodities or standard symbols if needed.
    if (cleanSymbol == 'CL') {
      // Crude oil futures on TradingView usually need exchange prefix or future ticker
      cleanSymbol = 'NYMEX:CL1!';
    } else if (cleanSymbol == 'XAUUSD') {
      cleanSymbol = 'OANDA:XAUUSD';
    }

    final cachedController = WebViewControllerCache.get(cleanSymbol);
    if (cachedController != null) {
      _controller = cachedController;
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      return;
    }

    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E1117))
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
      ..addJavaScriptChannel(
        'Logger',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("🌐 [TradingView JS LOG]: ${message.message}");
        },
      )
      ..addJavaScriptChannel(
        'DrawingSaver',
        onMessageReceived: (JavaScriptMessage message) async {
          try {
            final jsonStr = message.message;
            debugPrint("📊 [TradingView Flutter]: DrawingSaver channel received message of length: ${jsonStr.length}");
            if (jsonStr.isNotEmpty && jsonStr != '{}') {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('tradingview_drawings', jsonStr);
              debugPrint("💾 [TradingView Flutter]: Saved drawings successfully to SharedPreferences.");
            }
          } catch (e) {
            debugPrint("❌ [TradingView Flutter]: Failed to save drawings to SharedPreferences: $e");
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            try {
              final prefs = await SharedPreferences.getInstance();
              final savedData = prefs.getString('tradingview_drawings');
              debugPrint("🔄 [TradingView Flutter]: onPageFinished. Read saved drawings from SharedPreferences: ${savedData != null ? 'Length: ${savedData.length}' : 'null'}");
              if (savedData != null && savedData.isNotEmpty) {
                final base64Data = base64Encode(utf8.encode(savedData));
                await controller.runJavaScript("window.restoreDrawings('$base64Data');");
              }
            } catch (e) {
              debugPrint("❌ [TradingView Flutter]: Failed to restore drawings: $e");
            }
            await controller.runJavaScript("window.loadChart('$cleanSymbol');");
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            // Only intercept and redirect screenshot links (containing '/x/') 
            // to the external browser, allowing all other scripts, iframes, and assets to load.
            if (url.contains('tradingview.com/x/')) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    final htmlContent = await rootBundle.loadString('assets/tradingview.html');
    await controller.loadHtmlString(htmlContent, baseUrl: 'https://www.tradingview.com');

    WebViewControllerCache.put(cleanSymbol, controller);

    if (mounted) {
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E1117),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(
          controller: _controller,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),
        // Custom overlay circular button to mask the TradingView TV logo and display the Green Rabbit AI logo
        Positioned(
          left: 65,
          bottom: 44,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatBotScreen(startEmpty: true),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF131722), // Matching the TradingView dark theme background
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/ai.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WebViewControllerCache {
  static final Map<String, WebViewController> _cache = {};
  static final List<String> _history = [];
  static const int _maxCacheSize = 5;

  static WebViewController? get(String symbol) {
    if (_cache.containsKey(symbol)) {
      _history.remove(symbol);
      _history.add(symbol);
      return _cache[symbol];
    }
    return null;
  }

  static void put(String symbol, WebViewController controller) {
    if (_cache.length >= _maxCacheSize) {
      final oldest = _history.removeAt(0);
      _cache.remove(oldest);
    }
    _cache[symbol] = controller;
    _history.add(symbol);
  }

  static void clear() {
    _cache.clear();
    _history.clear();
  }
}
