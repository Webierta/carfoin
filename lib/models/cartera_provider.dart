import 'dart:math' show sqrt, pow;

import 'package:flutter/foundation.dart';

import '../utils/fecha_util.dart';
import 'cartera.dart';

class CarteraProvider with ChangeNotifier {
  // obtener lista de carteras de DB
  final List<Cartera> _carteras = [];

  List<Cartera> get carteras => _carteras;

  void addCartera(Cartera cartera) {
    if (!_carteras.contains(cartera)) {
      _carteras.add(cartera);
    }
    notifyListeners();
  }

  void sortCarteras() {
    _carteras.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  void removeCartera(Cartera cartera) {
    _carteras.remove(cartera);
    notifyListeners();
  }

  void removeAllCarteras() {
    _carteras.clear();
    notifyListeners();
  }

  void addFondo(Cartera cartera, Fondo fondo) {
    for (var f in cartera.fondos) {
      if (f.isin == fondo.isin) {
        cartera.fondos.remove(f);
      }
    }
    cartera.fondos.add(fondo);
    notifyListeners();
  }

  void sortFondos(Cartera cartera) {
    cartera.fondos.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  void removeFondo(Cartera cartera, Fondo fondo) {
    cartera.fondos.remove(fondo);
    notifyListeners();
  }

  void removeAllFondos(Cartera cartera) {
    cartera.fondos.clear();
    notifyListeners();
  }

  void addValor(Fondo fondo, Valor valor) {
    for (var v in fondo.valores) {
      if (v.date == valor.date) {
        fondo.valores.remove(v);
      }
    }
    fondo.valores.add(valor);
    sortValores(fondo);
    calculaIndices(fondo);
    notifyListeners();
  }

  void addValores(Fondo fondo, List<Valor> valores) {
    for (var valor in valores) {
      addValor(fondo, valor);
    }
    notifyListeners();
  }

  void sortValores(Fondo fondo) {
    fondo.valores.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void removeValor(Fondo fondo, Valor valor) {
    fondo.valores.remove(valor);
    calculaIndices(fondo);
    notifyListeners();
  }

  void removeAllValores(Fondo fondo) {
    fondo.valores.clear();
    calculaIndices(fondo);
    notifyListeners();
  }

  void calculaStats(Fondo fondo) {
    int? dateMinimo;
    int? dateMaximo;
    double? precioMinimo;
    double? precioMaximo;
    double? precioMedio;
    double? volatilidad;

    if (fondo.valores.isNotEmpty) {
      sortValores(fondo);
      dateMinimo = fondo.valores.first.date;
      dateMaximo = fondo.valores.last.date;
      final List<double> precios = fondo.valores.map((v) => v.precio).toList();
      precioMinimo = precios.reduce((curr, next) => curr < next ? curr : next);
      precioMaximo = precios.reduce((curr, next) => curr > next ? curr : next);
      precioMedio = precios.reduce((a, b) => a + b) / precios.length;
      var diferencialesCuadrados = 0.0;
      for (var valor in fondo.valores) {
        diferencialesCuadrados += (valor.precio - precioMedio) * (valor.precio - precioMedio);
      }
      var varianza = diferencialesCuadrados / fondo.valores.length;
      volatilidad = sqrt(varianza);
    }
    fondo.dateMinimo = dateMinimo;
    fondo.dateMaximo = dateMaximo;
    fondo.precioMinimo = precioMinimo;
    fondo.precioMaximo = precioMaximo;
    fondo.precioMedio = precioMedio;
    fondo.volatilidad = volatilidad;
    notifyListeners();
  }

  void calculaTotalParticipaciones(Fondo fondo) {
    double? participaciones;
    if (fondo.valores.isNotEmpty) {
      double part = 0.0;
      for (var valor in fondo.valores) {
        if (valor.tipo == 1) {
          part += valor.participaciones ?? 0.0;
        } else if (valor.tipo == 0) {
          part -= valor.participaciones ?? 0.0;
        }
      }
      participaciones = part;
    }
    fondo.totalParticipaciones = participaciones;
    notifyListeners();
  }

  void calculaInversion(Fondo fondo) {
    double? inversion;
    if (fondo.valores.isNotEmpty && fondo.totalParticipaciones != null) {
      double inv = 0.0;
      for (var valor in fondo.valores) {
        if (valor.tipo == 1) {
          inv += (valor.participaciones ?? 0.0) * valor.precio;
        } else if (valor.tipo == 0) {
          inv -= (valor.participaciones ?? 0.0) * valor.precio;
        }
      }
      inversion = inv;
    }
    fondo.inversion = inversion;
    notifyListeners();
  }

  void calculaResultado(Fondo fondo) {
    double? resultado;
    if (fondo.valores.isNotEmpty && fondo.totalParticipaciones != null) {
      sortValores(fondo);
      resultado = fondo.totalParticipaciones! * fondo.valores.first.precio;
    }
    fondo.resultado = resultado;
    notifyListeners();
  }

  void calculaBalance(Fondo fondo) {
    double? balance;
    if (fondo.resultado != null && fondo.inversion != null) {
      balance = fondo.resultado! - fondo.inversion!;
    }
    fondo.balance = balance;
    notifyListeners();
  }

  void calculaRentabilidad(Fondo fondo) {
    double? rentabilidad;
    if (fondo.balance != null && fondo.inversion != null) {
      if (fondo.inversion! > 0) {
        rentabilidad = fondo.balance! / fondo.inversion!;
      }
    }
    fondo.rentabilidad = rentabilidad;
    notifyListeners();
  }

  void calculaTae(Fondo fondo) {
    double? tae;
    if (fondo.resultado != null && fondo.inversion != null) {
      if (fondo.inversion! > 0) {
        sortValores(fondo);
        int? dateFirstOp;
        for (var valor in fondo.valores.reversed) {
          if (valor.tipo != null) {
            dateFirstOp = valor.date;
            break;
          }
        }
        if (dateFirstOp != null) {
          tae = pow(
                  (fondo.resultado! / fondo.inversion!),
                  (365 /
                      (FechaUtil.epochToDate(fondo.valores.first.date)
                          .difference(FechaUtil.epochToDate(dateFirstOp))
                          .inDays))) -
              1;
        }
      }
    }
    fondo.tae = tae;
    notifyListeners();
  }

  void calculaIndices(Fondo fondo) {
    calculaStats(fondo);
    calculaTotalParticipaciones(fondo);
    calculaInversion(fondo);
    calculaResultado(fondo);
    calculaBalance(fondo);
    calculaRentabilidad(fondo);
    calculaTae(fondo);
  }
}