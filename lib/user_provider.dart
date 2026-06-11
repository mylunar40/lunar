import 'package:flutter/material.dart';
import 'core/repositories/cycle_repository.dart';
import 'core/providers/lunar_data_provider.dart';

class UserProvider with ChangeNotifier {
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;

  // Optional reference — set by main.dart after both providers are created.
  // When set, every mutation is mirrored into LunarDataProvider so that
  // screens consuming either provider see consistent cycle data.
  LunarDataProvider? _lunarData;

  UserProvider() {
    _lastPeriodDate = CycleRepository.loadLastPeriodDate();
    _cycleLength = CycleRepository.loadCycleLength();
  }

  /// Called once from main.dart to wire up the sync bridge.
  void attachLunarDataProvider(LunarDataProvider lunarData) {
    _lunarData = lunarData;
  }

  // ── Getters ──────────────────────────────────────────────
  DateTime? get lastPeriodDate => _lastPeriodDate;
  int get cycleLength => _cycleLength;

  // ── Setters ──────────────────────────────────────────────
  void updatePeriodDate(DateTime newDate) {
    _lastPeriodDate = newDate;
    CycleRepository.saveLastPeriodDate(newDate);
    _lunarData?.syncPeriodDateFrom(newDate, _cycleLength);
    notifyListeners();
  }

  void updateCycleLength(int length) {
    _cycleLength = length;
    CycleRepository.saveCycleLength(length);
    _lunarData?.syncPeriodDateFrom(_lastPeriodDate, length);
    notifyListeners();
  }

  // ── Derived ──────────────────────────────────────────────
  int get daysUntilNext {
    if (_lastPeriodDate == null) return 0;
    final next = _lastPeriodDate!.add(Duration(days: _cycleLength));
    return next.difference(DateTime.now()).inDays;
  }
}
