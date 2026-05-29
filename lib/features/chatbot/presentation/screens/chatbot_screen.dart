import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/typing_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../../../profile/presentation/screens/subscription_screen.dart';

class ChatBotScreen extends StatefulWidget {
  final bool startEmpty;
  final String? initialPrompt;
  final String? summaryId;
  final String? summaryType;
  final String? summaryUrl;

  const ChatBotScreen({
    super.key, 
    this.startEmpty = false,
    this.initialPrompt,
    this.summaryId,
    this.summaryType,
    this.summaryUrl,
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
  bool _autoScroll = true;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    
    final pos = _scrollController.position;
    
    // Use a slightly larger buffer (50px) to detect if the user is NOT at the bottom.
    // Also check if the user is currently touching the screen.
    final atBottom = pos.pixels >= (pos.maxScrollExtent - 50);
    
    if (_autoScroll != atBottom) {
      setState(() {
        _autoScroll = atBottom;
      });
    }
  }

  void _scrollToBottom() {
    if (!_autoScroll || _scrollScheduled) return;

    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_scrollController.hasClients) return;

      final position = _scrollController.position;
      if (!position.hasContentDimensions) return;

      final target = position.maxScrollExtent;
      if (!target.isFinite) return;

      if ((position.pixels - target).abs() > 2) {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, String chatId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Chat', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this chat?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              this.context.read<ChatCubit>().deleteConversation(chatId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      buildWhen: (previous, current) {
        if (previous.isGenerating != current.isGenerating) return true;
        if (previous.messages.length != current.messages.length) return true;
        if (previous.messages.isEmpty || current.messages.isEmpty) return true;
        final prevLast = previous.messages.last;
        final currLast = current.messages.last;
        return prevLast.id != currLast.id || prevLast.content != currLast.content;
      },
      listenWhen: (previous, current) =>
          previous.messages.length != current.messages.length ||
          (current.isGenerating &&
              current.messages.isNotEmpty &&
              previous.messages.lastOrNull?.content !=
                  current.messages.last.content),
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        final cubit = context.read<ChatCubit>();

        // Always clear state if startEmpty is requested on a new screen entry
        if (widget.startEmpty && !_clearedOnOpen && !state.isGenerating) {
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

        if (widget.summaryId != null && widget.summaryType != null && !_initialPromptSent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _initialPromptSent = true;
            cubit.summarize(widget.summaryId!, widget.summaryType!, url: widget.summaryUrl);
          });
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.scaffoldBg,
            drawer: _buildSidebar(context, state),
            appBar: _buildAppBar(context, cubit),
            body: Column(
              children: [
                Expanded(
                  child: state.isVoiceMode
                      ? _buildVoiceInterface(context, cubit, state)
                      : (state.isGenerating && state.messages.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : (state.messages.isNotEmpty
                              ? _buildChatHistory(state)
                              : _buildEmptyState(cubit))),
                ),
                _buildInputArea(context, cubit, state),
              ],
            ),
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
      leading: _buildAppBarIcon(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.pop(context),
      ),
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          "Financial Advisor",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      actions: [
        _buildAppBarIcon(
          icon: Icons.edit_outlined,
          size: 18,
          onTap: () => cubit.startNewChat(),
        ),
        const SizedBox(width: 10),
        _buildAppBarIcon(
          icon: Icons.menu_rounded,
          size: 18,
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAppBarIcon({required IconData icon, double size = 18, required VoidCallback onTap}) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1F26),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size,
          ),
        ),
      ),
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
              leading: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 20,
              ),
              title: const Text("New Chat",
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatCubit>().startNewChat();
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text("Your Chats",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.history.length,
                itemBuilder: (context, index) {
                  final chat = state.history[index];
                  final isActive = state.activeConversationId == chat.id;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey,
                            fontSize: 14,
                          )),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 18),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConfirmation(context, chat.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<ChatCubit>().selectConversation(chat.id);
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
          _buildAIGreetingBubble("Hi, I'm your Financial Advisor. You can ask me anything about markets. \n\n*Note: AI responses are for informational purposes only. We are not responsible for any inaccuracies.*"),
          const SizedBox(height: 16),
          _buildSuggestionBox(cubit),
        ],
      ),
    );
  }

  Widget _buildRabbitLogo({double size = 96}) {
    return SizedBox(
      height: size,
      width: size,
      child: ClipOval(
        child: Image.asset(
          'assets/icons/rabbiticonAI.png',
          fit: BoxFit.cover,
          width: size,
          height: size,
          filterQuality: FilterQuality.high,
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
    final List<Map<String, String>> suggestions = [
      {
        "label": "Top stocks performers",
        "query": "Provide a detailed report on today's top performing stocks and trending market instruments."
      },
      {
        "label": "Commodity Outlook",
        "query": "What is the current outlook for major commodities like Gold, Silver, and Oil in the global market?"
      },
      {
        "label": "Bullish Trends",
        "query": "What are the current bullish trends in the stock market that I should be aware of?"
      },
      {
        "label": "Market Analysis",
        "query": "Provide a comprehensive market analysis for today's trading session."
      },
      {
        "label": "Trading Strategy",
        "query": "Suggest a high-probability trading strategy for the current market conditions."
      },
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
              onTap: () {
                cubit.sendMessage(s["query"]!);
                _textController.clear();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.02),
                ),
                child: Text(s["label"]!, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
    // Filter out internal technical messages (e.g. summary triggers) from the UI
    final visibleMessages = state.messages.where((msg) {
      if (!msg.isUser) return true;
      
      final content = msg.content.trim();
      // Hide if it's just a URL
      if (Uri.tryParse(content)?.hasAbsolutePath ?? false) return false;
      // Hide if it's a UUID/ID or technical trigger
      if (RegExp(r'^[a-fA-F0-9-]{32,50}$').hasMatch(content)) return false;
      if (content.contains('targetId:') || content.contains('entityType:') || 
          content.contains('summaryId:') || content.contains('summaryType:')) {
        return false;
      }
      
      return true;
    }).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: visibleMessages.length + (state.isGenerating ? 2 : 1),
      itemBuilder: (context, index) {
        if (index == visibleMessages.length + (state.isGenerating ? 1 : 0)) {
          return _buildCreditsRow(state);
        }
        if (state.isGenerating && index == visibleMessages.length) {
          // Only show a separate typing bubble if the last message is from the user
          // (meaning the assistant placeholder hasn't been added or is still being prepared)
          if (visibleMessages.isEmpty || visibleMessages.last.isUser) {
            return _buildTypingIndicatorBubble();
          }
          return const SizedBox.shrink();
        }
        
        final msg = visibleMessages[index];
        return _buildMessageBubble(context, msg, state.isGenerating && index == visibleMessages.length - 1);
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

  bool _isErrorMessage(ChatMessage msg) => msg.id.startsWith('err_');

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

    final isError = _isErrorMessage(msg);
    final isPlanError = isError && (msg.content.toLowerCase().contains('current plan') || msg.content.toLowerCase().contains('free trial'));

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: (msg.hasChart || isPlanError) ? 0 : 12, right: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red.withOpacity(0.12)
                  : Colors.white.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: isError
                  ? Border.all(color: Colors.redAccent.withOpacity(0.5))
                  : null,
            ),
            child: msg.content.isEmpty && isLastGenerating
                ? const SizedBox(width: 40, child: TypingIndicator())
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isError) ...[
                        Icon(isPlanError ? Icons.lock_outline : Icons.error_outline,
                            color: isPlanError ? AppColors.premiumGold : Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: MarkdownBody(
                          key: ValueKey('${msg.id}_${msg.content.length}'),
                          data: msg.content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isPlanError ? Colors.white : (isError ? Colors.redAccent[100] : Colors.white),
                              fontSize: 14,
                              height: 1.5,
                            ),
                            strong: TextStyle(
                              color: isPlanError ? Colors.white : (isError ? Colors.redAccent[100] : Colors.white),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (isPlanError) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SubscriptionScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "Activate the Free Trial",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (msg.hasChart) ...[
            const SizedBox(height: 8),
            _buildInlineChart(),
            const SizedBox(height: 4),
          ],
          if (!msg.hasChart && !isError)
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
  Widget _buildVoiceInterface(BuildContext context, ChatCubit cubit, ChatState state) {
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
                if (state.speechText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.speechText,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (!state.isListening && state.speechText.isEmpty) _buildSuggestionBox(cubit),
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
                onTap: () {
                  if (state.isListening) {
                    cubit.stopListening();
                  } else {
                    cubit.startListening();
                  }
                },
                child: Container(
                  height: 64, width: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: state.isListening ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.12), width: 1.5),
                    color: state.isListening ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  ),
                  child: Icon(state.isListening ? Icons.stop : Icons.mic, color: state.isListening ? Colors.redAccent : const Color(0xFF8B5CF6), size: 30),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => cubit.toggleVoiceMode(false),
                child: const Text("Close Voice Mode", style: TextStyle(color: Colors.grey, fontSize: 14)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                              hintText: "Ask Financial Advisor",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            onSubmitted: (v) => _handleSend(cubit),
                          ),
                        ),
                        GestureDetector(
                          onTap: state.isGenerating ? null : () => cubit.toggleVoiceMode(true),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.mic_none, 
                              color: state.isGenerating ? Colors.grey : const Color(0xFF8B5CF6), 
                              size: 20
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: state.isGenerating
                      ? () => cubit.stopGenerating()
                      : () => _handleSend(cubit),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isGenerating
                          ? Colors.redAccent.withOpacity(0.9)
                          : const Color(0xFF8B5CF6),
                    ),
                    child: state.isGenerating
                        ? const Icon(Icons.stop_rounded, color: Colors.white, size: 20)
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              "AI may make mistakes.",
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
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
    return Icon(
      Icons.auto_awesome_rounded,
      size: size,
      color: const Color(0xFF8B5CF6),
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