import '../models/cartera.dart';
import '../widgets/subglobal/models.dart';
import 'stats.dart';

class StatsGlobal {
  final double rateExchange;
  StatsGlobal({required this.rateExchange});

  int nFondos = 0;
  List<Destacado> destacados = [];
  List<LastOp> lastOps = [];
  double inversionGlobal = 0.0;
  double valorGlobal = 0.0;
  double balanceGlobal = 0.0;

  void calcular(List<Cartera> carteras) {
    nFondos = 0;
    destacados = [];
    lastOps = [];
    inversionGlobal = 0.0;
    valorGlobal = 0.0;
    balanceGlobal = 0.0;

    for (var cartera in carteras) {
      double inversionGlobalEur = 0.0;
      double inversionGlobalUsd = 0.0;
      double inversionGlobalOtra = 0.0;
      double valorGlobalEur = 0.0;
      double valorGlobalUsd = 0.0;
      double valorGlobalOtra = 0.0;
      double balanceGlobalEur = 0.0;
      double balanceGlobalUsd = 0.0;
      double balanceGlobalOtra = 0.0;

      List<Fondo> fondos = cartera.fondos ?? [];
      nFondos += fondos.length;
      if (fondos.isNotEmpty) {
        for (var fondo in fondos) {
          if (fondo.valores != null && fondo.valores!.isNotEmpty) {
            Stats stats = Stats(fondo.valores!);
            double participacionesFondo = stats.totalParticipaciones() ?? 0.0;
            if (participacionesFondo > 0) {
              double? twr = stats.twr();
              if (twr != null) {
                destacados.add(Destacado(
                    cartera: cartera,
                    fondo: fondo,
                    tae: stats.anualizar(twr)!));
              }
              List<Valor>? operaciones = fondo.valores
                  ?.where((v) => v.tipo == 1 || v.tipo == 0)
                  .toList();
              if (operaciones != null && operaciones.isNotEmpty) {
                // ORDENAR OPERACIONES POR DATE ??
                var lastOp = operaciones.first;
                lastOps
                    .add(LastOp(cartera: cartera, fondo: fondo, valor: lastOp));
                if (operaciones.length > 1) {
                  var lastOp2 = operaciones[1];
                  lastOps.add(
                      LastOp(cartera: cartera, fondo: fondo, valor: lastOp2));
                }
              }
              if (fondo.divisa == 'EUR') {
                inversionGlobalEur += stats.inversion() ?? 0.0;
                valorGlobalEur += stats.resultado() ?? 0.0;
                balanceGlobalEur += stats.balance() ?? 0.0;
              } else if (fondo.divisa == 'USD') {
                inversionGlobalUsd += stats.inversion() ?? 0.0;
                valorGlobalUsd += stats.resultado() ?? 0.0;
                balanceGlobalUsd += stats.balance() ?? 0.0;
              } else {
                inversionGlobalOtra += stats.inversion() ?? 0.0;
                valorGlobalOtra += stats.resultado() ?? 0.0;
                balanceGlobalOtra += stats.balance() ?? 0.0;
              }
            }
          }
        }
      }
      inversionGlobal += inversionGlobalEur +
          inversionGlobalOtra +
          (inversionGlobalUsd * rateExchange);
      valorGlobal +=
          valorGlobalEur + valorGlobalOtra + (valorGlobalUsd * rateExchange);
      balanceGlobal += balanceGlobalEur +
          balanceGlobalOtra +
          (balanceGlobalUsd * rateExchange);
    }

    if (destacados.isNotEmpty) {
      destacados.sort((a, b) => a.tae.compareTo(b.tae));
    }
    if (lastOps.isNotEmpty) {
      lastOps.sort((a, b) => a.valor.date.compareTo(b.valor.date));
    }
  }
}
