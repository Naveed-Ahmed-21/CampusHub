import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';

class StoryItemData {
  final String id;
  final String title;
  final String? imageUrl;
  final List<Color> gradientColors;
  final bool isUserStory;

  const StoryItemData({
    required this.id,
    required this.title,
    this.imageUrl,
    this.gradientColors = const [Colors.purple, Colors.pink, Colors.orange],
    this.isUserStory = false,
  });
}

class StoriesSectionWidget extends ConsumerWidget {
  const StoriesSectionWidget({super.key});

  static const List<StoryItemData> _mockStories = [
    StoryItemData(
      id: 'story_1',
      title: 'IT',
      gradientColors: [Colors.purple, Colors.pink],
    ),
    StoryItemData(
      id: 'story_2',
      title: 'CSE',
      gradientColors: [Colors.cyan, Colors.blue],
    ),
    StoryItemData(
      id: 'story_3',
      title: 'ECE',
      gradientColors: [Colors.red, Colors.orange],
    ),
    StoryItemData(
      id: 'story_4',
      title: 'MECH',
      gradientColors: [Colors.indigo, Colors.purple],
    ),
    StoryItemData(
      id: 'story_5',
      title: 'CIVIL',
      gradientColors: [Colors.teal, Colors.green],
    ),
    StoryItemData(
      id: 'story_6',
      title: 'FOSS Club',
      gradientColors: [Colors.amber, Colors.deepOrange],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;

    return Container(
      height: 96,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _mockStories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // First Story: "Your story" with '+' badge
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.teal.shade100,
                          child: Text(
                            user != null ? user.firstName[0].toUpperCase() : 'N',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Your story', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          final story = _mockStories[index - 1];

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Viewing ${story.title} story update...')),
                );
              },
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: story.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.indigo.shade900,
                        child: Text(
                          story.title.length > 4 ? story.title.substring(0, 4) : story.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
