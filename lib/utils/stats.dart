import 'dart:math';

import '../models/cartera.dart';
import 'fecha_util.dart';

class Stats {
  final List<Valor> valores;
  const Stats(this.valores);

  double? precioMinimo() {
    if (valores.isNotEmpty) {
      final List<double> precios = valores.map((v) => v.precio).toList();
      return precios.reduce((curr, next) => curr < next ? curr : next);
    }
    return null;
  }

  double? precioMaximo() {
    if (valores.isNotEmpty) {
      final List<double> precios = valores.map((v) => v.precio).toList();
      return precios.reduce((curr, next) => curr > next ? curr : next);
    }
    return null;
  }

  int? datePrecioMinimo() {
    if (valores.isNotEmpty) {
      for (var valor in valores) {
        if (valor.precio == precioMinimo()) {
          return valor.date;
        }
      }
      return null;
    }
    return null;
  }

  int? datePrecioMaximo() {
    if (valores.isNotEmpty) {
      for (var valor in valores) {
        if (valor.precio == precioMaximo()) {
          return valor.date;
        }
      }
      return null;
    }
    return null;
  }

  double? precioMedio() {
    if (valores.isNotEmpty) {
      final List<double> precios = valores.map((v) => v.precio).toList();
      return precios.reduce((a, b) => a + b) / precios.length;
    }
    return null;
  }

  double? volatilidad() {
    if (valores.isNotEmpty) {
      final List<double> precios = valores.map((v) => v.precio).toList();
      var precioMedio = precios.reduce((a, b) => a + b) / precios.length;
      var diferencialesCuadrados = 0.0;
      for (var valor in valores) {
        diferencialesCuadrados += (valor.precio - precioMedio) * (valor.precio - precioMedio);
      }
      var varianza = diferencialesCuadrados / valores.length;
      return sqrt(varianza);
    }
    return null;
  }

  double? totalParticipaciones() {
    double? participaciones;
    if (valores.isNotEmpty) {
      double part = 0.0;
      for (var valor in valores) {
        if (valor.tipo == 1) {
          part += valor.participaciones ?? 0.0;
        } else if (valor.tipo == 0) {
          part -= valor.participaciones ?? 0.0;
        }
      }
      participaciones = part;
    }
    return participaciones;
  }

  double? inversion() {
    double? inversion;
    if (valores.isNotEmpty && totalParticipaciones() != null) {
      double inv = 0.0;
      for (var valor in valores) {
        if (valor.tipo == 1) {
          inv += (valor.participaciones ?? 0.0) * valor.precio;
        } else if (valor.tipo == 0) {
          inv -= (valor.participaciones ?? 0.0) * valor.precio;
        }
      }
      inversion = inv;
    }
    return inversion;
  }

  double? resultado() {
    double? resultado;
    if (valores.isNotEmpty && totalParticipaciones() != null) {
      //sortValores(fondo);
      resultado = totalParticipaciones()! * valores.first.precio;
    }
    return resultado;
  }

  double? balance() {
    double? balance;
    if (resultado() != null && inversion() != null) {
      balance = resultado()! - inversion()!;
    }
    return balance;
  }

  double? rentabilidad() {
    double? rentabilidad;
    if (balance() != null && inversion() != null && inversion()! > 0) {
      rentabilidad = balance()! / inversion()!;
    }
    return rentabilidad;
  }

  double? tae() {
    double? tae;
    if (resultado() != null && inversion() != null && inversion()! > 0) {
      //sortValores(fondo);
      int? dateFirstOp;
      for (var valor in valores.reversed) {
        if (valor.tipo != null) {
          dateFirstOp = valor.date;
          break;
        }
      }
      if (dateFirstOp != null) {
        tae = pow(
                (resultado()! / inversion()!),
                (365 /
                    (FechaUtil.epochToDate(valores.first.date)
                        .difference(FechaUtil.epochToDate(dateFirstOp))
                        .inDays))) -
            1;
      }
    }
    return tae;
  }
}
