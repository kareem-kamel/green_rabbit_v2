import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/typing_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:green_rabbit/features/chatbot/data/models/chat_message_model.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import 'package:green_rabbit/shared/widgets/feature_guide_overlay.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  bool _clearedOnOpen = false;
  bool _initialPromptSent = false;
  bool _autoScroll = true;
  bool _scrollScheduled = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  // Local state for summary params, so we can clear after use
  String? _pendingSummaryId;
  String? _pendingSummaryType;
  String? _pendingSummaryUrl;
  // Selected image for attachment
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    if (widget.initialPrompt != null) {
      _textController.text = widget.initialPrompt!;
    } else if (widget.summaryId != null && widget.summaryType != null) {
      _textController.text = "Summarize this news article";
      _pendingSummaryId = widget.summaryId;
      _pendingSummaryType = widget.summaryType;
      _pendingSummaryUrl = widget.summaryUrl;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _textController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startRecordingTimer() {
    setState(() => _recordingSeconds = 0);
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _recordingSeconds++);
      }
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() => _recordingSeconds = 0);
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
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
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          _scrollToBottom();
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<ChatCubit>().clearError();
        }
        // Handle timer based on listening state
        if (state.isListening && _recordingTimer == null) {
          _startRecordingTimer();
        } else if (!state.isListening && _recordingTimer != null) {
          _stopRecordingTimer();
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

        // Don't auto-send initial prompt; leave it in text field for user to edit
        // Don't auto-summarize either; let user edit and send first

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
                if (!state.isVoiceMode) _buildInputArea(context, cubit, state),
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
          icon: Icons.help_outline,
          size: 18,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => FeatureGuideOverlay(
                type: GuideType.ai,
                onDismiss: () => Navigator.pop(context),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
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

  Widget _buildRabbitLogo({double size = 80}) { // Reduced from 96
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        'assets/ai.png',
        fit: BoxFit.contain,
        width: size,
        height: size,
        isAntiAlias: true,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildAIGreetingBubble(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.15)),
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
        color: AppColors.primaryPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              _SparkIcon(size: 14, color: AppColors.primaryPurple),
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
                _textController.text = s["query"]!;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primaryPurple.withOpacity(0.1),
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
          color: AppColors.primaryPurple.withOpacity(0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: AppColors.primaryPurple.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: const TypingIndicator(showText: true),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryPurple,
                AppColors.primaryPurple.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.imagePath != null) ...[
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.file(
                    File(msg.imagePath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              if (msg.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: MarkdownBody(
                    data: msg.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final isError = _isErrorMessage(msg);
    final isPlanError = isError && (msg.content.toLowerCase().contains('current plan') || msg.content.toLowerCase().contains('free trial'));
    final isEndedByUser = msg.content.contains('(Response ended by the user)');

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
                  : (isEndedByUser
                      ? Colors.red.withOpacity(0.08)
                      : AppColors.primaryPurple.withOpacity(0.08)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isError
                    ? Colors.redAccent.withOpacity(0.5)
                    : (isEndedByUser
                        ? Colors.redAccent.withOpacity(0.6)
                        : AppColors.primaryPurple.withOpacity(0.15)),
                width: isEndedByUser ? 2 : 1,
              ),
            ),
            child: msg.content.isEmpty && isLastGenerating
                ? const TypingIndicator(showText: true)
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
          ] else if (isError) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.read<ChatCubit>().retryLastMessage(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Retry",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          _buildRabbitLogo(size: 120),
          const SizedBox(height: 40),
          
          // Live Transcription Area
          Container(
            height: 120,
            alignment: Alignment.center,
            child: state.isListening
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Listening...",
                            style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(_recordingSeconds),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            state.speechText.isEmpty ? "Say something..." : state.speechText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  )
                : state.isGenerating
                    ? Column(
                        children: [
                          const TypingIndicator(),
                          const SizedBox(height: 12),
                          const Text(
                            "AI is thinking...",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      )
                    : const Text(
                        "Tap the microphone to speak",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
          ),
          
          const Spacer(),
          
          // Large Microphone Button
          GestureDetector(
            onTap: () {
              if (state.isListening) {
                cubit.stopListening();
              } else if (!state.isGenerating) {
                cubit.startListening();
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (state.isListening)
                  const _VoiceRipple(),
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: state.isListening
                          ? [AppColors.primaryPurple, AppColors.primaryPurple.withOpacity(0.6)]
                          : [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    state.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 60),
          
          // Close Voice Mode Button
          TextButton.icon(
            onPressed: () => cubit.toggleVoiceMode(false),
            icon: const Icon(Icons.keyboard_outlined, color: Colors.white54),
            label: const Text("Switch to Text Mode", style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(height: 40),
        ],
      ),
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
          if (_selectedImage != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImage!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      setState(() {
                        _selectedImage = image;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 50,
                      maxHeight: 150,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: state.isListening 
                          ? const Color(0xFF8B5CF6).withOpacity(0.3) 
                          : Colors.white.withOpacity(0.08)
                      ),
                    ),
                    child: state.isListening
                        ? Row(
                            children: [
                              const _PulseIcon(),
                              const SizedBox(width: 10),
                              Text(
                                _formatDuration(_recordingSeconds),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.speechText.isEmpty ? "Listening..." : state.speechText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => cubit.stopListening(submit: false),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  minLines: 1,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                ),
                              ),
                              GestureDetector(
                                onTap: state.isGenerating ? null : () => cubit.startListening(),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                                  child: Icon(
                                    Icons.mic_none, 
                                    color: state.isGenerating ? Colors.grey : const Color(0xFF8B5CF6), 
                                    size: 22
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: state.isListening
                      ? () => cubit.stopListening(submit: true)
                      : (state.isGenerating
                          ? () => cubit.stopGenerating()
                          : () => _handleSend(cubit)),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isListening 
                          ? const Color(0xFF8B5CF6)
                          : (state.isGenerating
                              ? Colors.redAccent.withOpacity(0.9)
                              : const Color(0xFF8B5CF6)),
                    ),
                    child: state.isListening
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                        : (state.isGenerating
                            ? const Icon(Icons.stop_rounded, color: Colors.white, size: 20)
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
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
    if (text.isNotEmpty || _selectedImage != null) {
      if (_pendingSummaryId != null && _pendingSummaryType != null) {
        // We have pending summary params, call summarize
        cubit.summarize(_pendingSummaryId!, _pendingSummaryType!, url: _pendingSummaryUrl);
        // Clear the pending params so next time it's a normal send
        _pendingSummaryId = null;
        _pendingSummaryType = null;
        _pendingSummaryUrl = null;
      } else {
        // Normal send message
        cubit.sendMessage(
          text,
          imagePath: _selectedImage?.path,
        );
      }
      _textController.clear();
      setState(() {
        _selectedImage = null;
      });
    }
  }
}

// _RabbitAIIcon kept previously is no longer used after switching to sparkles.

class _VoiceRipple extends StatefulWidget {
  const _VoiceRipple();

  @override
  State<_VoiceRipple> createState() => _VoiceRippleState();
}

class _VoiceRippleState extends State<_VoiceRipple> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildRipple(1.0 + (_controller.value * 0.5), 1.0 - _controller.value),
            _buildRipple(1.0 + ((_controller.value + 0.5) % 1.0 * 0.5), 1.0 - ((_controller.value + 0.5) % 1.0)),
          ],
        );
      },
    );
  }

  Widget _buildRipple(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryPurple.withOpacity(opacity * 0.5), width: 2),
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  const _PulseIcon();

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.primaryPurple,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SparkIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _SparkIcon({this.size = 20, this.color = AppColors.primaryPurple});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      size: size,
      color: color,
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