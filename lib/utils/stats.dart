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
        diferencialesCuadrados +=
            (valor.precio - precioMedio) * (valor.precio - precioMedio);
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

  List<double> operacionesCapital({required bool isAport}) {
    List<double> operacionesCapital = [];
    int tipoOp = isAport ? 1 : 0;
    if (valores.isNotEmpty && totalParticipaciones() != null) {
      for (var valor in valores) {
        if (valor.tipo == tipoOp) {
          operacionesCapital.add((valor.participaciones ?? 0.0) * valor.precio);
        }
      }
    }
    return operacionesCapital;
  }

  double? suscripcion() {
    double? suscripcion;
    var opAportaciones = operacionesCapital(isAport: true);
    if (opAportaciones.isNotEmpty) {
      suscripcion = opAportaciones.last;
    }
    return suscripcion;
  }

  /*double? _aportaciones() {
    double? aportaciones;
    var opAportaciones = operacionesCapital(isAport: true);
    if (opAportaciones.isNotEmpty && opAportaciones.length > 1) {
      opAportaciones.removeLast();
      aportaciones = opAportaciones.reduce((value, element) => value + element);
    }
    return aportaciones;
  }

  double? _reembolsos() {
    double? reembolsos;
    var opReembolsos = operacionesCapital(isAport: false);
    if (opReembolsos.isNotEmpty) {
      reembolsos = opReembolsos.reduce((value, element) => value + element);
    }
    return reembolsos;
  }*/

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

  /*double? tae() {
    double? tae;
    var rent = rentabilidad();
    if (rent != null) {
      tae = anualizar(rent);
    }
    return tae;
  }*/

  /*double? tae() {
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
        var dias = (FechaUtil.epochToDate(valores.first.date)
            .difference(FechaUtil.epochToDate(dateFirstOp))
            .inDays);
        //tae = pow((resultado()! / inversion()!), (365 / dias)) - 1;
        //tae = (pow((resultado()! / inversion()!), (1 / (dias / 365)))) - 1;
        tae = (pow((1 + rentabilidad()!), (1 / (dias / 365)))) - 1;
      }
    }
    return tae;
  }*/

  /// TAE RENTABILIDAD = (1 + RENT) ^ ( 1 / (DIAS / 365) ) - 1
  /// TAE RENTABILIDAD = (1 + RENT) ^ ( 365 / DIAS ) - 1
  double? anualizar(double rentabilidad) {
    double? anualizada;
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
        var dias = (FechaUtil.epochToDate(valores.first.date)
            .difference(FechaUtil.epochToDate(dateFirstOp))
            .inDays);
        //tae = pow((resultado()! / inversion()!), (365 / dias)) - 1;
        //tae = (pow((resultado()! / inversion()!), (1 / (dias / 365)))) - 1;
        anualizada = (pow((1 + rentabilidad), (1 / (dias / 365)))) - 1;
      }
    }
    return anualizada;
  }

  /*double? twr() {
    double? twr;
    if (resultado() != null && suscripcion() != null) {
      // TWR = (Valor Final – Valor Inicial + Reembolsos – Aportaciones) / Valor Inicial
      //TWR = (CAPITALF - CAPITALI + REEMB - APORT) / CAPITALI
      double aportaciones = _aportaciones() ?? 0.0;
      double reembolsos = _reembolsos() ?? 0.0;
      print('SUSCRIPCION:  ${suscripcion()}');
      print('APORTACIONES: $aportaciones');
      print('REEMBOLSOS: $reembolsos');
      twr = (resultado()! - suscripcion()! + reembolsos - aportaciones) /
          suscripcion()!;
    }
    return twr;
  }*/

  /// TWR: para cada operación:
  ///   1. calcular rpn
  ///       Valor Final = Valor Actual + Valor Operación
  ///       rpn = (Valor Final - Valor Inicial - Valor Operación) / Valor Inicial
  ///   2. calcular TWR
  ///       twr = (1 + rpn) * (1 * rpn) * ... - 1
  double? twr() {
    double? twr;
    List<double> rpnList = [];
    List<Valor> operaciones = [];
    for (var valor in valores.reversed) {
      if (valor.tipo == 1 || valor.tipo == 0) {
        operaciones.add(valor);
      }
    }
    if (valores.reversed.last.tipo != 1 || valores.reversed.last.tipo != 0) {
      operaciones.add(valores.reversed.last);
    }
    if (operaciones.isNotEmpty) {
      for (int i = 0; i < operaciones.length; i++) {
        var op = operaciones[i];
        if (i == 0) {
          var rpn = 0.0;
          rpnList.add(rpn + 1);
        } else {
          double valorFinal =
              (operaciones[i - 1].participaciones! * op.precio) +
                  (op.participaciones! * op.precio);
          double valorInicial =
              (operaciones[i - 1].participaciones! * operaciones[i - 1].precio);
          double valorOp = op.participaciones! * op.precio;
          var rpn = (valorFinal - valorInicial - valorOp) / valorInicial;
          rpnList.add(rpn + 1);
        }
      }
      var rpnProducto = 1.0;
      for (var rpn in rpnList) {
        rpnProducto *= rpn;
      }
      twr = rpnProducto - 1;
    }
    return twr;
  }
}
