import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/typing_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class ChatBotScreen extends StatefulWidget {
  final bool startEmpty;
  final String? initialPrompt;

  const ChatBotScreen({
    super.key, 
    this.startEmpty = false,
    this.initialPrompt,
  });

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _clearedOnOpen = false;
  bool _initialPromptSent = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        final cubit = context.read<ChatCubit>();

        if (widget.startEmpty && !_clearedOnOpen) {
          // Ensure empty suggestion state only once on entry
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _clearedOnOpen = true;
            cubit.startNewChat();
          });
        }

        if (widget.initialPrompt != null && !_initialPromptSent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _initialPromptSent = true;
            cubit.sendMessage(widget.initialPrompt!);
          });
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.scaffoldBg,
          drawer: _buildSidebar(context, state),
          appBar: _buildAppBar(context, cubit),
          body: Column(
            children: [
              Expanded(
                child: state.isVoiceMode
                    ? _buildVoiceInterface(context, cubit)
                    : (state.messages.isNotEmpty
                        ? _buildChatHistory(state)
                        : _buildEmptyState(cubit)),
              ),
              _buildInputArea(context, cubit, state),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, ChatCubit cubit) {
    return AppBar(
      backgroundColor: AppColors.scaffoldBg,
      elevation: 0,
      toolbarHeight: 72,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 40),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Chatbot AI",
        style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: Image.asset(
            'assets/icons/editchat.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          onPressed: () => cubit.startNewChat(),
        ),
        IconButton(
          icon: Image.asset(
            'assets/icons/allchat.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  SIDEBAR
  // ─────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context, ChatState state) {
    return Drawer(
      backgroundColor: AppColors.scaffoldBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.white),
              title: const Text("New Chat",
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatCubit>().startNewChat();
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Your Chats", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.history.length,
                itemBuilder: (context, index) {
                  final chat = state.history[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: chat.isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(chat.title,
                          style: TextStyle(
                            color: chat.isActive ? Colors.white : Colors.grey,
                            fontSize: 14,
                          )),
                      trailing: chat.isActive
                          ? const Icon(Icons.more_horiz, color: Colors.grey, size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  EMPTY / SUGGESTION STATE
  // ─────────────────────────────────────────────
  Widget _buildEmptyState(ChatCubit cubit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildRabbitLogo(),
          const SizedBox(height: 32),
          _buildAIGreetingBubble("Hi, you can ask me anything about markets"),
          const SizedBox(height: 16),
          _buildSuggestionBox(cubit),
        ],
      ),
    );
  }

  Widget _buildRabbitLogo({double size = 110}) {
    return SizedBox(
      height: size,
      width: size,
      child: ClipOval(
        child: Image.asset(
          'assets/icons/rabbiticonAI.png',
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      ),
    );
  }

  Widget _buildAIGreetingBubble(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          const _SparkIcon(size: 16),
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

  Widget _buildSuggestionBox(ChatCubit cubit) {
    final List<String> suggestions = [
      "Bullish Trends", "Market Analysis", "Top Stocks", "Crypto News", "Strategy",
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              _SparkIcon(size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Try asking about these...",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: suggestions.map((s) => GestureDetector(
              onTap: () => _textController.text = s,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.02),
                ),
                child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CHAT HISTORY
  // ─────────────────────────────────────────────
  Widget _buildChatHistory(ChatState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: state.messages.length + (state.isGenerating ? 2 : 1),
      itemBuilder: (context, index) {
        if (index == state.messages.length + (state.isGenerating ? 1 : 0)) {
          return _buildCreditsRow(state);
        }
        if (state.isGenerating && index == state.messages.length) {
          // Only show a separate typing bubble if the last message is from the user
          // (meaning the assistant placeholder hasn't been added or is still being prepared)
          final lastMsg = state.messages.last;
          if (lastMsg.isUser) {
            return _buildTypingIndicatorBubble();
          }
          return const SizedBox.shrink();
        }
        
        final msg = state.messages[index];
        return _buildMessageBubble(context, msg, state.isGenerating && index == state.messages.length - 1);
      },
    );
  }

  Widget _buildTypingIndicatorBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
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
        child: const SizedBox(
          width: 40,
          child: TypingIndicator(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg, bool isLastGenerating) {
    if (msg.isUser) {
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
          child: MarkdownBody(
            data: msg.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Colors.white, fontSize: 14),
              strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      );
    }

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
            child: msg.content.isEmpty && isLastGenerating
                ? const SizedBox(width: 40, child: TypingIndicator())
                : MarkdownBody(
                    data: msg.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                      strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      h1: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      h3: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      listBullet: const TextStyle(color: Colors.white70),
                    ),
                  ),
          ),
          if (msg.hasChart) ...[
            const SizedBox(height: 8),
            _buildInlineChart(),
            const SizedBox(height: 8),
            _buildStopGeneratingButton(context),
            const SizedBox(height: 4),
          ],
          if (!msg.hasChart)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Icon(Icons.copy_outlined, color: Colors.white.withOpacity(0.3), size: 16),
            ),
        ],
      ),
    );
  }

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
        children: [
          Expanded(child: CustomPaint(painter: _StockChartPainter(), size: Size.infinite)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["1D", "1W", "1Y", "5Y", "Max"].map((t) => Text(t, 
              style: TextStyle(color: t == "1D" ? Colors.white : Colors.grey, fontSize: 11))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStopGeneratingButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ChatCubit>().stopGenerating(),
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
            Text("Stop generating...", style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsRow(ChatState state) {
    bool outOfCredits = state.creditsUsed >= state.totalCredits;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("${state.creditsUsed}/${state.totalCredits} Credits Used  ",
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (outOfCredits)
            const Text("Upgrade to pro",
                style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  VOICE MODE
  // ─────────────────────────────────────────────
  Widget _buildVoiceInterface(BuildContext context, ChatCubit cubit) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildRabbitLogo(),
                const SizedBox(height: 24),
                _buildAIGreetingBubble("I'm listening... Ask me anything"),
                const SizedBox(height: 16),
                _buildSuggestionBox(cubit),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const Text("Voice Mode Active",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => cubit.toggleVoiceMode(false),
                child: Container(
                  height: 64, width: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: const Icon(Icons.mic, color: Color(0xFF8B5CF6), size: 30),
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
  Widget _buildInputArea(BuildContext context, ChatCubit cubit, ChatState state) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
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
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (v) => _handleSend(cubit),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => cubit.toggleVoiceMode(true),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.mic_none, color: Color(0xFF8B5CF6), size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: state.isGenerating ? null : () => _handleSend(cubit),
              child: Container(
                height: 48, width: 48,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8B5CF6)),
                child: state.isGenerating 
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend(ChatCubit cubit) {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      cubit.sendMessage(text);
      _textController.clear();
    }
  }
}

// _RabbitAIIcon kept previously is no longer used after switching to sparkles.

class _SparkIcon extends StatelessWidget {
  final double size;
  const _SparkIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/sparkles-sharp.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

// ─────────────────────────────────────────────
//  CUSTOM CHART PAINTER
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
        colors: [const Color(0xFF6B4EE6).withOpacity(0.3), const Color(0xFF6B4EE6).withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final points = [0.85, 0.45, 0.55, 0.30, 0.60, 0.40, 0.55, 0.65, 0.50, 0.45, 0.70];
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
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}