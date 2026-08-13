import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomSearchBarWidget extends StatelessWidget {
  const BottomSearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
      ),
      child: InkWell(
        onTap: () => context.push('/search'),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search students, clubs, posts, events...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.tune, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
