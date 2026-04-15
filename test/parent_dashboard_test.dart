import 'package:flutter_test/flutter_test.dart';

/// Mock Functions
bool addChild(String name, String id, String location) {
  return name.isNotEmpty && id.length == 10 && location.isNotEmpty;
}

bool updateParentInfo(String name, String phone) {
  return name.isNotEmpty && phone.length == 10;
}

bool confirmAttendance(bool beforeDeadline) {
  return beforeDeadline;
}

bool viewDashboard(bool isLoggedIn) {
  return isLoggedIn;
}

bool trackTransportation(bool validChildSelected) {
  return validChildSelected;
}

void main() {
  group('Parent Dashboard Module Tests', () {
    /// ✅ Add Child
    test('Add child with valid data', () {
      final result = addChild("Ali", "1234567890", "Jeddah");
      expect(result, true);
    });

    test('Reject child with invalid data', () {
      final result = addChild("", "123", "");
      expect(result, false);
    });

    /// ✅ Update Parent Info
    test('Update parent info with valid data', () {
      final result = updateParentInfo("Raghad", "0551234567");
      expect(result, true);
    });

    test('Reject update with invalid data', () {
      final result = updateParentInfo("", "123");
      expect(result, false);
    });

    /// ✅ Confirm Attendance
    test('Confirm attendance before deadline', () {
      final result = confirmAttendance(true);
      expect(result, true);
    });

    test('Reject attendance after deadline', () {
      final result = confirmAttendance(false);
      expect(result, false);
    });

    /// ✅ View Dashboard
    test('View dashboard when logged in', () {
      final result = viewDashboard(true);
      expect(result, true);
    });
  });
}
