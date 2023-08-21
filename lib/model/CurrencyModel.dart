class CurrencyModel {
  String code;

  String id;

  bool isactive;

  num rounding;

  String name;

  String symbol;

  bool symbolatright;

  CurrencyModel({
    this.code = '',
    this.isactive = false,
    this.id = '',
    this.name = '',
    this.rounding = 0,
    this.symbol = '',
    this.symbolatright = false,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> parsedJson) {
    return CurrencyModel(
      code: parsedJson['code'] ?? '',
      isactive: parsedJson['isActive'] ?? '',
      id: parsedJson['id'] ?? '',
      name: parsedJson['name'] ?? '',
      rounding: parsedJson['rounding'] ?? 0,
      symbol: parsedJson['symbol'] ?? '',
      symbolatright: parsedJson['symbolAtRight'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'isActive': isactive,
      'rounding': rounding,
      'id': id,
      'name': name,
      'symbol': symbol,
      'symbolAtRight': symbolatright,
    };
  }
}
