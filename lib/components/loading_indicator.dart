import 'package:flutter/material.dart';
import 'package:oxy/theme.dart';

/// Custom loading indicator with animated dots
class OxyLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;

  const OxyLoader({
    super.key,
    this.size = 48,
    this.color,
    this.message,
  });

  @override
  State<OxyLoader> createState() => _OxyLoaderState();
}

class _OxyLoaderState extends State<OxyLoader> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primaryTeal;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _pulseController]),
            builder: (context, child) {
              return CustomPaint(
                painter: _OxyLoaderPainter(
                  progress: _controller.value,
                  pulse: _pulseController.value,
                  color: color,
                ),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightOnSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _OxyLoaderPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final Color color;

  _OxyLoaderPainter({
    required this.progress,
    required this.pulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    // Draw background track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, trackPaint);
    
    // Draw animated arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final startAngle = progress * 2 * 3.14159;
    final sweepAngle = (0.5 + pulse * 0.3) * 3.14159;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
    
    // Draw center dot with pulse
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.3 + pulse * 0.4);
    
    final dotRadius = 4 + pulse * 2;
    canvas.drawCircle(center, dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _OxyLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}

/// Three bouncing dots loader - compact and minimal
class OxyDotsLoader extends StatefulWidget {
  final double dotSize;
  final Color? color;

  const OxyDotsLoader({
    super.key,
    this.dotSize = 8,
    this.color,
  });

  @override
  State<OxyDotsLoader> createState() => _OxyDotsLoaderState();
}

class _OxyDotsLoaderState extends State<OxyDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primaryTeal;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);
            final bounce = _calculateBounce(progress);
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.dotSize * 0.3),
              child: Transform.translate(
                offset: Offset(0, -bounce * widget.dotSize),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.4 + bounce * 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _calculateBounce(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      final f = (2 * t) - 2;
      return 0.5 * f * f * f + 1;
    }
  }
}

/// Full page loading overlay
class OxyLoadingOverlay extends StatelessWidget {
  final String? message;

  const OxyLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: OxyLoader(
          size: 56,
          message: message,
        ),
      ),
    );
  }
}

/// Skeleton shimmer effect for content loading
class OxyShimmer extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const OxyShimmer({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<OxyShimmer> createState() => _OxyShimmerState();
}

class _OxyShimmerState extends State<OxyShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton placeholder shapes
class OxySkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const OxySkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class OxySkeletonCircle extends StatelessWidget {
  final double size;

  const OxySkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}
