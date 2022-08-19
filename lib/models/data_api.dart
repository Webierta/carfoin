import 'dart:convert';

DataApi dataApiFromJson(String str) => DataApi.fromJson(json.decode(str));

String dataApiToJson(DataApi data) => json.encode(data.toJson());

class DataApi {
  String name;
  String market;
  double price;
  DateTime humanDate;
  int epochSecs;
  DataApi(
      {required this.name,
      required this.market,
      required this.price,
      required this.humanDate,
      required this.epochSecs});

  factory DataApi.fromJson(Map<String, dynamic> json) => DataApi(
        name: json["name"],
        market: json["market"],
        price: json["price"].toDouble(),
        humanDate: DateTime.parse(json["humanDate"]),
        epochSecs: json["epochSecs"],
      );

  Map<String, dynamic> toJson() {
    String year = humanDate.year.toString().padLeft(4, '0');
    String month = humanDate.month.toString().padLeft(2, '0');
    String day = humanDate.day.toString().padLeft(2, '0');
    return {
      "name": name,
      "market": market,
      "price": price,
      "humanDate": "$year-$month-$day",
      "epochSecs": epochSecs,
    };
  }
}

List<DataApiRange> dataApiRangeFromJson(String str) => List<DataApiRange>.from(
    json.decode(str).map((x) => DataApiRange.fromJson(x)));

String dataApiRangeToJson(List<DataApiRange> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DataApiRange {
  DateTime humanDate;
  int epochSecs;
  double price;
  DataApiRange({
    required this.humanDate,
    required this.epochSecs,
    required this.price,
  });

  factory DataApiRange.fromJson(Map<String, dynamic> json) => DataApiRange(
        humanDate: DateTime.parse(json["humanDate"]),
        epochSecs: json["epochSecs"],
        price: json["price"].toDouble(),
      );

  Map<String, dynamic> toJson() {
    String year = humanDate.year.toString().padLeft(4, '0');
    String month = humanDate.month.toString().padLeft(2, '0');
    String day = humanDate.day.toString().padLeft(2, '0');
    return {
      "humanDate": "$year-$month-$day",
      "epochSecs": epochSecs,
      "price": price,
    };
  }
}
