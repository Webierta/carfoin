class Cartera {
  final int id;
  final String name;
  List<Fondo>? fondos;
  Cartera({required this.id, required this.name, this.fondos}) {
    fondos ??= [];
  }

  Cartera.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        fondos = map['fondos'];

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'fondos': fondos};
  }
}

class Fondo {
  final String isin;
  final String name;
  String? divisa;
  List<Valor>? valores;

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

  Fondo({required this.isin, required this.name, this.divisa, this.valores}) {
    valores ??= [];
  }
}

class Valor {
  final int date;
  final double precio;
  int? tipo;
  double? participaciones;
  Valor({required this.date, required this.precio, this.tipo, this.participaciones});
}
