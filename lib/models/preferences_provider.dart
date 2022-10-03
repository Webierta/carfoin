import 'package:flutter/material.dart';

import '../utils/konstantes.dart';

class PreferencesProvider with ChangeNotifier {
  bool? _isStorageLogger;
  bool get isStorageLogger => _isStorageLogger ?? false;
  set isStorageLogger(bool value) {
    _isStorageLogger = value;
    notifyListeners();
  }

  bool? _isAutoExchange;
  bool get isAutoExchange => _isAutoExchange ?? false;
  set isAutoExchange(bool value) {
    _isAutoExchange = value;
    notifyListeners();
  }

  bool? _isByOrderCarteras;
  bool get isByOrderCarteras => _isByOrderCarteras ?? true;
  set isByOrderCarteras(bool value) {
    _isByOrderCarteras = value;
    notifyListeners();
  }

  bool? _isViewDetalleCarteras;
  bool get isViewDetalleCarteras => _isViewDetalleCarteras ?? true;
  set isViewDetalleCarteras(bool value) {
    _isViewDetalleCarteras = value;
    notifyListeners();
  }

  bool? _isConfirmDeleteCartera;
  bool get isConfirmDeleteCartera => _isConfirmDeleteCartera ?? true;
  set isConfirmDeleteCartera(bool value) {
    _isConfirmDeleteCartera = value;
    notifyListeners();
  }

  bool? _isByOrderFondos;
  bool get isByOrderFondos => _isByOrderFondos ?? true;
  set isByOrderFondos(bool value) {
    _isByOrderFondos = value;
    notifyListeners();
  }

  bool? _isViewDetalleFondos;
  bool get isViewDetalleFondos => _isViewDetalleFondos ?? true;
  set isViewDetalleFondos(bool value) {
    _isViewDetalleFondos = value;
    notifyListeners();
  }

  bool? _isConfirmDeleteFondo;
  bool get isConfirmDeleteFondo => _isConfirmDeleteFondo ?? true;
  set isConfirmDeleteFondo(bool value) {
    _isConfirmDeleteFondo = value;
    notifyListeners();
  }

  bool? _isDeleteOperaciones;
  bool get isDeleteOperaciones => _isDeleteOperaciones ?? true;
  set isDeleteOperaciones(bool value) {
    _isDeleteOperaciones = value;
    notifyListeners();
  }

  bool? _isAutoAudate;
  bool get isAutoAudate => _isAutoAudate ?? true;
  set isAutoAudate(bool value) {
    _isAutoAudate = value;
    notifyListeners();
  }

  bool? _isConfirmDelete;
  bool get isConfirmDelete => _isConfirmDelete ?? true;
  set isConfirmDelete(bool value) {
    _isConfirmDelete = value;
    notifyListeners();
  }

  int? _dateExchange;
  int get dateExchange => _dateExchange ?? dateExchangeInit;
  set dateExchange(int value) {
    _dateExchange = value;
    notifyListeners();
  }

  double? _rateExchange;
  double get rateExchange => _rateExchange ?? rateExchangeInit;
  set rateExchange(double value) {
    _rateExchange = value;
    notifyListeners();
  }
}
