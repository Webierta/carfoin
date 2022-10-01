enum StatusApiService {
  inactive,
  okHttp,
  errorHttp,
  tiempoOut,
  noInternet,
  error
}

extension StatusApiServiceExtension on StatusApiService {
  String get msg {
    switch (this) {
      case StatusApiService.okHttp:
        return 'Fondo actualizado';
      case StatusApiService.errorHttp:
      case StatusApiService.error:
        return 'Fondo no actualizado: Sin respuesta del servidor';
      case StatusApiService.tiempoOut:
        return 'Fondo no actualizado: Tiempo excedido sin respuesta del servidor';
      case StatusApiService.noInternet:
        return 'Fondo no actualizado: Sin respuesta del servidor. Comprueba tu conexión a internet';
      default:
        return '';
    }
  }
}
