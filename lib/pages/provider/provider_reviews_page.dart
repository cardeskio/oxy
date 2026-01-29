import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oxy/models/service_provider.dart';
import 'package:oxy/services/living_service.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/components/empty_state.dart';
import 'package:oxy/utils/formatters.dart';

/// Reviews management page for service providers
class ProviderReviewsPage extends StatefulWidget {
  const ProviderReviewsPage({super.key});

  @override
  State<ProviderReviewsPage> createState() => _ProviderReviewsPageState();
}

class _ProviderReviewsPageState extends State<ProviderReviewsPage> {
  List<ServiceReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final livingService = context.read<LivingService>();
    if (livingService.myProvider == null) return;

    setState(() => _isLoading = true);
    
    try {
      final reviews = await livingService.getProviderReviews(
        livingService.myProvider!.id,
      );
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
      ),
      body: Consumer<LivingService>(
        builder: (context, livingService, _) {
          final provider = livingService.myProvider;

          if (provider == null) {
            return const Center(child: Text('No business profile'));
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadReviews,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Rating summary
                _RatingSummary(
                  rating: provider.ratingAverage,
                  count: provider.ratingCount,
                ),
                const SizedBox(height: 24),

                // Reviews list
                if (_reviews.isEmpty)
                  EmptyState(
                    icon: HugeIcons.strokeRoundedStar,
                    title: 'No Reviews Yet',
                    message: 'Reviews from your customers will appear here.',
                  )
                else
                  ..._reviews.map((review) => _ReviewCard(
                    review: review,
                    onRespond: () => _showRespondDialog(review),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRespondDialog(ServiceReview review) {
    final controller = TextEditingController(text: review.providerResponse);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Review'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your response...',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = controller.text.trim();
              if (response.isEmpty) return;
              
              Navigator.pop(context);
              
              try {
                final livingService = context.read<LivingService>();
                await livingService.respondToReview(
                  review.id,
                  response,
                );
                await _loadReviews();
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Response saved')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    controller.dispose();
  }
}

class _RatingSummary extends StatelessWidget {
  final double rating;
  final int count;

  const _RatingSummary({
    required this.rating,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count > 0 ? rating.toStringAsFixed(1) : '-',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count review${count == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ServiceReview review;
  final VoidCallback onRespond;

  const _ReviewCard({
    required this.review,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: review.userAvatarUrl != null
                    ? NetworkImage(review.userAvatarUrl!)
                    : null,
                child: review.userAvatarUrl == null
                    ? Text(
                        (review.userName ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      Formatters.dateTime(review.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: TextStyle(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ],

          // Provider response
          if (review.providerResponse != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Your Response',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.providerResponse!,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Respond button
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRespond,
              icon: Icon(
                review.providerResponse == null
                    ? Icons.reply
                    : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(
                review.providerResponse == null ? 'Respond' : 'Edit Response',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
