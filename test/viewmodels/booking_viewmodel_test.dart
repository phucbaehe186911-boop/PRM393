import 'package:flutter_test/flutter_test.dart';
import 'package:sportzone/models/time_slot.dart';
import 'package:sportzone/viewmodels/booking_viewmodel.dart';
import 'package:sportzone/services/database_service.dart';

/// Unit tests cho BookingViewModel
/// Kiểm thử logic tính tiền, chọn slot, add-ons
void main() {
  late BookingViewModel vm;

  setUp(() {
    vm = BookingViewModel(DatabaseService());
  });

  tearDown(() {
    vm.clearSelection();
  });

  // Helper tạo TimeSlot mẫu
  TimeSlot makeSlot({
    int id = 1,
    String startTime = '08:00',
    String endTime = '09:00',
    bool isAvailable = true,
  }) {
    return TimeSlot(
      id: id,
      courtId: 1,
      date: '2026-01-01',
      startTime: startTime,
      endTime: endTime,
      isAvailable: isAvailable,
    );
  }

  group('BookingViewModel', () {
    test('calculateTotalPrice - off peak slots', () {
      // 2 slot off-peak, không addon
      final slot1 = makeSlot(id: 1, startTime: '08:00', endTime: '09:00');
      final slot2 = makeSlot(id: 2, startTime: '09:00', endTime: '10:00');

      vm.toggleSlotSelection(slot1);
      vm.toggleSlotSelection(slot2);

      // pricePerHour = 90000, 2 slots
      final total = vm.totalPriceWithCourtPrices(90000, 180000);
      expect(total, equals(180000.0));
    });

    test('calculateTotalPrice - with addons', () {
      final slot = makeSlot(id: 1, startTime: '08:00', endTime: '09:00');
      vm.toggleSlotSelection(slot);

      vm.toggleAddon('racket'); // +30000
      vm.toggleAddon('ball'); // +50000

      // 1 slot off-peak 180000 + racket 30000 + ball 50000 = 260000
      final total = vm.totalPriceWithCourtPrices(180000, 360000);
      expect(total, equals(260000.0));
    });

    test('toggleSlotSelection - add slot', () {
      expect(vm.selectedSlots.length, equals(0));

      final slot = makeSlot(id: 1);
      vm.toggleSlotSelection(slot);

      expect(vm.selectedSlots.length, equals(1));
      expect(vm.selectedSlots.first.id, equals(1));
    });

    test('toggleSlotSelection - remove slot on second tap', () {
      final slot = makeSlot(id: 1);

      vm.toggleSlotSelection(slot); // add
      expect(vm.selectedSlots.length, equals(1));

      vm.toggleSlotSelection(slot); // remove
      expect(vm.selectedSlots.isEmpty, isTrue);
    });

    test('toggleSlotSelection - unavailable slot is ignored', () {
      final slot = makeSlot(id: 1, isAvailable: false);
      vm.toggleSlotSelection(slot);
      expect(vm.selectedSlots.isEmpty, isTrue);
    });

    test('clearSelection - resets slots and addons', () {
      final slot = makeSlot(id: 1);
      vm.toggleSlotSelection(slot);
      vm.toggleAddon('racket');
      vm.toggleAddon('water');

      vm.clearSelection();

      expect(vm.selectedSlots.isEmpty, isTrue);
      expect(vm.selectedAddons['racket'], isFalse);
      expect(vm.selectedAddons['ball'], isFalse);
      expect(vm.selectedAddons['water'], isFalse);
    });

    test('isSlotSelected - returns correct state', () {
      final slot1 = makeSlot(id: 1);
      final slot2 = makeSlot(id: 2);

      vm.toggleSlotSelection(slot1);

      expect(vm.isSlotSelected(slot1), isTrue);
      expect(vm.isSlotSelected(slot2), isFalse);
    });

    test('peak slot isPeak - correctly identifies 17:00-21:00', () {
      final peakSlot = makeSlot(startTime: '18:00', endTime: '19:00');
      final offPeakSlot = makeSlot(startTime: '10:00', endTime: '11:00');
      final borderSlot = makeSlot(startTime: '21:00', endTime: '22:00');

      expect(peakSlot.isPeak, isTrue);
      expect(offPeakSlot.isPeak, isFalse);
      expect(borderSlot.isPeak, isFalse); // 21:00 is NOT peak (17 <= h < 21)
    });

    test('addon prices are correct', () {
      expect(BookingViewModel.addonPrices['racket'], equals(30000));
      expect(BookingViewModel.addonPrices['ball'], equals(50000));
      expect(BookingViewModel.addonPrices['water'], equals(20000));
    });
  });
}
