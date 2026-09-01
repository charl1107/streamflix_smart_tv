import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BaseShimmer extends StatelessWidget {
  final Widget child;
  const BaseShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: child,
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  
  const ShimmerCard({
    super.key, 
    this.width = 160, 
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class ShimmerRail extends StatelessWidget {
  const ShimmerRail({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }
}

class ShimmerHero extends StatelessWidget {
  const ShimmerHero({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: Container(
        width: double.infinity,
        height: 300,
        color: Colors.black,
      ),
    );
  }
}

class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 2/3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}
