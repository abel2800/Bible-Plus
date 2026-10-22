import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  bool _focusMode = false;
  int _indexBeforeFocus = 1;

  int get selectedIndex => _selectedIndex;
  bool get focusMode => _focusMode;

  void setIndex(int index) {
    if (_focusMode && index != 1) return;
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void setFocusMode(bool value) {
    if (_focusMode == value) return;
    if (value) {
      _indexBeforeFocus = _selectedIndex;
      _selectedIndex = 1;
    } else {
      _selectedIndex = _indexBeforeFocus;
    }
    _focusMode = value;
    notifyListeners();
  }
}
