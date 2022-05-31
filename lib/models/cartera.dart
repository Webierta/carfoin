class Cartera {
  final int id;
  final String name;
  Cartera({required this.id, required this.name});

  List<Fondo> fondos = [];
}

class Fondo {
  final String isin;
  final String name;
  String? divisa;
  Fondo({required this.isin, required this.name, this.divisa});

  List<Valor> valores = [];

  double? precioMinimo;
  double? precioMaximo;
  double? precioMedio;
  int? dateMinimo;
  int? dateMaximo;
  double? volatilidad;

  double? totalParticipaciones;
  double? inversion;
  double? resultado;
  double? balance;
  double? rentabilidad;
  double? tae;
}

class Valor {
  final int date;
  final double precio;
  int? tipo;
  double? participaciones;
  Valor({required this.date, required this.precio, this.tipo, this.participaciones});
}
