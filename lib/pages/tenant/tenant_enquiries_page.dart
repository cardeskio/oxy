import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/property_enquiry.dart';
import 'package:oxy/services/tenant_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/utils/icons.dart';
import 'package:oxy/components/loading_indicator.dart';

class TenantEnquiriesPage extends StatefulWidget {
  const TenantEnquiriesPage({super.key});

  @override
  State<TenantEnquiriesPage> createState() => _TenantEnquiriesPageState();
}

class _TenantEnquiriesPageState extends State<TenantEnquiriesPage> {
  List<PropertyEnquiry> _enquiries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnquiries();
  }

  Future<void> _loadEnquiries() async {
    setState(() => _isLoading = true);
    final tenantService = context.read<TenantService>();
    final enquiries = await tenantService.loadMyEnquiries();
    if (mounted) {
      setState(() {
        _enquiries = enquiries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        automaticallyImplyLeading: false,
        title: Text(
          'My Enquiries',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEnquiries,
        child: _isLoading
            ? const OxyLoadingOverlay(message: 'Loading enquiries...')
            : _enquiries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _enquiries.length,
                    itemBuilder: (context, index) {
                      final enquiry = _enquiries[index];
                      return _EnquiryCard(
                        enquiry: enquiry,
                        onTap: () => _showEnquiryDetail(enquiry),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: AppIcons.document,
            color: Colors.grey.shade300,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No enquiries yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.lightOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your property enquiries will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showEnquiryDetail(PropertyEnquiry enquiry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EnquiryDetailPage(enquiry: enquiry),
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  final PropertyEnquiry enquiry;
  final VoidCallback onTap;

  const _EnquiryCard({required this.enquiry, required this.onTap});

  Color get _statusColor {
    switch (enquiry.status) {
      case EnquiryStatus.pending: return AppColors.warning;
      case EnquiryStatus.contacted: return AppColors.info;
      case EnquiryStatus.scheduled: return AppColors.primaryTeal;
      case EnquiryStatus.viewingDone: return AppColors.success;
      case EnquiryStatus.declined: return AppColors.error;
      case EnquiryStatus.converted: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      enquiry.propertyName ?? 'Property',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      enquiry.statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (enquiry.unitLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Unit: ${enquiry.unitLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightOnSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      enquiry.enquiryTypeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  const Spacer(),
                  HugeIcon(
                    icon: AppIcons.calendar,
                    color: AppColors.lightOnSurfaceVariant,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.relativeDate(enquiry.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (enquiry.scheduledDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    HugeIcon(
                      icon: AppIcons.pending,
                      color: AppColors.success,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled: ${Formatters.dateTime(enquiry.scheduledDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EnquiryDetailPage extends StatefulWidget {
  final PropertyEnquiry enquiry;

  const _EnquiryDetailPage({required this.enquiry});

  @override
  State<_EnquiryDetailPage> createState() => _EnquiryDetailPageState();
}

class _EnquiryDetailPageState extends State<_EnquiryDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  List<EnquiryComment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final tenantService = context.read<TenantService>();
    final comments = await tenantService.loadEnquiryComments(widget.enquiry.id);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final tenantService = context.read<TenantService>();
      await tenantService.addEnquiryComment(
        enquiryId: widget.enquiry.id,
        orgId: widget.enquiry.orgId,
        content: content,
      );
      _messageController.clear();
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Color get _statusColor {
    switch (widget.enquiry.status) {
      case EnquiryStatus.pending: return AppColors.warning;
      case EnquiryStatus.contacted: return AppColors.info;
      case EnquiryStatus.scheduled: return AppColors.primaryTeal;
      case EnquiryStatus.viewingDone: return AppColors.success;
      case EnquiryStatus.declined: return AppColors.error;
      case EnquiryStatus.converted: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enquiry = widget.enquiry;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enquiry Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Enquiry Info Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            enquiry.propertyName ?? 'Property',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (enquiry.unitLabel != null)
                            Text(
                              'Unit: ${enquiry.unitLabel}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.lightOnSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        enquiry.statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: AppIcons.document,
                      label: enquiry.enquiryTypeLabel,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: AppIcons.calendar,
                      label: Formatters.shortDate(enquiry.createdAt),
                    ),
                  ],
                ),
                if (enquiry.scheduledDate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(icon: AppIcons.pending, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduled Viewing',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                Formatters.dateTime(enquiry.scheduledDate!),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Messages Section
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Messages',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: OxyLoader(size: 32))
                        : _comments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    HugeIcon(
                                      icon: AppIcons.chat,
                                      color: AppColors.lightOnSurfaceVariant,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No messages yet',
                                      style: TextStyle(color: AppColors.lightOnSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Send a message to start the conversation',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.lightOnSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadComments,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = _comments[index];
                                    return _CommentBubble(comment: comment);
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
          
          // Message Input
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: AppColors.lightSurfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSending ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const HugeIcon(
                          icon: HugeIcons.strokeRoundedSent,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final dynamic icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: AppColors.lightOnSurfaceVariant, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lightOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final EnquiryComment comment;

  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    final isManager = comment.isFromManager;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isManager ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isManager) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryTeal,
              child: Text(
                (comment.userName ?? 'M')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isManager
                    ? AppColors.primaryTeal.withValues(alpha: 0.1)
                    : AppColors.primaryTeal,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isManager ? 0 : 12),
                  bottomRight: Radius.circular(isManager ? 12 : 0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isManager)
                    Text(
                      comment.userName ?? 'Property Manager',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  Text(
                    comment.content,
                    style: TextStyle(
                      color: isManager ? Colors.black87 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.relativeDate(comment.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isManager
                          ? AppColors.lightOnSurfaceVariant
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isManager) const SizedBox(width: 40),
        ],
      ),
    );
  }
}
