import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';

/// Danh sách các sân user đã chat
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<ChatViewModel>().loadChattedCourts(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        title: const Text(
          AppStrings.chatTitle,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ),
      body: Consumer<ChatViewModel>(
        builder: (_, vm, __) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (vm.chattedCourts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 48, color: AppColors.textDisabled),
                  const SizedBox(height: 12),
                  const Text(
                    AppStrings.noChats,
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vào trang sân và nhấn "Liên hệ" để bắt đầu chat',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textDisabled),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: vm.chattedCourts.length,
            separatorBuilder: (_, __) =>
                Container(height: 1, color: AppColors.border),
            itemBuilder: (ctx, i) {
              final courtId = vm.chattedCourts.keys.elementAt(i);
              final court = vm.chattedCourts[courtId]!;
              final lastMsg = vm.getLastMessage(courtId);
              return InkWell(
                onTap: () => ctx.push('/chat/$courtId'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: court.images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: court.images.first,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.sports_tennis,
                                color: AppColors.textDisabled),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              court.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (lastMsg != null)
                              Text(
                                lastMsg,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.textDisabled),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
