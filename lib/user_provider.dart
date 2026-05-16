import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  // 1. Data jo hume har jagah chahiye
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;

  // 2. Data ko bahar dikhane ke liye (Getters)
  DateTime? get lastPeriodDate => _lastPeriodDate;

  // 3. Data badalne ka tarika (Setter)
  void updatePeriodDate(DateTime newDate) {
    _lastPeriodDate = newDate;

    // YE SABSE JARURI HAI: Ye poore app ko chillakar bolta hai "DATA BADAL GAYA HAI!"
    notifyListeners();
  }

  // 4. Agle period tak kitne din bache hain (Calculations)
  int get daysUntilNext {
    if (_lastPeriodDate == null) return 0;
    final next = _lastPeriodDate!.add(Duration(days: _cycleLength));
    return next.difference(DateTime.now()).inDays;
  }
}
