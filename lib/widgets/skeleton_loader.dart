import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/foodly_colors.dart';

/// Contenedor genérico con efecto shimmer para estados de carga.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: FoodlyColors.grisClaro,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: FoodlyColors.grisClaro,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton para una card de pedido en el historial.
class PedidoCardSkeleton extends StatelessWidget {
  const PedidoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonBox(width: 140, height: 16),
                SkeletonBox(width: 70, height: 22, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 10),
            const SkeletonBox(width: 90, height: 12),
            const SizedBox(height: 8),
            const SkeletonBox(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const SkeletonBox(width: 200, height: 12),
            const SizedBox(height: 10),
            const SkeletonBox(width: 80, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Lista de N skeletons de pedido.
class PedidoListSkeleton extends StatelessWidget {
  const PedidoListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => const PedidoCardSkeleton(),
    );
  }
}

/// Skeleton para el header del perfil.
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: FoodlyColors.grisClaro,
          highlightColor: Colors.white,
          child: const CircleAvatar(
            radius: 40,
            backgroundColor: FoodlyColors.grisClaro,
          ),
        ),
        const SizedBox(height: 16),
        const SkeletonBox(width: 180, height: 20),
        const SizedBox(height: 24),
        _tile(),
        const SizedBox(height: 12),
        _tile(),
      ],
    );
  }

  Widget _tile() {
    return Row(
      children: [
        const SkeletonBox(width: 20, height: 20),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 80, height: 11),
              SizedBox(height: 4),
              SkeletonBox(width: double.infinity, height: 15),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton para una card de local en el listado.
class LocalCardSkeleton extends StatelessWidget {
  const LocalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: FoodlyColors.grisClaro,
            highlightColor: Colors.white,
            child: Container(
              height: 140,
              color: FoodlyColors.grisClaro,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 160, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 12),
                SizedBox(height: 6),
                SkeletonBox(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de N skeletons de local.
class LocalListSkeleton extends StatelessWidget {
  const LocalListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => const LocalCardSkeleton(),
    );
  }
}
