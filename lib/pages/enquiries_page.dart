import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:oxy/models/property_enquiry.dart';
import 'package:oxy/services/data_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/formatters.dart';
import 'package:oxy/utils/icons.dart';
import 'package:oxy/components/loading_indicator.dart';

class EnquiriesPage extends StatefulWidget {
  const EnquiriesPage({super.key});

  @override
  State<EnquiriesPage> createState() => _EnquiriesPageState();
}

class _EnquiriesPageState extends State<EnquiriesPage> {
  EnquiryStatus? _filterStatus;
  
  @override
  void initState() {
    super.initState();
    // Load enquiries on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataService>().loadEnquiries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        title: Text(
          'Property Enquiries',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedFilter, color: Colors.white, size: 24),
            onPressed: () => _showFilterSheet(),
          ),
        ],
      ),
      body: Consumer<DataService>(
        builder: (context, dataService, _) {
          if (dataService.isLoading) {
            return const OxyLoadingOverlay(message: 'Loading enquiries...');
          }
          
          var enquiries = dataService.enquiries;
          
          // Apply filter
          if (_filterStatus != null) {
            enquiries = enquiries.where((e) => e.status == _filterStatus).toList();
          }
          
          if (enquiries.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () => dataService.loadEnquiries(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: enquiries.length,
              itemBuilder: (context, index) {
                final enquiry = enquiries[index];
                return _EnquiryCard(
                  enquiry: enquiry,
                  onTap: () => _showEnquiryDetail(enquiry),
                );
              },
            ),
          );
        },
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
            _filterStatus != null ? 'No enquiries with this status' : 'No enquiries yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.lightOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enquiries from potential tenants will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filterStatus == null,
                  onTap: () {
                    setState(() => _filterStatus = null);
                    Navigator.pop(context);
                  },
                ),
                ...EnquiryStatus.values.map((status) => _FilterChip(
                  label: _statusLabel(status),
                  isSelected: _filterStatus == status,
                  onTap: () {
                    setState(() => _filterStatus = status);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  String _statusLabel(EnquiryStatus status) {
    switch (status) {
      case EnquiryStatus.pending: return 'Pending';
      case EnquiryStatus.contacted: return 'Contacted';
      case EnquiryStatus.scheduled: return 'Scheduled';
      case EnquiryStatus.viewingDone: return 'Viewing Done';
      case EnquiryStatus.declined: return 'Declined';
      case EnquiryStatus.converted: return 'Converted';
    }
  }

  void _showEnquiryDetail(PropertyEnquiry enquiry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EnquiryDetailPage(enquiry: enquiry),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.lightOnSurfaceVariant,
          ),
        ),
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                    child: Text(
                      enquiry.contactName[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enquiry.contactName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          enquiry.contactPhone,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            enquiry.propertyName ?? 'Property',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  HugeIcon(icon: AppIcons.calendar, color: AppColors.lightOnSurfaceVariant, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.relativeDate(enquiry.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                  if (enquiry.scheduledDate != null) ...[
                    const SizedBox(width: 16),
                    HugeIcon(icon: AppIcons.pending, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled: ${Formatters.shortDate(enquiry.scheduledDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
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
  late PropertyEnquiry _enquiry;

  @override
  void initState() {
    super.initState();
    _enquiry = widget.enquiry;
    _loadComments();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final dataService = context.read<DataService>();
    final comments = await dataService.loadEnquiryComments(widget.enquiry.id);
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
      final dataService = context.read<DataService>();
      await dataService.addEnquiryComment(
        enquiryId: widget.enquiry.id,
        content: content,
      );
      _messageController.clear();
      
      // Mark as contacted if pending
      if (_enquiry.status == EnquiryStatus.pending) {
        await dataService.updateEnquiryStatus(
          widget.enquiry.id,
          EnquiryStatus.contacted,
        );
        setState(() {
          _enquiry = _enquiry.copyWith(status: EnquiryStatus.contacted);
        });
      }
      
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

  Future<void> _updateStatus(EnquiryStatus status, {DateTime? scheduledDate}) async {
    try {
      final dataService = context.read<DataService>();
      await dataService.updateEnquiryStatus(
        widget.enquiry.id,
        status,
        scheduledDate: scheduledDate,
      );
      setState(() {
        _enquiry = _enquiry.copyWith(
          status: status,
          scheduledDate: scheduledDate ?? _enquiry.scheduledDate,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_enquiry.statusLabel}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color get _statusColor {
    switch (_enquiry.status) {
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
        actions: [
          PopupMenuButton<EnquiryStatus>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (status) async {
              if (status == EnquiryStatus.scheduled) {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (date != null) {
                  _updateStatus(status, scheduledDate: date);
                }
              } else {
                _updateStatus(status);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: EnquiryStatus.contacted,
                child: Text('Mark as Contacted'),
              ),
              const PopupMenuItem(
                value: EnquiryStatus.scheduled,
                child: Text('Schedule Viewing'),
              ),
              const PopupMenuItem(
                value: EnquiryStatus.viewingDone,
                child: Text('Viewing Complete'),
              ),
              const PopupMenuItem(
                value: EnquiryStatus.converted,
                child: Text('Mark as Converted'),
              ),
              const PopupMenuItem(
                value: EnquiryStatus.declined,
                child: Text('Decline'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Contact Info Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                      child: Text(
                        _enquiry.contactName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _enquiry.contactName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              HugeIcon(icon: AppIcons.phone, color: AppColors.lightOnSurfaceVariant, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _enquiry.contactPhone,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          if (_enquiry.contactEmail != null)
                            Row(
                              children: [
                                HugeIcon(icon: AppIcons.email, color: AppColors.lightOnSurfaceVariant, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _enquiry.contactEmail!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
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
                        _enquiry.statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                                  _enquiry.propertyName ?? 'Property',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_enquiry.unitLabel != null)
                                  Text(
                                    'Unit: ${_enquiry.unitLabel}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.lightOnSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _enquiry.enquiryTypeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_enquiry.message != null) ...[
                        const Divider(height: 16),
                        Text(
                          _enquiry.message!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_enquiry.scheduledDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(icon: AppIcons.calendar, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Column(
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
                              Formatters.dateTime(_enquiry.scheduledDate!),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
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
                      'Communication',
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
                                      'Send a message to respond to this enquiry',
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

class _CommentBubble extends StatelessWidget {
  final EnquiryComment comment;

  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    final isManager = comment.isFromManager;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isManager ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isManager) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                (comment.userName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isManager
                    ? AppColors.primaryTeal
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isManager ? 12 : 0),
                  bottomRight: Radius.circular(isManager ? 0 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isManager)
                    Text(
                      comment.userName ?? 'Prospective Tenant',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  Text(
                    comment.content,
                    style: TextStyle(
                      color: isManager ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.relativeDate(comment.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isManager
                          ? Colors.white70
                          : AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isManager) const SizedBox(width: 40),
        ],
      ),
    );
  }
}
