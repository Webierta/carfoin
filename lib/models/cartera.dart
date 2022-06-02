class Cartera {
  final int? id;
  final String name;
  List<Fondo>? fondos;

  Cartera({this.id, required this.name, this.fondos}) {
    fondos ??= [];
  }

  Cartera.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        fondos = map['fondos'];

  Map<String, Object?> toDb() {
    return {'id': id, 'name': name};
  }
}

class Fondo {
  final String isin;
  final String name;
  String? divisa;
  List<Valor>? valores;

  Fondo({required this.isin, required this.name, this.divisa, this.valores}) {
    divisa ??= '';
    valores ??= [];
  }

  Fondo.fromMap(Map<String, dynamic> map)
      : isin = map['isin'],
        name = map['name'],
        divisa = map['divisa'],
        valores = map['valores'];

  Map<String, Object?> toDb() {
    return {'isin': isin, 'name': name, 'divisa': divisa};
  }

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
