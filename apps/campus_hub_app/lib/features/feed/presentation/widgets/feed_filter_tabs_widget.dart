import 'package:flutter/material.dart';
import '../../../../core/widgets/campus_segmented_control.dart';

class FeedTabOption {
  final String label;
  final String type;

  const FeedTabOption({
    required this.label,
    required this.type,
  });
}

class FeedFilterTabsWidget extends StatelessWidget {
  final String activeFeedType;
  final ValueChanged<String> onSelectTab;
  final bool isAdmin;

  const FeedFilterTabsWidget({
    super.key,
    required this.activeFeedType,
    required this.onSelectTab,
    this.isAdmin = false,
  });

  static const List<FeedTabOption> allTabs = [
    FeedTabOption(label: 'For You', type: 'forYou'),
    FeedTabOption(label: 'Following', type: 'following'),
    FeedTabOption(label: 'Department', type: 'myDepartment'),
    FeedTabOption(label: 'Related', type: 'related'),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleTabs = isAdmin
        ? allTabs.where((t) => t.type == 'forYou' || t.type == 'following').toList()
        : allTabs;

    final selectedIndex = visibleTabs.indexWhere((t) => t.type == activeFeedType);
    final validIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: CampusSegmentedControl(
        height: 38,
        selectedIndex: validIndex,
        items: visibleTabs
            .map((t) => CampusSegmentItem(label: t.label))
            .toList(growable: false),
        onValueChanged: (index) {
          if (index >= 0 && index < visibleTabs.length) {
            onSelectTab(visibleTabs[index].type);
          }
        },
      ),
    );
  }
}
