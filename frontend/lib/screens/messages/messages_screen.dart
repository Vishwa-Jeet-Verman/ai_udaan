import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/user_avatar.dart';
import '../../screens/support/support_screen.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final mp = context.read<MessageProvider>();
    final auth = context.read<AuthProvider>();
    final token = await ApiService.getToken();
    if (token != null) mp.connectSocket(token, myUserId: auth.user?.id);
    await Future.wait([
      mp.loadConversations(),
      mp.loadStarred(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.messages),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            tooltip: 'Support & Feedback',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: UserAvatar(radius: 16, fontSize: 12),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.star_outline), text: AppLocalizations.of(context)!.starred),
            Tab(icon: const Icon(Icons.lock_outline), text: AppLocalizations.of(context)!.private),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StarredTab(),
          _PrivateTab(),
        ],
      ),
    );
  }
}

// ─── Starred Tab ──────────────────────────────────────────────────────────────

class _StarredTab extends StatelessWidget {
  const _StarredTab();

  @override
  Widget build(BuildContext context) {
    final starred = context.watch<MessageProvider>().starredMessages;
    if (starred.isEmpty) {
      return _EmptyState(
        icon: Icons.star_outline,
        message: AppLocalizations.of(context)!.noStarredMessages,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: starred.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final msg = starred[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              _initials(msg.senderName),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          title: Text(
            msg.senderName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            msg.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM d').format(msg.timestamp.toLocal()),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Private Tab ─────────────────────────────────────────────────────────────

class _PrivateTab extends StatelessWidget {
  const _PrivateTab();

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MessageProvider>();
    final isAdmin = context.watch<AuthProvider>().user?.isAdmin ?? false;
    final conversations = mp.conversations;

    return Column(
      children: [
        Expanded(
          child: conversations.isEmpty
              ? _EmptyState(
                  icon: Icons.lock_outline,
                  message: isAdmin
                      ? AppLocalizations.of(context)!.noStudentMessages
                      : AppLocalizations.of(context)!.conversationsHere,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) {
                    final conv = conversations[i];
                    return _ConversationTile(
                      conversation: conv,
                      onTap: () {
                        // Normalize admin conversations to 'moodle-2' key
                        final chatKey = (conv.partnerId == 'admin' || conv.partnerId == 'moodle-2') ? 'moodle-2' : conv.partnerId;
                        mp.clearUnread(chatKey);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: mp,
                              child: ChatScreen(
                                chatKey: chatKey,
                                chatTitle: conv.partnerName,
                                isGroup: false,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unread > 0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        child: Text(
          _initials(conversation.partnerName),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(
        conversation.partnerName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          color: hasUnread ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('HH:mm').format(
              conversation.lastMessage.timestamp.toLocal(),
            ),
            style: TextStyle(
              fontSize: 11,
              color: hasUnread ? theme.colorScheme.primary : Colors.grey,
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unread}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts[0].isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
}
