# 🎨 CampusHub UI Design Guidelines

**Version:** 1.0

**Project:** CampusHub

**Platform:** Flutter (Android & iOS)

**Design System:** Material Design 3

---

# Table of Contents

1. Design Philosophy
2. Design Principles
3. Brand Identity
4. Color System
5. Typography
6. Spacing System
7. Border Radius
8. Shadows & Elevation
9. Icons
10. Components
11. Navigation
12. Screen Layout
13. Accessibility
14. Animations
15. Responsive Design
16. Dark Mode
17. UI Patterns

---

# 1. Design Philosophy

CampusHub is designed to be:

- Modern
- Clean
- Student Friendly
- Professional
- Fast
- Accessible

The interface should feel like a combination of

- LinkedIn
- Discord
- Google Classroom
- Notion
- GitHub

without copying any of them.

---

# 2. Design Principles

## Simplicity

Every screen should focus on one primary task.

---

## Consistency

Buttons, cards, spacing and typography should remain consistent across the application.

---

## Accessibility

Every user should easily navigate the application.

---

## Scalability

Components should be reusable.

---

## Mobile First

CampusHub is designed primarily for mobile devices.

---

# 3. Brand Identity

App Name

CampusHub

Tagline

One Campus. One Platform.

Brand Personality

- Friendly
- Modern
- Professional
- Innovative
- Collaborative

---

# 4. Color System

## Primary

Royal Blue

```
#2563EB
```

Used for

- Buttons
- Active Icons
- Navigation
- Links

---

## Secondary

Indigo

```
#4F46E5
```

Used for

- Highlights
- Progress

---

## Success

Emerald

```
#10B981
```

Used for

- Success
- Completed
- Placement Status

---

## Warning

Amber

```
#F59E0B
```

---

## Error

Red

```
#EF4444
```

---

## Background

Light

```
#F8FAFC
```

Dark

```
#0F172A
```

---

## Surface

```
#FFFFFF
```

---

## Text

Primary

```
#111827
```

Secondary

```
#6B7280
```

---

# 5. Typography

Font Family

Inter

Alternative

Poppins

---

Heading 1

32

Bold

---

Heading 2

28

Bold

---

Heading 3

24

SemiBold

---

Title

20

SemiBold

---

Body

16

Regular

---

Caption

14

Regular

---

Small

12

Regular

---

# 6. Spacing System

Base Unit

8px

Spacing

4

8

12

16

24

32

40

48

Never use random spacing values.

---

# 7. Border Radius

Cards

16

Buttons

12

Dialogs

20

Bottom Sheets

28

Text Fields

12

---

# 8. Elevation

Cards

2dp

Floating Button

6dp

Bottom Sheet

8dp

Dialog

10dp

Keep shadows subtle.

---

# 9. Icons

Use

Material Symbols Rounded

or

Cupertino Icons

Avoid mixing icon packs.

---

# 10. Buttons

## Primary Button

Filled

Blue Background

White Text

---

## Secondary Button

Outlined

Blue Border

Transparent Background

---

## Tertiary Button

Text Button

No Border

---

## FAB

Only one Floating Action Button per screen.

Example

Feed

↓

Create Post

---

# 11. Input Fields

Rounded

12 Radius

Support

- Prefix Icon
- Helper Text
- Error Message

---

# 12. Cards

Cards are the primary content container.

Used for

- Posts
- Clubs
- Events
- Roadmaps
- Projects

Padding

16

Radius

16

---

# 13. Navigation

Bottom Navigation

Home

Career

Clubs

Chat

Profile

Maximum

5 tabs

---

# 14. Home Screen

Top

AppBar

↓

Feed Tabs

↓

Stories / Highlights (Future)

↓

Feed

↓

FAB

---

# 15. Feed Tabs

My Feed

Related

Cross

Clubs

Following

Swipe between tabs.

---

# 16. AppBar

Contains

Logo

Title

Search

Notifications

Profile

---

# 17. Search

Universal Search

Supports

Students

Faculty

Posts

Clubs

Events

Resources

---

# 18. Profile

Sections

Header

About

Skills

Projects

Certificates

Achievements

Portfolio

---

# 19. Career Hub

Contains

Progress Card

↓

Roadmaps

↓

Recommended Skills

↓

Resources

↓

Weekly Goals

---

# 20. Club Page

Club Banner

↓

Description

↓

Members

↓

Feed

↓

Events

↓

Resources

---

# 21. Event Card

Shows

Image

Title

Date

Location

Register Button

---

# 22. Placement Card

Company Logo

↓

Role

↓

Package

↓

Eligibility

↓

Apply Button

---

# 23. Notification Card

Icon

↓

Title

↓

Message

↓

Time

Unread notifications have a colored indicator.

---

# 24. Empty States

Every screen should have a proper empty state.

Example

No Clubs

"No clubs joined yet."

Button

Explore Clubs

---

# 25. Error States

Use friendly messages.

Instead of

Error 404

Use

"Something went wrong."

Retry Button

---

# 26. Loading States

Use

Skeleton Loaders

Instead of

Circular Progress Indicators

whenever possible.

---

# 27. Animations

Use subtle animations.

Examples

Fade

Slide

Scale

Hero

Lottie

Avoid excessive animations.

---

# 28. Responsive Design

Support

Small Phones

Large Phones

Tablets

Flutter Web (Future)

---

# 29. Dark Mode

Support both

Light Theme

Dark Theme

Avoid pure black.

---

# 30. Accessibility

Minimum Touch Area

48 x 48

Contrast Ratio

WCAG AA

Support

Screen Readers

Dynamic Font Size

---

# 31. Design Tokens

Primary

Royal Blue

Font

Inter

Radius

16

Spacing

8

Animation

300ms

---

# 32. UI Components

Reusable Components

PrimaryButton

SecondaryButton

AppTextField

ProfileAvatar

PostCard

ClubCard

RoadmapCard

EventCard

NotificationTile

UserTile

SearchBar

AppDialog

LoadingView

EmptyView

ErrorView

---

# 33. Screen List

Authentication

- Splash
- Login
- Forgot Password

Main

- Home
- Career
- Clubs
- Chat
- Profile

Features

- Feed
- Post Details
- Club Details
- Event Details
- Roadmap
- Resources
- Notifications
- Search
- Settings

Admin

- Dashboard
- User Management
- Club Verification

---

# 34. Figma Guidelines

Use

Auto Layout

Component Variants

Design Tokens

Color Styles

Text Styles

Icon Components

No detached components.

---

# 35. Naming Convention

Buttons

PrimaryButton

Cards

PostCard

Dialogs

DeleteDialog

Screens

HomeScreen

Widgets

RoadmapCard

---

# 36. Design Quality Checklist

Before implementing any screen verify:

✅ Consistent spacing

✅ Typography follows guidelines

✅ Uses reusable components

✅ Responsive layout

✅ Supports dark mode

✅ Accessible colors

✅ Touch targets ≥ 48px

✅ Empty state available

✅ Loading state available

✅ Error state available

---

# Conclusion

CampusHub follows a clean, modern, and scalable design system based on Material Design 3. Every screen should prioritize clarity, consistency, accessibility, and reusability. The design system ensures that as the application grows, new features can be added without compromising the overall user experience.
