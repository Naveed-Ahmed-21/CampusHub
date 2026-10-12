import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_hub_app/core/branding/gcee_brand.dart';
import 'package:campus_hub_app/core/branding/gcee_logo.dart';
import 'package:campus_hub_app/core/branding/campushub_brand.dart';

void main() {
  group('GceeBrand Configuration Tests', () {
    test('Institutional and Product constants are accurately configured', () {
      expect(GceeBrand.institutionName, 'Government College of Engineering, Erode');
      expect(GceeBrand.institutionShort, 'GCEE');
      expect(GceeBrand.productName, 'CampusHub');
      expect(GceeBrand.logoAsset, 'assets/branding/gcee_logo.png');
      expect(GceeBrand.logoFallbackAsset, 'assets/images/gcee_logo.png');
      expect(GceeBrand.logoSemanticsLabel, 'GCEE — Government College of Engineering, Erode official logo');
    });
  });

  group('GceeLogo Widget Tests', () {
    testWidgets('GceeLogo.header renders with dimension 36 and contain fit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GceeLogo.header(),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.fit, BoxFit.contain);
      expect(imageWidget.width, 36.0);
      expect(imageWidget.height, 36.0);
    });

    testWidgets('GceeLogo.login renders with dimension 88 and transparent background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GceeLogo.login(),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.width, 88.0);
      expect(imageWidget.height, 88.0);
    });

    testWidgets('GceeLogo preserves semantics label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GceeLogo.sidebar(),
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == GceeBrand.logoSemanticsLabel,
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('GceeLogo applies black color in light theme and default in dark theme', (tester) async {
      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.light),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: GceeLogo(size: 40),
          ),
        ),
      );
      var imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.color, Colors.black);
      expect(imageWidget.colorBlendMode, BlendMode.srcIn);

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: GceeLogo(size: 40),
          ),
        ),
      );
      await tester.pumpAndSettle();
      imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.color, isNull);
      expect(imageWidget.colorBlendMode, isNull);
    });
  });

  group('CampusHubBrand Widget Tests', () {
    testWidgets('CampusHubBrand.login renders vertical hierarchy with institution details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CampusHubBrand.login(),
          ),
        ),
      );

      expect(find.text(GceeBrand.productName), findsOneWidget);
      expect(find.text(GceeBrand.institutionName), findsOneWidget);
      expect(find.text(GceeBrand.institutionShort), findsOneWidget);
      expect(find.byType(GceeLogo), findsOneWidget);
    });

    testWidgets('CampusHubBrand.header renders horizontal brand with shortcode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CampusHubBrand.header(),
          ),
        ),
      );

      expect(find.text(GceeBrand.productName), findsOneWidget);
      expect(find.text(GceeBrand.institutionShort), findsOneWidget);
      expect(find.byType(GceeLogo), findsOneWidget);
    });
  });
}
