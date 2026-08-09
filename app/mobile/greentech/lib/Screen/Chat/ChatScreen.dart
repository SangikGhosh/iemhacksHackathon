import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';

import 'package:greentech/Model/Chat.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/LocationService.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  final List<ChatMessage> _messages = [];

  ChatCapabilities _capabilities = ChatCapabilities.disabled;
  String? _conversationId;
  LatLng? _origin;
  bool _loading = true;
  bool _sending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      final has = _input.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _boot();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      final capabilities = await ApiService.chatCapabilities();
      if (mounted) {
        setState(() {
          _capabilities = capabilities;
          _loading = false;
        });
      }
    } on ApiException {
      if (mounted) {
        setState(() {
          _capabilities = ChatCapabilities.disabled;
          _loading = false;
        });
      }
    }

    try {
      _origin = await LocationService.current();
    } on LocationException {
      _origin = null;
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 340),
        curve: uiEase,
      );
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _sending) return;

    _input.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(
        ChatMessage(
          author: ChatAuthor.user,
          content: text,
          toolsUsed: const [],
          createdAt: DateTime.now(),
        ),
      );
      _sending = true;
      _hasText = false;
    });
    _scrollToEnd();

    try {
      final reply = await ApiService.sendChat(
        message: text,
        conversationId: _conversationId,
        latitude: _origin?.latitude,
        longitude: _origin?.longitude,
      );

      if (!mounted) return;
      setState(() {
        _conversationId = reply.conversationId;
        _messages.add(
          ChatMessage(
            author: ChatAuthor.assistant,
            content: reply.reply,
            toolsUsed: reply.toolsUsed,
            createdAt: DateTime.now(),
          ),
        );
        _sending = false;
      });
      _scrollToEnd();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            author: ChatAuthor.assistant,
            content: error.message,
            toolsUsed: const [],
            createdAt: DateTime.now(),
            failed: true,
          ),
        );
        _sending = false;
      });
      _scrollToEnd();
    }
  }

  void _newChat() {
    HapticFeedback.selectionClick();
    setState(() {
      _messages.clear();
      _conversationId = null;
    });
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(sessionProvider).value?.firstName ?? 'there';

    return Scaffold(
      backgroundColor: appBackground,
      appBar: CitizenAppBar(
        title: 'Assistant',
        subtitle: _capabilities.enabled
            ? 'Answers from your real data'
            : 'Currently unavailable',
        onBack: _exit,
        actions: [
          if (_messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Pressable(
                  onTap: _newChat,
                  scale: 0.92,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: uiFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      color: uiInk,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : !_capabilities.enabled
          ? const EmptyState(
              icon: HugeIcons.strokeRoundedSparkles,
              title: 'Assistant is off',
              message:
                  'The assistant is not configured on this server yet. Ask your admin to add an API key.',
            )
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _Welcome(
                          name: name,
                          suggestions: _capabilities.suggestions,
                          onPick: _send,
                        )
                      : ListView.builder(
                          controller: _scroll,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          itemCount: _messages.length + (_sending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _messages.length) {
                              return const _Thinking();
                            }
                            final message = _messages[index];
                            return message.isUser
                                ? _UserTurn(message: message)
                                : _AssistantTurn(message: message);
                          },
                        ),
                ),
                _Composer(
                  controller: _input,
                  focusNode: _focus,
                  sending: _sending,
                  canSend: _hasText,
                  onSend: () => _send(_input.text),
                ),
              ],
            ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.name,
    required this.suggestions,
    required this.onPick,
  });

  final String name;
  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final prompts = suggestions.isEmpty
        ? const [
            'What is my rewards summary?',
            'Show my payment history',
            'Where is the nearest collection point?',
            'What happened to my last pickup?',
          ]
        : suggestions;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF1A73D4), uiGreen],
          ).createShader(bounds),
          child: Text(
            'Hello, $name',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1.2,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'How can I help you today?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: uiInkTertiary,
            letterSpacing: -0.9,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 34),
        for (final prompt in prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Pressable(
              onTap: () => onPick(prompt),
              scale: 0.98,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: uiFill,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: uiInk,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: uiInkTertiary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UserTurn extends StatelessWidget {
  const _UserTurn({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 44),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: uiFill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.45,
              color: uiInk,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantTurn extends StatelessWidget {
  const _AssistantTurn({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantMark(),
          const SizedBox(height: 12),
          Text(
            message.content,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.62,
              color: message.failed ? uiDanger : uiInk,
              letterSpacing: -0.15,
            ),
          ),
          if (message.toolsUsed.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tool in message.toolsUsed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: uiFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tool.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: uiInkTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AssistantMark extends StatelessWidget {
  const _AssistantMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A73D4), uiGreen],
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedSparkles,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'Green Route',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: uiInkSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _Thinking extends StatefulWidget {
  const _Thinking();

  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantMark(),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Row(
              children: [
                for (var index = 0; index < 3; index++)
                  Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                    child: Transform.translate(
                      offset: Offset(0, _bounce(index)),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: uiInkTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _bounce(int index) {
    final phase = (_controller.value * 3 - index * 0.4) % 3;
    if (phase > 1) return 0;
    return -3.5 * (1 - (2 * phase - 1).abs());
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final active = canSend && !sending;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: uiHairlineStrong, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: uiInk.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  cursorColor: uiInk,
                  cursorWidth: 1.8,
                  cursorRadius: const Radius.circular(2),
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.4,
                    color: uiInk,
                    letterSpacing: -0.2,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Ask Green Route',
                    hintStyle: TextStyle(
                      fontSize: 15.5,
                      color: uiInkTertiary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Pressable(
              onTap: active ? onSend : null,
              dimWhenDisabled: false,
              scale: 0.88,
              child: AnimatedContainer(
                duration: uiQuick,
                curve: uiEase,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: active ? uiInk : uiFillStrong,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: uiInkSecondary,
                        ),
                      )
                    : HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowUp01,
                        color: active ? Colors.white : uiInkTertiary,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
