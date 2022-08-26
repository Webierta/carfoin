import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../router/routes_const.dart';
import '../utils/konstantes.dart';

class PageInfoBalance extends StatelessWidget {
  const PageInfoBalance({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        decoration: scaffoldGradient,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => context.go(fondoPage),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('ÍNDICES Y CÁLCULOS'),
          ),
          body: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Markdown(
              data: mdstring,
            ),
          ),
        ),
      ),
    );
  }
}

const String mdstring = """

## INVERSIÓN

Capital global dedicado al Fondo considerando el **importe inicial suscrito** más las **aportaciones** menos los **reembolsos** realizados.

## RESULTADO

Importe actual del Fondo. **Valor** de tu participación en el Fondo según el último precio descargado.

## RENDIMIENTO

Balance calculado por la diferencia entre el **resultado** obtenido y la **inversión** realizada.

## RENTABILIDAD

**Rentabilidad acumulada** desde la suscripción del Fondo. Se calcula como la proporción entre el **rendimiento** y la **inversión** realizada.

Se trata de un índice muy básico que solo es fiable cuando existe una única aportación inicial que se mantiene en el tiempo sin incorporar aportaciones o reembolsos.

## TAE

Índice anualizado de la rentabilidad acumulada (con sus mismas limitaciones). 

## RENTABILIDAD TWR (*Time Weighted Return*)

Índice de rentabilidad ponderada por el tiempo, adecuado cuando se producen situaciones de entradas o retiradas de dinero en una cartera para poder calcular la rentabilidad de forma más precisa.

Resulta útil para comparar la rentabilidad de un Fondo o una Cartera con las rentabilidades de otros fondos o carteras, aunque lo ideal es tener los valores diarios del fondo o al menos mensuales.

Para calcularlo primero se obtienen las rentabilidades de cada uno de los subperiodos que existen entre los flujos de efectivo (operaciones de aportación o reembolso):

```
RENTABILIDAD PERIODO (RP) = (VALOR FINAL - VALOR INICIAL - VALOR OPERACIÓN) / VALOR INICIAL

RENTABILIDAD TWR = (1 + RP) x (1 + RP) x … – 1
```

## TWR ANUAL

Rentabilidad TWR anualizada.

## RENTABILIDAD MWR (*Money Weighted Return*)

Índice de rentabilidad ponderanda por el dinero que básicamente informa sobre si se ha ganado o no dinero con el Fondo.

Mide lo que realmente has hecho crecer tu dinero considerando la cantidad de dinero invertido, el tiempo que lo has tenido y a qué interés o rendimiento para obtener ese dinero.

Resulta muy variable en función de los movimientos de efectivo y los momentos en que se han realizado.

## MWR ANUAL

Rentabilidad MWR anualizada.

> Únicamente cuando no existen entradas y salidas de capital del Fondo las rentabilidades obtenidas por estos métodos son iguales.


""";
