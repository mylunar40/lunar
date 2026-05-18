import 'package:flutter/material.dart';
import 'core/repositories/cycle_repository.dart';

class UserProvider with ChangeNotifier {
  // 1. Data jo hume har jagah chahiye
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;

  UserProvider() {
    // Load from local cache on startup
    _lastPeriodDate = CycleRepository.loadLastPeriodDate();
    _cycleLength = CycleRepository.loadCycleLength();
  }

  // 2. Data ko bahar dikhane ke liye (Getters)
  DateTime? get lastPeriodDate => _lastPeriodDate;
  int get cycleLength => _cycleLength;

  // 3. Data badalne ka tarika (Setter)
  void updatePeriodDate(DateTime newDate) {
    _lastPeriodDate = newDate;
    CycleRepository.saveLastPeriodDate(newDate);
    // YE SABSE JARURI HAI: Ye poore app ko chillakar bolta hai "DATA BADAL GAYA HAI!"
    notifyListeners();
  }

  void updateCycleLength(int length) {
    _cycleLength = length;
    CycleRepository.saveCycleLength(length);
    notifyListeners();
  }

  // 4. Agle period tak kitne din bache hain (Calculations)
  int get daysUntilNext {
    if (_lastPeriodDate == null) return 0;
    final next = _lastPeriodDate!.add(Duration(days: _cycleLength));
    return next.difference(DateTime.now()).inDays;
  }
}
