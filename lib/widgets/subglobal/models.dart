import '../../models/cartera.dart';

class CarteraFondo {
  final Cartera cartera;
  final Fondo fondo;
  const CarteraFondo({required this.cartera, required this.fondo});
}

class Destacado extends CarteraFondo {
  final double tae;
  const Destacado(
      {required super.cartera, required super.fondo, required this.tae});
}

class LastOp extends CarteraFondo {
  final Valor valor;
  const LastOp(
      {required super.cartera, required super.fondo, required this.valor});
}
