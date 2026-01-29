import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oxy/theme.dart';

/// Common property features/amenities that managers can quickly add
const List<String> commonPropertyFeatures = [
  'Parking',
  'Security',
  '24/7 Security',
  'CCTV',
  'Swimming Pool',
  'Gym',
  'Lift/Elevator',
  'Generator Backup',
  'Water Storage',
  'Rooftop Access',
  'Garden',
  'Playground',
  'Laundry Room',
  'Internet/WiFi',
  'Gate',
  'Intercom',
  'Staff Quarters',
  'Visitor Parking',
  'Pet Friendly',
  'Wheelchair Access',
  'Balcony',
  'Near Schools',
  'Near Shopping',
  'Near Transport',
  'Quiet Neighborhood',
];

/// A widget for editing property or unit features/amenities
class FeaturesEditor extends StatefulWidget {
  final List<String> features;
  final ValueChanged<List<String>> onChanged;
  final String title;
  final String subtitle;

  const FeaturesEditor({
    super.key,
    required this.features,
    required this.onChanged,
    this.title = 'Features & Amenities',
    this.subtitle = 'Add features to help tenants find this property',
  });

  @override
  State<FeaturesEditor> createState() => _FeaturesEditorState();
}

class _FeaturesEditorState extends State<FeaturesEditor> {
  late List<String> _features;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _features = List<String>.from(widget.features);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggleFeature(String feature) {
    setState(() {
      if (_features.contains(feature)) {
        _features.remove(feature);
      } else {
        _features.add(feature);
      }
    });
    widget.onChanged(_features);
  }

  void _addCustomFeature() {
    final custom = _customController.text.trim();
    if (custom.isNotEmpty && !_features.contains(custom)) {
      setState(() => _features.add(custom));
      _customController.clear();
      widget.onChanged(_features);
    }
  }

  void _removeFeature(String feature) {
    setState(() => _features.remove(feature));
    widget.onChanged(_features);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedStar,
              color: AppColors.primaryTeal,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Selected features
        if (_features.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _features.map((f) => Chip(
              label: Text(f),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeFeature(f),
              backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
              side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
              labelStyle: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w500,
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Add custom feature
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customController,
                decoration: const InputDecoration(
                  hintText: 'Add custom feature...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (_) => _addCustomFeature(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addCustomFeature,
              icon: const Icon(Icons.add_circle, color: AppColors.primaryTeal),
              tooltip: 'Add',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Common features grid
        Text(
          'Quick Add',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.lightOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commonPropertyFeatures.map((f) {
            final isSelected = _features.contains(f);
            return InkWell(
              onTap: () => _toggleFeature(f),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primaryTeal.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primaryTeal 
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.check, size: 14, color: AppColors.primaryTeal),
                      ),
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? AppColors.primaryTeal : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Compact display of features (for cards/lists)
class FeaturesDisplay extends StatelessWidget {
  final List<String> features;
  final int maxDisplay;
  final Color? backgroundColor;
  final Color? textColor;

  const FeaturesDisplay({
    super.key,
    required this.features,
    this.maxDisplay = 4,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    final displayFeatures = features.take(maxDisplay).toList();
    final remaining = features.length - maxDisplay;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayFeatures.map((f) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            f,
            style: TextStyle(
              fontSize: 11,
              color: textColor ?? AppColors.lightOnSurfaceVariant,
            ),
          ),
        )),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$remaining more',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
