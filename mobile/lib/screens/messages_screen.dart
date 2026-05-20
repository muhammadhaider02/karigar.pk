import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const _teal  = Color(0xFF075E54);
  // ignore: unused_field
  static const _green = Color(0xFF25D366);

  List<_ChatPreview> _chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser?.id;
    if (uid == null) {
      setState(() { _chats = []; _loading = false; });
      return;
    }
    try {
      // Pull bookings where I'm the customer OR the worker, with the other
      // party's profile name attached via Postgres foreign-table joins.
      final rows = await supa
          .from('bookings')
          .select('id, status, service_type, slot_time, created_at, customer_id, worker_id, '
                  'customer:customers!customer_id(full_name), '
                  'worker:workers!worker_id(full_name)')
          .or('customer_id.eq.$uid,worker_id.eq.$uid')
          .order('created_at', ascending: false)
          .limit(30);

      final list = <_ChatPreview>[];
      for (final row in (rows as List)) {
        final m = row as Map<String, dynamic>;
        final iAmCustomer = m['customer_id'] == uid;
        final other = (iAmCustomer ? m['worker'] : m['customer']);
        final otherName = (other is Map && other['full_name'] is String && (other['full_name'] as String).isNotEmpty)
            ? other['full_name'] as String
            : (iAmCustomer ? 'Worker' : 'Customer');
        final status = (m['status'] as String? ?? '').toUpperCase();
        list.add(_ChatPreview(
          name: otherName,
          msg: _statusMessage(status, m['service_type'] as String? ?? ''),
          time: _shortAgo(m['created_at'] as String? ?? ''),
          unread: (status == 'WORKER_ASSIGNED' || status == 'EN_ROUTE') ? 1 : 0,
          avatar: otherName.isNotEmpty ? otherName.trim().substring(0, 1).toUpperCase() : '?',
        ));
      }
      // Always also include the support row.
      list.add(const _ChatPreview(name: 'Karigar Support', msg: 'How can we help you today?', time: 'always', unread: 0, avatar: 'KS'));
      if (mounted) setState(() { _chats = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _chats = [const _ChatPreview(name: 'Karigar Support', msg: 'How can we help?', time: 'now', unread: 0, avatar: 'KS')]; _loading = false; });
    }
  }

  String _statusMessage(String status, String service) {
    switch (status) {
      case 'WORKER_ASSIGNED': return 'New booking assigned · $service';
      case 'WORKER_ACCEPTED': return 'Worker accepted your booking';
      case 'EN_ROUTE':        return 'Worker is on the way';
      case 'ARRIVED':         return 'Worker has arrived';
      case 'IN_PROGRESS':     return 'Service in progress';
      case 'COMPLETED':       return 'Service completed · Rate your experience';
      case 'CANCELLED':       return 'Booking cancelled';
      default: return 'Tap to view booking · $service';
    }
  }

  String _shortAgo(String iso) {
    if (iso.isEmpty) return '';
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24)   return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Messages', style: TextStyle(color: Color(0xFF111B21), fontSize: 20, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF111B21)), onPressed: _loadChats),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _chats.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No conversations yet.\nBook a service to start chatting.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8696A0)))))
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.separated(
                    itemCount: _chats.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: Color(0xFFF0F2F5)),
                    itemBuilder: (context, i) {
                      final chat = _chats[i];
                      return _ChatTile(chat: chat)
                          .animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideX(begin: 0.05);
                    },
                  ),
                ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final _ChatPreview chat;
  const _ChatTile({required this.chat});

  static const _teal  = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openChat(context, chat),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Stack(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _teal.withValues(alpha: 0.12),
              child: Text(chat.avatar, style: const TextStyle(color: _teal, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            if (chat.unread > 0)
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: _green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(chat.name, style: const TextStyle(color: Color(0xFF111B21), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(chat.msg, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: chat.unread > 0 ? const Color(0xFF111B21) : const Color(0xFF8696A0),
                fontSize: 13, fontWeight: chat.unread > 0 ? FontWeight.w600 : FontWeight.normal)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(chat.time, style: TextStyle(color: chat.unread > 0 ? _green : const Color(0xFF8696A0), fontSize: 12)),
            const SizedBox(height: 4),
            if (chat.unread > 0)
              Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                child: Center(child: Text('${chat.unread}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
              ),
          ]),
        ]),
      ),
    );
  }

  void _openChat(BuildContext context, _ChatPreview chat) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _ChatDetailScreen(chat: chat)));
  }
}

class _ChatDetailScreen extends StatefulWidget {
  final _ChatPreview chat;
  const _ChatDetailScreen({required this.chat, super.key});
  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  static const _teal  = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);

  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  final List<_Msg> _messages = [
    _Msg(text: 'Salaam! Main 10 minute mein pohonch raha hoon', isMe: false, time: '2:45 PM'),
    _Msg(text: 'Theek hai, main intezaar kar raha hoon', isMe: true, time: '2:46 PM'),
    _Msg(text: 'On my way, 10 mins', isMe: false, time: '2:47 PM'),
  ];

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, isMe: true, time: TimeOfDay.now().format(context)));
      _ctrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 30,
        title: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: _teal.withValues(alpha: 0.12),
            child: Text(widget.chat.avatar, style: const TextStyle(color: _teal, fontWeight: FontWeight.w800, fontSize: 11))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.chat.name, style: const TextStyle(color: Color(0xFF111B21), fontSize: 15, fontWeight: FontWeight.w700)),
            const Text('Online', style: TextStyle(color: Color(0xFF25D366), fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: _teal), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Color(0xFF111B21)), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              return Align(
                alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: m.isMe ? _teal : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(m.isMe ? 16 : 4),
                      bottomRight: Radius.circular(m.isMe ? 4 : 16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(m.text, style: TextStyle(color: m.isMe ? Colors.white : const Color(0xFF111B21), fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(m.time, style: TextStyle(color: m.isMe ? Colors.white54 : const Color(0xFF8696A0), fontSize: 10)),
                  ]),
                ),
              ).animate().fadeIn(duration: 200.ms);
            },
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(28)),
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xFF8696A0))),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ChatPreview {
  final String name, msg, time, avatar;
  final int unread;
  const _ChatPreview({required this.name, required this.msg, required this.time, required this.unread, required this.avatar});
}

class _Msg {
  final String text, time;
  final bool isMe;
  const _Msg({required this.text, required this.isMe, required this.time});
}
