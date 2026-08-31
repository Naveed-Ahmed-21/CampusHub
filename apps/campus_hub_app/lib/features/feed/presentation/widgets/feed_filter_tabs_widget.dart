import 'package:flutter/material.dart';

class FeedTabOption {
  final String label;
  final String type;
  final Color? dotColor;

  const FeedTabOption({
    required this.label,
    required this.type,
    this.dotColor,
  });
}

class FeedFilterTabsWidget extends StatelessWidget {
  final String activeFeedType;
  final ValueChanged<String> onSelectTab;

  const FeedFilterTabsWidget({
    super.key,
    required this.activeFeedType,
    required this.onSelectTab,
  });

  static const List<FeedTabOption> tabs = [
    FeedTabOption(label: 'For You', type: 'MY_FEED'),
    FeedTabOption(label: 'Following', type: 'FOLLOWING'),
    FeedTabOption(label: 'My Department', type: 'DEPARTMENT', dotColor: Colors.purple),
    FeedTabOption(label: 'Cross Department', type: 'CROSS_DEPARTMENT', dotColor: Colors.orange),
    FeedTabOption(label: 'Related', type: 'CLUB', dotColor: Colors.green),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = tab.type == activeFeedType;

          return InkWell(
            onTap: () => onSelectTab(tab.type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 2.5))
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.primary : Colors.grey.shade700,
                    ),
                  ),
                  if (tab.dotColor != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tab.dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
