import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';

class UpcomingDeadlinesCard extends StatelessWidget {
  final List<dynamic> upcomingDeadlines;

  const UpcomingDeadlinesCard({super.key, required this.upcomingDeadlines});

  @override
  Widget build(BuildContext context) {
    if (upcomingDeadlines.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeSlideAnimation(
      delay: 150,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black12,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade500, Colors.deepOrange.shade400],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────
              // HEADER
              // ─────────────────────────────
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Text(
                      'Upcoming Deadlines',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────
              // DEADLINE ITEMS
              // ─────────────────────────────
              ...upcomingDeadlines.asMap().entries.map((entry) {
                final index = entry.key;
                final goal = entry.value;

                final title = goal['title']?.toString() ?? 'Untitled Goal';

                final daysRemaining =
                    (goal['days_remaining'] as num?)?.toDouble() ?? 0;

                final isLast = index == upcomingDeadlines.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: _DeadlineItem(
                    title: title,
                    daysRemaining: daysRemaining,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineItem extends StatelessWidget {
  final String title;
  final double daysRemaining;

  const _DeadlineItem({required this.title, required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    final days = daysRemaining.ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_circle_outlined,
              color: Colors.white,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  days == 1 ? '1 day remaining' : '$days days remaining',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
        ],
      ),
    );
  }
}
