import 'dart:math' show pow;

class CashFlow {
  final double importe;
  final DateTime date;
  CashFlow({required this.importe, required this.date});
}

class CashFlowYear {
  final double importe;
  final double years;
  CashFlowYear({required this.importe, required this.years});
}

class CalculationWrapper {
  static double? xirr(List<CashFlow> cashflows,
      [int decimals = 6, double maxRate = 1000000]) {
    double? calculate;
    double precision = pow(10, -decimals).toDouble();
    double minRate = -(1 - precision).toDouble();
    XirrCalculator xirrCalculator = XirrCalculator(
      lowRate: minRate,
      highRate: maxRate,
      cashFlow: cashflows,
    );
    calculate = xirrCalculator.calculate(precision);
    return calculate;
  }
}

class XirrCalculator {
  final double lowRate;
  final double highRate;
  final List<CashFlow> cashFlow;

  late double _lowRate;
  late double _highRate;
  late List<CashFlowYear> _cashFlow;
  late double _lowResult;
  late double _highResult;

  XirrCalculator({
    required this.lowRate,
    required this.highRate,
    required this.cashFlow,
  }) {
    _lowRate = lowRate;
    _highRate = highRate;
    _cashFlow = _toCashFlowYear(cashFlow);
    _lowResult = _calcEquation(_cashFlow, _lowRate);
    _highResult = _calcEquation(_cashFlow, _highRate);
  }

  static List<CashFlowYear> _toCashFlowYear(List<CashFlow> cashFlows) {
    var firsDate = cashFlows.first.date;
    List<CashFlowYear> listCashFlowYear = [];
    for (var cf in cashFlows) {
      double years = (cf.date.difference(firsDate).inDays) / 365;
      listCashFlowYear.add(CashFlowYear(importe: cf.importe, years: years));
    }
    return listCashFlowYear;
  }

  static double _calcEquation(List<CashFlowYear> cashFlows, double rate) {
    double result = 0.0;
    for (var cf in cashFlows) {
      result += cf.importe / (pow((1 + rate), cf.years));
    }
    return result;
  }

  double? calculate(double precision) {
    double middleRate;
    double middleResult;
    var count = 1;
    do {
      if (_lowResult.sign == _highResult.sign) {
        return null;
      }
      middleRate = (_lowRate + _highRate) / 2;
      middleResult = _calcEquation(_cashFlow, middleRate);
      if (middleResult.sign == _lowResult.sign) {
        _lowRate = middleRate;
        _lowResult = middleResult;
      } else {
        _highRate = middleRate;
        _highResult = middleResult;
      }
      count++;
      if (count > 1000) {
        break;
      }
    } while (middleResult.abs() > precision);
    return (_highRate + _lowRate) / 2;
  }
}
