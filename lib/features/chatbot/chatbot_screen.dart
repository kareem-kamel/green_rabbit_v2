import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isGenerating;
  final bool hasChart;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isGenerating = false,
    this.hasChart = false,
  });
}

class ChatHistory {
  final String title;
  final bool isActive;

  const ChatHistory({required this.title, this.isActive = false});
}

// ─────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────
class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isVoiceMode = false;
  bool _hasMessages = false; // false = show empty/suggestion state
  bool _isGenerating = false;
  int _creditsUsed = 5;
  int _totalCredits = 5;

  // ── Dummy chat sessions in sidebar
  final List<ChatHistory> _chatHistories = [
    ChatHistory(title: "Intel Stock", isActive: true),
    ChatHistory(title: "Apple go vi"),
    ChatHistory(title: "Apple in market"),
    ChatHistory(title: "Nividia Up"),
    ChatHistory(title: "Apple"),
    ChatHistory(title: "Apple"),
    ChatHistory(title: "Apple"),
  ];

  // ── Messages shown in chat view
  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hello ! there", isUser: true),
    ChatMessage(text: "Hello there! How may I assist you today?", isUser: false),
    ChatMessage(
        text: "I'm looking for a name that reflects adventure and exploration.",
        isUser: true),
    ChatMessage(
        text:
            'How about the name "VentureQuest"? It combines the sense of adventure with a quest for this ..',
        isUser: false),
    ChatMessage(
        text: "I want a name that sounds elegant and timeless.", isUser: true),
    ChatMessage(
        text:
            'How about the name "Seraphina Grace"? It exudes elegance and has a timeless quality. If you\'d like more suggestions or have specific preferences, feel free to let me know Tra|',
        isUser: false,
        isGenerating: true,
        hasChart: true),
  ];

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.scaffoldBg,
      drawer: _buildSidebar(),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isVoiceMode
                ? _buildVoiceInterface()
                : (_hasMessages ? _buildChatHistory() : _buildEmptyState()),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.scaffoldBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Chatbot AI",
        style: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.smart_toy, color: Colors.white),
          onPressed: () {
            // AI assistant quick action (add behavior as needed)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('AI Assistant opened'),
              duration: Duration(milliseconds: 700),
            ));
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_note, color: Colors.white),
          onPressed: () {
            // Start new chat → go back to empty state
            setState(() {
              _hasMessages = false;
              _isVoiceMode = false;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  SIDEBAR
  // ─────────────────────────────────────────────
  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFF131517),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search..",
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // New Chat button
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.white),
              title: const Text("New Chat",
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(context); // close drawer
                setState(() {
                  _hasMessages = false;
                  _isVoiceMode = false;
                });
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child:
                  Text("Your Chats", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),

            // Chat history list
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistories.length,
                itemBuilder: (context, index) {
                  return _sidebarItem(_chatHistories[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(ChatHistory chat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: chat.isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          chat.title,
          style: TextStyle(
            color: chat.isActive ? Colors.white : Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: chat.isActive
            ? const Icon(Icons.more_horiz, color: Colors.grey, size: 18)
            : null,
        onTap: () {
          Navigator.pop(context);
          setState(() => _hasMessages = true);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  EMPTY / SUGGESTION STATE  (Image 1)
  // ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Purple rabbit logo circle
          _buildRabbitLogo(),

          const SizedBox(height: 32),

          // AI greeting bubble
          _buildAIGreetingBubble("Hi, you can ask me anything about name"),

          const SizedBox(height: 16),

          // Suggestion box
          _buildSuggestionBox(),
        ],
      ),
    );
  }

  Widget _buildRabbitLogo({double size = 110}) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6B4EE6), Color(0xFF3B2A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _buildAIGreetingBubble(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionBox() {
    final List<String> suggestions = [
      "Business names",
      "Human names",
      "Pet names",
      "Dish names",
      "names",
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "I suggest you some names you can ask me..",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((s) => _buildSuggestionChip(s))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        _textController.text = label;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.03),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CHAT HISTORY  (Images 4 & 5)
  // ─────────────────────────────────────────────
  Widget _buildChatHistory() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length + 1, // +1 for credits row
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildCreditsRow();
        }
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      // ── User bubble (right, indigo tint)
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3730A3).withOpacity(0.7),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      );
    }

    // ── AI bubble (left, dark card)
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: msg.hasChart ? 0 : 12, right: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.text,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
              ],
            ),
          ),

          // Stock chart if applicable (Image 5)
          if (msg.hasChart) ...[
            const SizedBox(height: 8),
            _buildInlineChart(),
            const SizedBox(height: 8),
            _buildStopGeneratingButton(),
            const SizedBox(height: 4),
          ],

          // Copy icon for AI messages
          if (!msg.hasChart)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Icon(Icons.copy_outlined,
                  color: Colors.white.withOpacity(0.3), size: 16),
            ),
        ],
      ),
    );
  }

  // ── Inline stock chart bubble (Image 5)
  Widget _buildInlineChart() {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(right: 40),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Y-axis labels + chart area
          Expanded(
            child: CustomPaint(
              painter: _StockChartPainter(),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          // Time range tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["1D", "1W", "1Y", "5Y", "Max"].map((t) {
              bool isActive = t == "1D";
              return Text(
                t,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStopGeneratingButton() {
    return GestureDetector(
      onTap: () => setState(() => _isGenerating = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stop_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text("Stop generating...",
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Credits row (Image 4)
  Widget _buildCreditsRow() {
    bool outOfCredits = _creditsUsed >= _totalCredits;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$_creditsUsed/$_totalCredits Credits Used  ",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (outOfCredits)
            GestureDetector(
              onTap: () {},
              child: const Text(
                "Upgrade to pro",
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  VOICE MODE  (Image 3)
  // ─────────────────────────────────────────────
  Widget _buildVoiceInterface() {
    return Column(
      children: [
        // Top half — logo + greeting + suggestions
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildRabbitLogo(),
                const SizedBox(height: 24),
                _buildAIGreetingBubble("Hi, you can ask me anything about name"),
                const SizedBox(height: 16),
                _buildSuggestionBox(),
              ],
            ),
          ),
        ),

        // Bottom half — voice prompt + mic button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const Text(
                "You can ask me everything about names",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => setState(() => _isVoiceMode = false),
                child: Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: const Icon(Icons.mic,
                      color: Color(0xFF8B5CF6), size: 30),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  BOTTOM INPUT AREA
  // ─────────────────────────────────────────────
  Widget _buildInputArea() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            // Text field container
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: "Ask AI",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (v) => _sendMessage(),
                      ),
                    ),
                    // Mic icon
                    GestureDetector(
                      onTap: () => setState(() => _isVoiceMode = true),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.mic_none,
                            color: Color(0xFF8B5CF6), size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8B5CF6),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SEND MESSAGE LOGIC
  // ─────────────────────────────────────────────
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _hasMessages = true;
      _messages.add(ChatMessage(text: text, isUser: true));
      _textController.clear();
      _isGenerating = true;
      _creditsUsed = (_creditsUsed + 1).clamp(0, _totalCredits);
    });

    // Simulate AI response after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _messages.add(const ChatMessage(
          text: "I'm here to help! What else would you like to explore?",
          isUser: false,
        ));
      });
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }
}

// ─────────────────────────────────────────────
//  CUSTOM CHART PAINTER  (mimics Image 5)
// ─────────────────────────────────────────────
class _StockChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B4EE6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6B4EE6).withOpacity(0.3),
          const Color(0xFF6B4EE6).withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Normalised Y values (0=bottom, 1=top)
    final points = [
      0.85, 0.45, 0.55, 0.30, 0.60, 0.40, 0.55, 0.65, 0.50, 0.45, 0.70,
    ];

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    final lastX = size.width;
    final lastY = size.height * (1 - points.last);
    fillPath.lineTo(lastX, lastY);
    fillPath.lineTo(lastX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Dotted horizontal reference line at ~112k mark
    final dottedPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dashY = size.height * 0.35;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, dashY), Offset(x + 6, dashY), dottedPaint);
      x += 12;
    }

    // Y-axis labels
    final textStyle = const TextStyle(color: Colors.grey, fontSize: 9);
    final labels = ["117.000", "114.000", "112.000", "110.000", "108.000", "105.000"];
    for (int i = 0; i < labels.length; i++) {
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(0, size.height * i / (labels.length - 1) - 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}