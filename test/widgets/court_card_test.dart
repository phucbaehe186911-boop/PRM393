import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportzone/models/court.dart';
import 'package:sportzone/widgets/court_card.dart';

/// Widget tests cho CourtCard
void main() {
  // Tạo Court mẫu cho tests
  final testCourt = Court(
    id: 1,
    name: 'Sân Pickleball Yên Xá',
    type: 'pickleball',
    address: 'Thanh Xuân, Hà Nội',
    lat: 20.9956,
    lng: 105.8027,
    pricePerHour: 80000,
    peakPricePerHour: 180000,
    description: 'Sân test',
    images: [],
    rating: 4.8,
    reviewCount: 42,
  );

  Widget buildCard({VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: CourtCard(
          court: testCourt,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('CourtCard', () {
    testWidgets('renders court name', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('Sân Pickleball Yên Xá'), findsOneWidget);
    });

    testWidgets('renders price with short format', (tester) async {
      await tester.pumpWidget(buildCard());
      // Giá 80000 hiển thị thành '80k/giờ'
      expect(find.textContaining('80k'), findsOneWidget);
    });

    testWidgets('renders court type label', (tester) async {
      await tester.pumpWidget(buildCard());
      // type='pickleball' → typeLabel = 'Pickleball'
      expect(find.text('Pickleball'), findsOneWidget);
    });

    testWidgets('renders rating', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.textContaining('4.8'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));
      await tester.tap(find.byType(CourtCard));
      expect(tapped, isTrue);
    });

    testWidgets('shows placeholder icon when images list is empty',
        (tester) async {
      await tester.pumpWidget(buildCard());
      // Khi images trống → hiển thị Icon sports_tennis
      expect(find.byIcon(Icons.sports_tennis), findsWidgets);
    });

    testWidgets('shows address', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('Thanh Xuân, Hà Nội'), findsOneWidget);
    });
  });
}
