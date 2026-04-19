import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_message_model.dart';
import '../../services/chatbot_service.dart';
import '../../widgets/chat_bubble.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _primary = Color(0xFF1A6B3C);
const _accent  = Color(0xFF25A05B);
const _white   = Colors.white;
const _bg      = Color(0xFFF5F6F8);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  String? _userLocation;

  static const List<Map<String, String>> _quickSuggestions = [
    {'icon': '🛡️', 'label': 'Safety tips'},
    {'icon': '🏖️', 'label': 'Best places in Kerala'},
    {'icon': '🍛', 'label': 'Food near me'},
    {'icon': '🏨', 'label': 'Hotels near me'},
    {'icon': '🗺️', 'label': 'Travel advice'},
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text:
            'Hello 👋 I am TravelShield AI, your Kerala travel assistant!\n\nI can help you with:\n• 🛡️ Safety tips & emergency guidance\n• 🏖️ Best places to visit\n• 🍛 Food & restaurant recommendations\n• 🏨 Hotels & homestay suggestions\n• 🗺️ Travel planning advice\n\nAsk me anything about Kerala tourism. Namaskaram! 🙏',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() => _messages.add(message));
    _scrollToBottom();
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

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _inputController.clear();
    _focusNode.unfocus();

    _addMessage(ChatMessage(
      text: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    ));

    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final reply = await ChatbotService.sendMessage(
        message: trimmed,
        location: _userLocation,
      );
      _addMessage(ChatMessage(
        text: reply,
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      ));
    } on ChatbotException catch (e) {
      _addMessage(ChatMessage(
        text: 'Oops! ${e.message}',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } catch (_) {
      _addMessage(ChatMessage(
        text: 'Something went wrong. Please try again later.',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _showLocationDialog() {
    final locationController =
        TextEditingController(text: _userLocation ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: _primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Set Location',
              style: GoogleFonts.urbanist(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: locationController,
          style: GoogleFonts.urbanist(fontSize: 15, color: _dark),
          decoration: InputDecoration(
            hintText: 'e.g. Fort Kochi, Munnar...',
            hintStyle: GoogleFonts.urbanist(color: _light),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
            prefixIcon:
                const Icon(Icons.place_outlined, color: _primary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _userLocation = null);
              Navigator.pop(ctx);
            },
            child: Text('Clear',
                style: GoogleFonts.urbanist(
                    color: _light, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _userLocation =
                    locationController.text.trim().isEmpty
                        ? null
                        : locationController.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: Text('Save',
                style: GoogleFonts.urbanist(
                    color: _white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isTyping) const TypingIndicator(),
          _buildQuickSuggestions(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: _white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // ← Back button to return to dashboard
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: _primary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🛡️', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TravelShield AI',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                ),
                Text(
                  _userLocation != null
                      ? '📍 $_userLocation'
                      : 'Kerala Tourism Assistant',
                  style: GoogleFonts.urbanist(
                    fontSize: 11,
                    color: _light,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _userLocation != null
                    ? const Color(0xFFEEF5F1)
                    : const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _userLocation != null
                    ? Icons.location_on_rounded
                    : Icons.location_off_rounded,
                color: _userLocation != null ? _accent : _light,
                size: 18,
              ),
            ),
            onPressed: _showLocationDialog,
          ),
          const SizedBox(width: 8),
        ],
      );

  // ── Message List ────────────────────────────────────────────────────────────

  Widget _buildMessageList() => ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        itemCount: _messages.length,
        itemBuilder: (_, i) => ChatBubble(message: _messages[i]),
      );

  // ── Quick Suggestions ───────────────────────────────────────────────────────

  Widget _buildQuickSuggestions() {
    if (_messages.length > 1 && !_isTyping) return const SizedBox.shrink();
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _quickSuggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final s = _quickSuggestions[i];
            return GestureDetector(
              onTap: () => _sendMessage(s['label']!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFDDE8E2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s['icon']!,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      s['label']!,
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: _primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Input Bar ───────────────────────────────────────────────────────────────

  Widget _buildInputBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        color: _bg,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.07),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    color: _dark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask about Kerala travel...',
                    hintStyle: GoogleFonts.urbanist(
                        color: _light, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 13),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _sendMessage(_inputController.text),
              child: Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: _white, size: 20),
              ),
            ),
          ],
        ),
      );
}