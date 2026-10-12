---
name: flutter-skill
description: AI Agent Bridge and testing automation skill for Flutter applications using flutter-skill. Use when launching, inspecting, tapping, typing, scrolling, testing, debugging, or performing UI accessibility/semantic tree analysis and monkey/fuzz testing on Flutter apps.
---

# Flutter Skill — AI Agent Bridge for Flutter Apps

`flutter-skill` connects AI coding agents directly to running Flutter applications. It enables the agent to inspect the UI element hierarchy, tap widgets, enter text, scroll views, take screenshots, run autonomous exploratory testing, and hot reload after making code edits.

---

## 1. Architecture & Capabilities

- **Lightweight Semantic Tree**: Instead of expensive multi-modal screenshots (~4,000 tokens), `flutter-skill` leverages Flutter's accessibility tree (`flutter-skill snap`) to generate compact semantic representations (~200 tokens).
- **Interactive Control**: Execute single or batched UI interactions (`tap`, `fill`, `scroll`, `drag`) without manual device intervention.
- **Autonomous & Monkey Testing**: Run automated exploration (`flutter-skill explore`) and random action fuzz testing (`flutter-skill monkey`) to detect app crashes and broken flows.
- **MCP Server Protocol**: Runs as an MCP server (`flutter-skill server`), exposing native tools directly into the agent's toolbelt.

---

## 2. In-App Integration (`apps/campus_hub_app`)

The Flutter client binding is enabled in debug mode:

```dart
// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_skill/flutter_skill.dart';

Future<void> main() async {
  if (kDebugMode) FlutterSkillBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  // ... rest of initialization
  runApp(const MyApp());
}
```

---

## 3. CLI Command Reference

### Launch & Connect
```bash
# Launch Flutter application and connect bridge
flutter-skill launch ./apps/campus_hub_app

# Check environment and connection health
flutter-skill doctor
```

### Inspect & Interact
```bash
# Inspect interactive elements (buttons, inputs, lists)
flutter-skill inspect

# Accessibility semantic tree snapshot (compact tokens)
flutter-skill snap

# Capture visual screenshot
flutter-skill screenshot /tmp/campus_hub_ui.jpg

# Action execution
flutter-skill tap "Sign In"
flutter-skill type "student@gmail.com"
```

### Autonomous Testing & Exploration
```bash
# AI autonomous exploration - discovers broken flows and errors
flutter-skill explore http://localhost:3000 --depth=3

# Monkey / Fuzz testing - stress test UI with randomized actions
flutter-skill monkey http://localhost:3000 --actions=100 --seed=42

# Multi-platform validation
flutter-skill test --url http://localhost:3000 --platforms web,android
```

---

## 4. MCP Server Configuration

Configured in `~/.gemini/config/mcp_config.json`:

```json
{
  "mcpServers": {
    "flutter-skill": {
      "command": "flutter-skill",
      "args": ["server"]
    }
  }
}
```

When active, `flutter-skill` exposes tools for the agent to inspect UI hierarchies, dispatch user gestures, verify render boxes, and validate navigation flows dynamically.
