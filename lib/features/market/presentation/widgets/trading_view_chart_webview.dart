import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:green_rabbit/features/chatbot/presentation/screens/chatbot_screen.dart';

class TradingViewChartWebView extends StatefulWidget {
  final String symbol;

  const TradingViewChartWebView({
    super.key,
    required this.symbol,
  });

  @override
  State<TradingViewChartWebView> createState() => _TradingViewChartWebViewState();
}

class _TradingViewChartWebViewState extends State<TradingViewChartWebView> {
  late final WebViewController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
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

    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E1117))
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            controller.runJavaScript("window.loadChart('$cleanSymbol');");
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

    await controller.loadFlutterAsset('assets/tradingview.html');

    if (mounted) {
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
