class Cartera {
  final int? id;
  String name;
  List<Fondo>? fondos;
  Cartera({this.id, required this.name, this.fondos}) {
    fondos ??= [];
  }

  //List<Fondo> fondos;
  //Cartera({this.id, required this.name, this.fondos = []});

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
  int? rating;
  Fondo(
      {required this.isin,
      required this.name,
      this.divisa,
      this.valores,
      this.rating}) {
    divisa ??= '';
    valores ??= [];
    rating ??= 0;
  }

  Fondo.fromMap(Map<String, dynamic> map)
      : isin = map['isin'],
        name = map['name'],
        divisa = map['divisa'],
        valores = map['valores'],
        rating = map['rating'];

  Map<String, Object?> toDb() {
    return {'isin': isin, 'name': name, 'divisa': divisa, 'rating': rating};
  }

  /*double? precioMinimo;
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
  double? tae;*/
}

class Valor {
  final int date;
  final double precio;
  int? tipo;
  double? participaciones;

  Valor({
    required this.date,
    required this.precio,
    this.tipo,
    this.participaciones,
  }) {
    tipo ??= -1;
    participaciones ??= 0;
  }

  Valor.fromMap(Map<String, dynamic> map)
      : date = map['date'],
        precio = map['precio'],
        tipo = map['tipo'],
        participaciones = map['participaciones'];

  Map<String, Object?> toDb() {
    return {
      'date': date,
      'precio': precio,
      'tipo': tipo,
      'participaciones': participaciones
    };
  }
}
