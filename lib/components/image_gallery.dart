import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oxy/models/property.dart';
import 'package:oxy/theme.dart';
import 'package:oxy/utils/icons.dart';

/// Horizontal scrollable image gallery with add/remove functionality
class ImageGallery extends StatelessWidget {
  final List<PropertyImage> images;
  final bool canEdit;
  final Future<void> Function(List<String> filePaths)? onAddImages;
  final Future<void> Function(String imageUrl)? onRemoveImage;
  final double height;

  const ImageGallery({
    super.key,
    required this.images,
    this.canEdit = false,
    this.onAddImages,
    this.onRemoveImage,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty && !canEdit) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: AppIcons.noImage, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                'No images',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length + (canEdit ? 1 : 0),
        itemBuilder: (context, index) {
          // Add button at the end
          if (canEdit && index == images.length) {
            return _AddImageButton(onAddImages: onAddImages);
          }

          final image = images[index];
          return _ImageCard(
            image: image,
            canEdit: canEdit,
            onRemove: onRemoveImage != null ? () => onRemoveImage!(image.url) : null,
            onTap: () => _showFullImage(context, image, index),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, PropertyImage image, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final PropertyImage image;
  final bool canEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const _ImageCard({
    required this.image,
    required this.canEdit,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image.url,
                width: 160,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 160,
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, size: 40, color: Colors.grey),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 160,
                    height: 200,
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            if (canEdit && onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(150),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18, color: Colors.white),
                  ),
                ),
              ),
            if (image.caption != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(150), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    image.caption!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddImageButton extends StatefulWidget {
  final Future<void> Function(List<String> filePaths)? onAddImages;

  const _AddImageButton({this.onAddImages});

  @override
  State<_AddImageButton> createState() => _AddImageButtonState();
}

class _AddImageButtonState extends State<_AddImageButton> {
  bool _isUploading = false;
  int _uploadTotal = 0;
  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: Colors.black87, size: 24),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: Colors.black87, size: 24),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select multiple photos'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    try {
      List<String> filePaths = [];
      
      if (choice == 'camera') {
        final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
        if (file != null) filePaths.add(file.path);
      } else {
        // Multi-select from gallery
        final files = await _picker.pickMultiImage(imageQuality: 80);
        filePaths = files.map((f) => f.path).toList();
      }
      
      if (filePaths.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadTotal = filePaths.length;
      });
      
      await widget.onAddImages?.call(filePaths);
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access camera/gallery')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadTotal = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImages,
      child: Container(
        width: 120,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryTeal.withAlpha(100), width: 2),
        ),
        child: _isUploading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  if (_uploadTotal > 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Uploading...',
                      style: TextStyle(
                        color: AppColors.primaryTeal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(icon: AppIcons.gallery, size: 40, color: AppColors.primaryTeal),
                  const SizedBox(height: 8),
                  Text(
                    'Add Photos',
                    style: TextStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Full screen image gallery viewer
class _FullScreenGallery extends StatefulWidget {
  final List<PropertyImage> images;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final image = widget.images[index];
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                image.url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: HugeIcon(icon: AppIcons.noImage, color: Colors.white54, size: 64),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact image gallery for list items (shows thumbnails)
class CompactImageGallery extends StatelessWidget {
  final List<PropertyImage> images;
  final double size;

  const CompactImageGallery({
    super.key,
    required this.images,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: HugeIcon(icon: AppIcons.house, color: Colors.grey.shade400, size: 24),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        images.first.url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade200,
          child: HugeIcon(icon: AppIcons.noImage, color: Colors.grey.shade400, size: 24),
        ),
      ),
    );
  }
}
