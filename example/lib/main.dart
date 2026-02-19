import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:anchored_paginated_list/anchored_paginated_list.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

void main() => runApp(const ChatApp());

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF00796B),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF00796B),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message model
// ─────────────────────────────────────────────────────────────────────────────

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = 'text',
  });

  final int id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String type;

  bool get isMe => senderId == 'me';
}

// ─────────────────────────────────────────────────────────────────────────────
// Simulated chat database — 200 messages, IDs 1–200
// ─────────────────────────────────────────────────────────────────────────────

class ChatDatabase {
  ChatDatabase._();

  static const totalMessages = 10000;

  /// Base time: messages start from this point, ~7 min apart.
  static final _baseTime = DateTime(2024, 1, 1, 0, 0);

  /// A realistic conversation script that cycles for 200 messages.
  /// Each entry: (senderId, text).
  static const _script = <(String, String)>[
    // ── Morning greeting ──
    ('them', 'Good morning! Did you sleep well?'),
    ('me', 'Morning! Yeah not bad, though the cat woke me up at 5am again'),
    (
      'them',
      'Haha sounds about right. Cats have zero respect for sleep schedules'
    ),
    ('me', 'Zero. She was literally sitting on my face meowing for breakfast'),
    ('them', 'Classic cat behavior honestly'),
    ('me', 'Anyway, what are you up to today?'),
    (
      'them',
      'Not much, was thinking of going to that new farmer\'s market '
          'downtown. Want to come?'
    ),
    (
      'me',
      'Oh yeah I heard about that! It opened last weekend right? '
          'I\'m down, what time were you thinking?'
    ),
    ('them', 'Around 10? We could grab brunch after'),
    ('me', 'Perfect, I know a great spot near there'),

    // ── Food & brunch ──
    ('them', 'Which place? That Thai restaurant on Main St?'),
    (
      'me',
      'No, there\'s this new brunch place called The Morning After. '
          'They have insane avocado toast and really good cold brew'
    ),
    ('them', 'Avocado toast? Are we basic now?'),
    (
      'me',
      'Hey don\'t knock it till you try it. This one has poached eggs, '
          'chili flakes, and some kind of fancy seed mix on top'
    ),
    ('them', 'OK fine that does sound amazing'),
    ('me', 'Trust me, it\'s worth it'),

    // ── Work discussion ──
    ('them', 'By the way, how did that meeting go yesterday?'),
    ('me', 'Which one? I had like four'),
    ('them', 'The one about the new project'),
    (
      'me',
      'Oh that one went well actually! They approved the budget so '
          'we\'re good to start next month. I\'m pretty excited about it'
    ),
    ('them', 'That\'s awesome! What\'s the project about again?'),
    (
      'me',
      'We\'re building a new mobile app for the company. Cross-platform '
          'with Flutter. Should be interesting since none of us have used '
          'it before'
    ),
    (
      'them',
      'Flutter is great, I used it for a side project last year. '
          'The hot reload alone is worth it'
    ),
    ('me', 'Yeah that\'s what I keep hearing. Any tips for getting started?'),
    (
      'them',
      'Start with the official codelabs, they\'re really well done. '
          'And the docs are surprisingly good'
    ),
    ('me', 'Will do, thanks!'),

    // ── Weekend plans ──
    ('them', 'So what else are you doing this weekend?'),
    (
      'me',
      'Thinking about going for a hike on Sunday if the weather holds up. '
          'Maybe the trail by the lake'
    ),
    (
      'them',
      'Oh that\'s a nice one! I did it last month, took about 3 hours '
          'round trip'
    ),
    ('me', 'That\'s perfect. Not too long, not too short'),
    ('them', 'Bring water though, there\'s no shade for the first mile'),
    ('me', 'Good to know. Want to join?'),
    (
      'them',
      'I wish I could but I promised my mom I\'d help her move some '
          'furniture'
    ),
    ('me', 'No worries, next time!'),

    // ── Movie recommendation ──
    ('them', 'Hey have you watched anything good lately?'),
    (
      'me',
      'Actually yes! I just finished this documentary about deep sea '
          'creatures. It was mind-blowing'
    ),
    ('them', 'What\'s it called?'),
    (
      'me',
      'The Abyss Within. It\'s on that streaming service, the one with '
          'the blue logo'
    ),
    ('them', 'Adding it to my list. I need something to watch tonight'),
    (
      'me',
      'You won\'t regret it. There\'s this one scene with a '
          'bioluminescent jellyfish that\'s absolutely stunning. Like '
          'something from another planet'
    ),
    ('them', 'Sold. I\'m watching it tonight'),

    // ── Tech talk ──
    ('me', 'Oh btw, did you see the new phone announcement?'),
    ('them', 'The one with the crazy camera?'),
    (
      'me',
      'Yeah! 200 megapixels. I don\'t even know what I\'d do with that '
          'many pixels'
    ),
    (
      'them',
      'Take really detailed photos of your cat sitting on your face '
          'at 5am'
    ),
    ('me', 'LOL fair point'),
    (
      'them',
      'But seriously, phone cameras have gotten insane. I took some '
          'photos at sunset last week that looked professional'
    ),
    ('me', 'The computational photography stuff is wild'),
    (
      'them',
      'Right? Night mode especially. Remember when phone photos in the '
          'dark were just... noise?'
    ),
    ('me', 'Dark ages. Literally'),

    // ── Fitness ──
    (
      'them',
      'Speaking of outdoors, have you been keeping up with your running?'
    ),
    (
      'me',
      'Trying to! Did 5K yesterday morning. Slowly building up to 10K '
          'by next month'
    ),
    ('them', 'Nice! What\'s your pace like?'),
    (
      'me',
      'About 6 minutes per km. Nothing impressive but I\'m consistent '
          'at least'
    ),
    (
      'them',
      'Consistency is everything. I read somewhere that running 3 times '
          'a week is better than running 6 times one week and zero the next'
    ),
    ('me', 'That makes sense. I\'m doing Mon/Wed/Sat right now'),
    ('them', 'Smart schedule. Rest days are important'),
  ];

  /// Returns a deterministic message for the given [id] (1-based).
  static Message getMessage(int id) {
    final scriptIndex = (id - 1) % _script.length;
    final entry = _script[scriptIndex];
    final timestamp = _baseTime.add(Duration(minutes: (id - 1) * 7));
    return Message(
      id: id,
      senderId: entry.$1,
      text: entry.$2,
      timestamp: timestamp,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incoming message pool — for auto-arriving messages (id > 200)
// ─────────────────────────────────────────────────────────────────────────────

const _incomingPool = <String>[
  'Just thinking about what to have for dinner...',
  'Did you finish that thing you were working on?',
  'Check out this song I just found, it\'s amazing',
  'I can\'t believe how fast this year is going',
  'Want to play some games later?',
  'My cat just knocked over my water glass again',
  'Btw did you see the weather forecast? Rain all week',
  'I found the best coffee shop near the office',
  'Running late today, traffic is insane',
  'Have you tried that new restaurant on Oak Street?',
  'I just saw the funniest video, remind me to show you',
  'Do you think we should plan a trip this summer?',
  'I\'m so tired, stayed up way too late last night',
  'The sunset right now is incredible, wish you could see it',
  'Just got back from the gym, absolutely destroyed',
];

// ─────────────────────────────────────────────────────────────────────────────
// Chat screen — main widget
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controllers
  final _listController = AnchoredPaginatedListController();
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  // Message state — stored newest-first (index 0 = newest, at bottom).
  //
  // The loaded window is bounded by [_oldestLoadedId, _newestLoadedId].
  // Pagination extends these edges. Search *replaces* the window entirely.
  List<Message> _messages = [];
  int _oldestLoadedId = 0;
  int _newestLoadedId = 0;

  int _nextOutgoingId = ChatDatabase.totalMessages + 1;
  bool _isAtBottom = true;
  int _unreadCount = 0;
  int _incomingIndex = 0;

  // Visible range for pagination debugging
  String _visibleRangeText = '';

  // Timers
  Timer? _incomingTimer;
  final _random = Random();

  bool get _hasMoreOlder => _oldestLoadedId > 1;
  bool get _hasMoreNewer => _newestLoadedId < _latestMessageId;

  /// The highest message ID that exists (DB + incoming/sent).
  int get _latestMessageId => _nextOutgoingId - 1;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _scrollController.addListener(_onScroll);
    _scheduleNextIncoming();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateVisibleRange();
    });
  }

  @override
  void dispose() {
    _incomingTimer?.cancel();
    _listController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  void _loadInitialMessages() {
    // Load the last 200 messages (IDs 9801–10000), stored newest-first.
    const initialCount = 200;
    final startId = ChatDatabase.totalMessages - initialCount + 1;
    final msgs = <Message>[];
    for (var id = ChatDatabase.totalMessages; id >= startId; id--) {
      msgs.add(ChatDatabase.getMessage(id));
    }
    _messages = msgs;
    _oldestLoadedId = startId;
    _newestLoadedId = ChatDatabase.totalMessages;
  }

  Future<void> _onLoadMore(LoadDirection direction) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (direction == LoadDirection.forward && _hasMoreOlder) {
      // ── Load OLDER messages (forward = toward the scroll end in reverse) ──
      // Always extend from _oldestLoadedId — the CURRENT window's lower edge.
      final batchSize = (_oldestLoadedId - 1).clamp(0, 50);
      if (batchSize <= 0) return;

      final newOldestId = _oldestLoadedId - batchSize;
      final older = <Message>[];
      for (var id = _oldestLoadedId - 1; id >= newOldestId; id--) {
        older.add(ChatDatabase.getMessage(id));
      }

      setState(() {
        // Append at the END (top visually in reversed list). This does NOT
        // shift the viewport, so no scroll anchoring is needed.
        _messages = [..._messages, ...older];
        _oldestLoadedId = newOldestId;
      });
    } else if (direction == LoadDirection.backward && _hasMoreNewer) {
      // ── Load NEWER messages (backward = toward scroll start in reverse) ──
      // Extend from _newestLoadedId — the CURRENT window's upper edge.
      final maxId = _latestMessageId;
      final batchSize = (maxId - _newestLoadedId).clamp(0, 50);
      if (batchSize <= 0) return;

      final newNewestId = _newestLoadedId + batchSize;
      final newer = <Message>[];
      for (var id = _newestLoadedId + 1; id <= newNewestId; id++) {
        if (id <= ChatDatabase.totalMessages) {
          newer.add(ChatDatabase.getMessage(id));
        }
      }
      // Also include any session messages (id > totalMessages) in range
      for (final m in _sessionMessages) {
        if (m.id > _newestLoadedId && m.id <= newNewestId) {
          newer.add(m);
        }
      }
      // Sort newest-first to prepend
      newer.sort((a, b) => b.id.compareTo(a.id));

      setState(() {
        // Prepend at the START (bottom visually in reversed list).
        _messages = [...newer, ..._messages];
        _newestLoadedId = newNewestId;
      });
    }
  }

  /// Messages created during the session (sent + incoming) that live
  /// outside the DB. Kept so backward pagination can find them.
  final List<Message> _sessionMessages = [];

  // ── Incoming messages ─────────────────────────────────────────────────────

  void _scheduleNextIncoming() {
    final delay = 4000 + _random.nextInt(3000); // 4–7 seconds
    _incomingTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      _addIncomingMessage();
      _scheduleNextIncoming();
    });
  }

  void _addIncomingMessage() {
    final text = _incomingPool[_incomingIndex % _incomingPool.length];
    _incomingIndex++;

    final msg = Message(
      id: _nextOutgoingId++,
      senderId: 'them',
      text: text,
      timestamp: DateTime.now(),
    );

    _sessionMessages.add(msg);

    // Only prepend if we're viewing the latest window (no gap to newest).
    if (_newestLoadedId == msg.id - 1) {
      setState(() {
        _messages = [msg, ..._messages];
        _newestLoadedId = msg.id;
        if (!_isAtBottom) {
          _unreadCount++;
        }
      });

      if (_isAtBottom) {
        _jumpToBottom();
      }
    } else {
      // We're viewing an older window — don't disrupt it, just count.
      setState(() {
        _unreadCount++;
      });
    }
  }

  // ── Send message ──────────────────────────────────────────────────────────

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final msg = Message(
      id: _nextOutgoingId++,
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
    );

    _textController.clear();
    _sessionMessages.add(msg);

    // If viewing an older window, jump back to latest first.
    if (_newestLoadedId < msg.id - 1) {
      _jumpToLatestWindow(thenJumpToBottom: true);
      // Insert after window loads
      setState(() {
        _messages = [msg, ..._messages];
        _newestLoadedId = msg.id;
        _isAtBottom = true;
        _unreadCount = 0;
      });
    } else {
      setState(() {
        _messages = [msg, ..._messages];
        _newestLoadedId = msg.id;
        _isAtBottom = true;
        _unreadCount = 0;
      });
    }

    _jumpToBottom();
  }

  /// Replaces the current window with the latest messages (go back to
  /// "home" view).
  void _jumpToLatestWindow({bool thenJumpToBottom = false}) {
    const windowSize = 200;
    final latestId = _latestMessageId;
    final startId = (latestId - windowSize + 1).clamp(1, latestId);

    final msgs = <Message>[];
    // DB messages in range
    for (var id = latestId; id >= startId; id--) {
      if (id <= ChatDatabase.totalMessages) {
        msgs.add(ChatDatabase.getMessage(id));
      }
    }
    // Session messages in range
    for (final m in _sessionMessages) {
      if (m.id >= startId && m.id <= latestId) {
        msgs.add(m);
      }
    }
    msgs.sort((a, b) => b.id.compareTo(a.id));

    setState(() {
      _messages = msgs;
      _oldestLoadedId = startId;
      _newestLoadedId = latestId;
      _isAtBottom = true;
      _unreadCount = 0;
    });

    if (thenJumpToBottom) _jumpToBottom();
  }

  // ── Scroll tracking ───────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final atBottom = _scrollController.offset <= 150;
    bool needsRebuild = false;

    if (atBottom != _isAtBottom) {
      _isAtBottom = atBottom;
      if (atBottom) _unreadCount = 0;
      needsRebuild = true;
    }

    // Update visible range for pagination debugging
    final rangeChanged = _updateVisibleRangeText();
    if (rangeChanged || needsRebuild) setState(() {});
  }

  /// Updates [_visibleRangeText] from controller. Returns true if changed.
  bool _updateVisibleRangeText() {
    final range = _listController.visibleRange;
    if (range == null || _messages.isEmpty) return false;
    final (first, last) = range;
    if (first < 0 ||
        last < 0 ||
        first >= _messages.length ||
        last >= _messages.length) return false;

    // Reversed list: first index = bottom (newest visible),
    // last index = top (oldest visible).
    final newestId = _messages[first].id;
    final oldestId = _messages[last].id;
    final text = 'Visible: [$oldestId] - [$newestId]  '
        '(${last - first + 1} items, loaded ${_messages.length})';
    if (text == _visibleRangeText) return false;
    _visibleRangeText = text;
    return true;
  }

  void _updateVisibleRange() {
    if (_updateVisibleRangeText()) setState(() {});
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _messages.isEmpty) return;
      _listController.jumpTo(
        index: 0,
        alignment: ListItemAlignment.bottom,
      );
    });
  }

  // ── Search & jump ─────────────────────────────────────────────────────────

  void _showSearchDialog() {
    final searchController = TextEditingController();
    var alignment = ListItemAlignment.center;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Jump to Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Message ID',
                  hintText: 'e.g. 42',
                ),
                onSubmitted: (_) {
                  final id = int.tryParse(searchController.text.trim());
                  if (id == null) return;
                  Navigator.pop(ctx);
                  _jumpToMessageId(id, alignment);
                },
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Position in viewport:'),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ListItemAlignment>(
                segments: const [
                  ButtonSegment(
                    value: ListItemAlignment.top,
                    label: Text('Top'),
                  ),
                  ButtonSegment(
                    value: ListItemAlignment.center,
                    label: Text('Center'),
                  ),
                  ButtonSegment(
                    value: ListItemAlignment.bottom,
                    label: Text('Bottom'),
                  ),
                ],
                selected: {alignment},
                onSelectionChanged: (selected) =>
                    setDialogState(() => alignment = selected.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final id = int.tryParse(searchController.text.trim());
                if (id == null) return;
                Navigator.pop(ctx);
                _jumpToMessageId(id, alignment);
              },
              child: const Text('Go'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _jumpToMessageId(
    int id,
    ListItemAlignment alignment,
  ) async {
    // Validate range
    if (id < 1 || id >= _nextOutgoingId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message ID $id not found')),
        );
      }
      return;
    }

    // ── Windowed loading: load a window AROUND the target, not everything ──
    // If the target is already in the current window, just jump.
    // Otherwise, replace the window with ~200 items centered on the target.
    final alreadyLoaded = id >= _oldestLoadedId && id <= _newestLoadedId;

    if (!alreadyLoaded) {
      const halfWindow = 100;
      final windowStart =
          (id - halfWindow).clamp(1, ChatDatabase.totalMessages);
      final windowEnd = (id + halfWindow).clamp(1, _latestMessageId);

      final msgs = <Message>[];
      // DB messages in range
      for (var mid = windowEnd; mid >= windowStart; mid--) {
        if (mid <= ChatDatabase.totalMessages) {
          msgs.add(ChatDatabase.getMessage(mid));
        }
      }
      // Session messages in range
      for (final m in _sessionMessages) {
        if (m.id >= windowStart && m.id <= windowEnd) {
          msgs.add(m);
        }
      }
      msgs.sort((a, b) => b.id.compareTo(a.id));

      setState(() {
        _messages = msgs;
        _oldestLoadedId = windowStart;
        _newestLoadedId = windowEnd;
      });
    }

    // Jump by key after layout — the controller resolves key → index.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _listController.jumpToKey(key: id, alignment: alignment);
      // Update visible range after jump settles
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateVisibleRange();
      });
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildMessageList(),
                  _buildVisibleRangeOverlay(),
                  _buildScrollToBottomButton(),
                ],
              ),
            ),
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            'A',
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alex',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            'online',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade400,
                ),
          ),
        ],
      ),
      actions: [
        // Search by message ID
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search by ID',
          onPressed: _showSearchDialog,
        ),
        // Jump to oldest → aligned to TOP of viewport
        IconButton(
          icon: const Icon(Icons.vertical_align_top),
          tooltip: 'Oldest → top',
          onPressed: _messages.isEmpty
              ? null
              : () => _listController.jumpTo(
                    index: _messages.length - 1,
                    alignment: ListItemAlignment.top,
                  ),
        ),
        // Jump to middle → aligned to CENTER of viewport
        IconButton(
          icon: const Icon(Icons.unfold_less),
          tooltip: 'Middle → center',
          onPressed: _messages.isEmpty
              ? null
              : () => _listController.jumpTo(
                    index: _messages.length ~/ 2,
                    alignment: ListItemAlignment.center,
                  ),
        ),
        // Jump to newest → aligned to BOTTOM of viewport
        IconButton(
          icon: const Icon(Icons.vertical_align_bottom),
          tooltip: 'Newest → bottom',
          onPressed: _messages.isEmpty
              ? null
              : () {
                  _listController.jumpTo(
                    index: 0,
                    alignment: ListItemAlignment.bottom,
                  );
                  setState(() {
                    _isAtBottom = true;
                    _unreadCount = 0;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return AnchoredPaginatedList<Message>(
      items: _messages,
      itemBuilder: _buildMessageItem,
      itemKey: (msg) => msg.id,
      onLoadMore: _onLoadMore,
      hasMoreForward: _hasMoreOlder,
      hasMoreBackward: _hasMoreNewer,
      controller: _listController,
      scrollController: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      loadingBuilder: (context, direction) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      emptyBuilder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No messages yet.\nSay hello!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    Message message,
    int index,
  ) {
    final widgets = <Widget>[];

    // "Beginning of conversation" indicator at the very top
    if (index == _messages.length - 1 && !_hasMoreOlder) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Beginning of conversation',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
      );
    }

    // Date header when the day changes.
    // In our reversed list, index+1 is the next-older message (above).
    final showDateHeader = index == _messages.length - 1 ||
        (index < _messages.length - 1 &&
            !_isSameDay(
              message.timestamp,
              _messages[index + 1].timestamp,
            ));
    if (showDateHeader) {
      widgets.add(_DateHeader(date: message.timestamp));
    }

    // The chat bubble
    widgets.add(_ChatBubble(message: message));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _buildVisibleRangeOverlay() {
    if (_visibleRangeText.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .inverseSurface
                .withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _visibleRangeText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return Positioned(
      right: 12,
      bottom: 12,
      child: AnimatedScale(
        scale: _isAtBottom ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _isAtBottom ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: () {
              if (_messages.isEmpty) return;
              if (_hasMoreNewer) {
                // Viewing an old window — jump back to latest
                _jumpToLatestWindow(thenJumpToBottom: true);
              } else {
                _listController.jumpTo(
                  index: 0,
                  alignment: ListItemAlignment.bottom,
                );
                setState(() {
                  _isAtBottom = true;
                  _unreadCount = 0;
                });
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          '$_unreadCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: _sendMessage,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat bubble widget
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMe = message.isMe;

    final bubbleColor = isMe ? cs.primaryContainer : cs.surfaceContainerHighest;
    final textColor = isMe ? cs.onPrimaryContainer : cs.onSurface;

    // Asymmetric corners: larger on the sender side, smaller "tail" on the
    // side closest to the screen edge.
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    final timeString = _formatTime(message.timestamp);

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '[${message.id}] ${message.text}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            timeString,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );

    // Their messages: show avatar on the left
    if (!isMe) {
      return Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: bubble),
          ],
        ),
      );
    }

    // My messages: right-aligned, no avatar
    return Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 3),
      child: Align(
        alignment: Alignment.centerRight,
        child: bubble,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0
        ? 12
        : h > 12
            ? h - 12
            : h;
    return '$hour12:$m $period';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date header
// ─────────────────────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(date),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
