import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/maintenance_ticket.dart';
import 'package:oxy/models/ticket_comment.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/utils/formatters.dart';

/// Local attachment pending upload
class _PendingLocalAttachment {
  final String path;
  final String name;
  final String mimeType;

  _PendingLocalAttachment({
    required this.path,
    required this.name,
    required this.mimeType,
  });
}

class TenantTicketDetailPage extends StatefulWidget {
  final String ticketId;

  const TenantTicketDetailPage({super.key, required this.ticketId});

  @override
  State<TenantTicketDetailPage> createState() => _TenantTicketDetailPageState();
}

class _TenantTicketDetailPageState extends State<TenantTicketDetailPage> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  
  List<TicketComment> _comments = [];
  List<_PendingLocalAttachment> _pendingAttachments = [];
  bool _isLoading = true;
  bool _isSending = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  MaintenanceTicket? get _ticket {
    final tenantService = context.read<TenantService>();
    return tenantService.tickets.where((t) => t.id == widget.ticketId).firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    final tenantService = context.read<TenantService>();
    debugPrint('Loading comments for ticket: ${widget.ticketId}');
    final comments = await tenantService.loadTicketComments(widget.ticketId);
    debugPrint('Loaded ${comments.length} comments');
    setState(() {
      _comments = comments;
      _isLoading = false;
    });
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

  Future<void> _pickMedia() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;
      
      // Store locally without uploading
      setState(() {
        _pendingAttachments.add(_PendingLocalAttachment(
          path: file.path,
          name: file.name,
          mimeType: 'image/jpeg',
        ));
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access camera/gallery')),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() => _pendingAttachments.removeAt(index));
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty && _pendingAttachments.isEmpty) return;

    setState(() {
      _isSending = true;
      _uploadProgress = 0.0;
      _uploadStatus = '';
    });
    
    final tenantService = context.read<TenantService>();
    final uploadedAttachments = <TicketAttachment>[];
    
    // Upload attachments with progress
    if (_pendingAttachments.isNotEmpty) {
      final total = _pendingAttachments.length;
      for (var i = 0; i < _pendingAttachments.length; i++) {
        final pending = _pendingAttachments[i];
        setState(() {
          _uploadProgress = i / total;
          _uploadStatus = 'Uploading ${i + 1}/$total...';
        });
        
        final attachment = await tenantService.uploadTicketAttachment(
          widget.ticketId,
          pending.path,
          pending.name,
          pending.mimeType,
        );
        
        if (attachment != null) {
          uploadedAttachments.add(attachment);
        }
      }
      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Sending...';
      });
    }
    
    final comment = await tenantService.addTicketComment(
      ticketId: widget.ticketId,
      content: content,
      attachments: uploadedAttachments,
    );

    if (comment != null) {
      setState(() {
        _comments.add(comment);
        _pendingAttachments.clear();
        _commentController.clear();
        _isSending = false;
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
      _scrollToBottom();
    } else {
      setState(() {
        _isSending = false;
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send comment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    final theme = Theme.of(context);
    final tenantService = context.watch<TenantService>();

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/tenant/maintenance'),
          ),
          title: const Text('Ticket Not Found'),
        ),
        body: const Center(child: Text('This ticket no longer exists')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tenant/maintenance'),
        ),
        title: Text('Issue #${ticket.id.substring(0, 8)}'),
      ),
      body: Column(
        children: [
          // Ticket Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(ticket.status, theme),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildInfoChip(
                      Icons.home,
                      tenantService.property?.name ?? 'Unknown',
                      theme,
                    ),
                    _buildInfoChip(
                      Icons.door_front_door,
                      tenantService.unit?.unitLabel ?? 'Unknown',
                      theme,
                    ),
                    _buildPriorityChip(ticket.priority, theme),
                    _buildInfoChip(
                      Icons.schedule,
                      Formatters.relativeDate(ticket.createdAt),
                      theme,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadComments,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pull to refresh or send a message',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _CommentBubble(comment: comment);
                          },
                        ),
            ),
          ),

          // Upload Progress
          if (_isSending && _pendingAttachments.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _uploadStatus,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Pending Attachments Preview
          if (_pendingAttachments.isNotEmpty && !_isSending)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _pendingAttachments.length,
                itemBuilder: (context, index) {
                  final attachment = _pendingAttachments[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(attachment.path),
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeAttachment(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickMedia,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isSending ? null : _sendComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status, ThemeData theme) {
    Color color;
    String label;
    switch (status) {
      case TicketStatus.new_:
        color = Colors.blue;
        label = 'Submitted';
      case TicketStatus.assigned:
        color = Colors.orange;
        label = 'Under Review';
      case TicketStatus.inProgress:
        color = Colors.purple;
        label = 'In Progress';
      case TicketStatus.done:
        color = Colors.teal;
        label = 'Completed';
      case TicketStatus.approved:
        color = Colors.green;
        label = 'Resolved';
      case TicketStatus.rejected:
        color = Colors.red;
        label = 'Closed';
    }
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withAlpha(30),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPriorityChip(TicketPriority priority, ThemeData theme) {
    Color color;
    switch (priority) {
      case TicketPriority.low:
        color = Colors.green;
      case TicketPriority.medium:
        color = Colors.orange;
      case TicketPriority.high:
        color = Colors.red;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          priority.name,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final TicketComment comment;

  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isManager = comment.isManager ?? false;
    // For tenant view: manager messages on left, tenant messages on right
    final isFromMe = !isManager;

    // Determine colors based on sender
    final Color bubbleColor;
    final Color textColor;
    final Color subtleTextColor;
    
    if (isFromMe) {
      // My messages (tenant) - use primary color
      bubbleColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      subtleTextColor = theme.colorScheme.onPrimary.withAlpha(180);
    } else {
      // Manager messages - neutral background
      bubbleColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurface;
      subtleTextColor = theme.colorScheme.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                (comment.userName ?? 'M')[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isManager ? (comment.userName ?? 'Property Manager') : 'You',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (comment.content.isNotEmpty)
                    Text(
                      comment.content,
                      style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                    ),
                  if (comment.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: comment.attachments.map((attachment) {
                        return GestureDetector(
                          onTap: () => _showAttachment(context, attachment),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: attachment.isVideo
                                ? Container(
                                    width: 120,
                                    height: 90,
                                    color: Colors.black,
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    attachment.url,
                                    width: 120,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 120,
                                      height: 90,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    Formatters.relativeDate(comment.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtleTextColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAttachment(BuildContext context, TicketAttachment attachment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(attachment.name),
            backgroundColor: Colors.black,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: attachment.isVideo
                ? const Text(
                    'Video playback coming soon',
                    style: TextStyle(color: Colors.white),
                  )
                : InteractiveViewer(
                    child: Image.network(
                      attachment.url,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, color: Colors.white54, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
