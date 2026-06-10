import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../services/ai_chat_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, String>> history = [];
  final ScrollController _scrollController = ScrollController();
  bool loading = false;
  String? _sessionId;

  void send() async {
    if (controller.text.isEmpty) return;

    final userMessage = controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      loading = true;
      history.add({"role": "user", "content": userMessage});
      controller.clear();
    });

    _scrollToBottom();

    try {
      final response = await AiChatService.sendMessage(
        userMessage,
        sessionId: _sessionId,
      );

      if (_sessionId == null && response.sessionId != null) {
        _sessionId = response.sessionId;
      }

      setState(() {
        history.add({"role": "assistant", "content": response.answer});
        loading = false;
      });

      _scrollToBottom();
    } on TimeoutException catch (e) {
      setState(() => loading = false);
      if (mounted) _showError(e.message ?? 'The request timed out.');
    } catch (e) {
      setState(() => loading = false);
      if (mounted) _showError(_friendlyError(e));
    }
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    final prefix = 'Exception: ';
    final text = msg.startsWith(prefix) ? msg.substring(prefix.length) : msg;

    if (text.contains('waking up') ||
        text.contains('503') ||
        text.contains('502') ||
        text.contains('504')) {
      return 'The AI model is waking up. Please try again in a moment.';
    }
    if (text.contains('sign in') || text.contains('401')) {
      return 'Your session expired. Please sign in again.';
    }
    if (text.contains('too long') || text.contains('timed out')) {
      return 'The coach is taking too long. Please try again.';
    }
    if (text.contains('too many') || text.contains('429')) {
      return 'You have sent too many messages. Please wait a moment.';
    }
    return text.isNotEmpty && text.length < 100
        ? text
        : 'Something went wrong. Please try again.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AI Coach",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.bot,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'AI Coach',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'I\'m here to support you with empathy\nand gentle guidance.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white.withOpacity(0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length + (loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == history.length) {
                        // Loading indicator
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.white.withOpacity(0.1),
                                      Colors.white.withOpacity(0.05),
                                    ]
                                  : [
                                      AppColors.textPrimary.withOpacity(0.05),
                                      AppColors.textPrimary.withOpacity(0.02),
                                    ],
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : AppColors.textPrimary.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'AI is thinking...',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.7)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final message = history[index];
                      final isUser = message["role"] == "user";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF8BC34A)
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.bot,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isUser
                                        ? [
                                            const Color(0xFF7C3AED),
                                            const Color(0xFF9333EA),
                                          ]
                                        : isDark
                                            ? [
                                                Colors.white.withOpacity(0.1),
                                                Colors.white.withOpacity(0.05),
                                              ]
                                            : [
                                                AppColors.textPrimary
                                                    .withOpacity(0.05),
                                                AppColors.textPrimary
                                                    .withOpacity(0.02),
                                              ],
                                  ),
                                  border: Border.all(
                                    color: isUser
                                        ? const Color(0xFF7C3AED)
                                        : isDark
                                            ? Colors.white.withOpacity(0.2)
                                            : AppColors.textPrimary
                                                .withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  message["content"] ?? "",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: isUser
                                        ? Colors.white
                                        : isDark
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFF9333EA)
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.user,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.textPrimary.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ]
                              : [
                                  AppColors.textPrimary.withOpacity(0.05),
                                  AppColors.textPrimary.withOpacity(0.02),
                                ],
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : AppColors.textPrimary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white.withOpacity(0.5)
                                : AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => send(),
                        enabled: !loading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0.06),
                              ]
                            : [
                                AppColors.textPrimary.withOpacity(0.06),
                                AppColors.textPrimary.withOpacity(0.03),
                              ],
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.16)
                            : AppColors.textPrimary.withOpacity(0.08),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        LucideIcons.mic,
                        color: isDark
                            ? Colors.white.withOpacity(0.75)
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: null,
                      tooltip: 'Voice input coming soon',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                      ),
                    ),
                    child: IconButton(
                      icon: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              LucideIcons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                      onPressed: loading ? null : send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
