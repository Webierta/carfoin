class SymbolYahoo {
  final String symbol;
  SymbolYahoo({required this.symbol});

  factory SymbolYahoo.fromJson(Map<String, dynamic> json) {
    final symbolJson = json['quotes'][0]['symbol']; // dynamic
    return SymbolYahoo(symbol: symbolJson);
  }
}

class SearchNameSymbol {
  final Map<String, String> mapSymbolName;
  SearchNameSymbol({required this.mapSymbolName});

  factory SearchNameSymbol.fromJson(Map<String, dynamic> json) {
    var listaFondos = [];
    final listaQuotes = json['quotes'];
    for (var quote in listaQuotes) {
      if (quote['typeDisp'] == 'Fund') {
        listaFondos.add(quote);
      }
    }
    //List<String> nombreFondos = [];
    Map<String, String> symbolName = {};
    for (var quote in listaFondos) {
      //nombreFondos.add(quote['longname']);
      symbolName[quote['symbol']] = quote['longname'];
    }
    return SearchNameSymbol(mapSymbolName: symbolName);
  }
}

class SearchByName {
  final List<String> listaFondos;
  SearchByName({required this.listaFondos});

  factory SearchByName.fromJson(Map<String, dynamic> json) {
    var listaFondos = [];
    final listaQuotes = json['quotes'];
    for (var quote in listaQuotes) {
      if (quote['typeDisp'] == 'Fund') {
        listaFondos.add(quote);
      }
    }
    List<String> nombreFondos = [];
    for (var quote in listaFondos) {
      nombreFondos.add(quote['longname']);
    }
    return SearchByName(listaFondos: nombreFondos);
  }
}

class DataYahoo {
  final String symbol;
  final String name;
  final int fecha;
  final double valor;
  final String divisa;

  DataYahoo(
      {required this.symbol,
      required this.name,
      required this.fecha,
      required this.valor,
      required this.divisa});

  factory DataYahoo.fromJson(Map<String, dynamic> json) {
    final quote = json['optionChain']['result'][0]['quote'];
    final symbolJson = quote['symbol'] as String;
    final nameJson = quote['longName'] as String;
    final fechaJson = quote['regularMarketTime'] as int;
    final valorJson = quote['regularMarketPrice'] as double;
    final divisaJson = quote['currency'] as String;
    return DataYahoo(
      symbol: symbolJson,
      name: nameJson,
      divisa: divisaJson,
      fecha: fechaJson,
      valor: valorJson,
    );
  }
}
