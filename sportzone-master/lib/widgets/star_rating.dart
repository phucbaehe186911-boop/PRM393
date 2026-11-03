import 'package:flutter/material.dart';

/// Widget hiển thị và chọn đánh giá sao
class StarRating extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color starColor;
  final ValueChanged<double>? onChanged; // null = readonly mode

  const StarRating({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 24,
    this.starColor = const Color(0xFFD97706),
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final filled = index < rating.floor();
        final halfFilled =
            !filled && index < rating && rating - index >= 0.5;

        return GestureDetector(
          onTap: onChanged != null
              ? () => onChanged!(index + 1.0)
              : null,
          child: Icon(
            filled
                ? Icons.star
                : halfFilled
                    ? Icons.star_half
                    : Icons.star_border,
            color: starColor,
            size: size,
          ),
        );
      }),
    );
  }
}
