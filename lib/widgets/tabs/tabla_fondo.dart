import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cartera.dart';
import '../../models/cartera_provider.dart';
import '../../services/database_helper.dart';
import '../../utils/fecha_util.dart';
import '../../utils/styles.dart';

class TablaFondo extends StatefulWidget {
  const TablaFondo({Key? key}) : super(key: key);

  @override
  State<TablaFondo> createState() => _TablaFondoState();
}

class _TablaFondoState extends State<TablaFondo> {
  bool _isSortDesc = true;
  DatabaseHelper database = DatabaseHelper();
  late CarteraProvider carteraProvider;
  late Cartera carteraSelect;
  late Fondo fondoSelect;
  late List<Valor> valoresSelect;
  late List<Valor> operacionesSelect;

  setValores(Cartera cartera, Fondo fondo) async {
    carteraProvider.valores = await database.getValores(cartera, fondo);
    fondo.valores = carteraProvider.valores;
    valoresSelect = carteraProvider.valores;

    carteraProvider.operaciones = await database.getOperaciones(cartera, fondo);
    operacionesSelect = carteraProvider.operaciones;
  }

  @override
  void initState() {
    carteraProvider = context.read<CarteraProvider>();
    carteraSelect = carteraProvider.carteraSelect;
    fondoSelect = carteraProvider.fondoSelect;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await setValores(carteraSelect, fondoSelect);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final valores = context.watch<CarteraProvider>().valores;

    _changeSort() {
      if (!_isSortDesc) {
        valores.sort((a, b) => b.date.compareTo(a.date));
      } else {
        valores.sort((a, b) => a.date.compareTo(b.date));
      }
      setState(() => _isSortDesc = !_isSortDesc);
    }

    Text _diferencia(Valor valor) {
      int index = _isSortDesc ? 1 : -1;
      bool condition = _isSortDesc
          ? valores.length > (valores.indexOf(valor) + 1)
          : valores.length > (valores.indexOf(valor) - 1) &&
              valores.indexOf(valor) > 0;
      if (condition) {
        var dif = valor.precio - valores[valores.indexOf(valor) + index].precio;
        return Text(
          dif.toStringAsFixed(2),
          textAlign: TextAlign.center,
          style: TextStyle(color: textRedGreen(dif)),
        );
      }
      return const Text('');
    }

    Widget _getId(int? tipo, int index) {
      _getTxt() {
        return Text(
          _isSortDesc ? '${valores.length - index}' : '${index + 1}',
          textAlign: TextAlign.center,
        );
      }

      if (tipo == 1 || tipo == 0) {
        return CircleAvatar(
          backgroundColor:
              tipo == 1 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
          //const Color(0xFFF44336) : const Color(0xFF4CAF50))
          child: _getTxt(),
        );
      }
      return _getTxt();
    }

    return valores.isEmpty
        ? const Center(child: Text('Sin datos'))
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFFFC107),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: const Icon(Icons.swap_vert),
                            onPressed: () => _changeSort(),
                          )),
                      const Expanded(
                          flex: 3,
                          child: Text(
                            'FECHA',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                      const Expanded(
                          flex: 3,
                          child: Text(
                            'PRECIO',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                      const Expanded(
                          flex: 2,
                          child: Text(
                            '+/-',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )),
                      /*const Expanded(
                        flex: 1,
                        child: Text(''),
                      ),*/
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 10),
                    separatorBuilder: (context, index) => const Divider(
                        color: Color(0xFF9E9E9E),
                        height: 4,
                        indent: 10,
                        endIndent: 10),
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: valores.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                          key: UniqueKey(),
                          direction: DismissDirection.endToStart,
                          background: bgDismissible,
                          /*background: Container(
                            color: Colors.red,
                            margin: const EdgeInsets.symmetric(horizontal: 15),
                            //alignment: Alignment.centerRight,
                            alignment: AlignmentDirectional.centerEnd,
                            child: const Padding(
                              padding: EdgeInsets.fromLTRB(0.0, 0.0, 10.0, 0.0),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),*/
                          onDismissed: (_) async {
                            //var carfoin = context.read<CarfoinProvider>();
                            //await carfoin.eliminarValor(valoresOn[index].date);
                            //await carfoin.updateValores();
                            //final carteraProvider = context.read<CarteraProvider>();
                            /// TODO...
                            await database.deleteValor(
                                carteraSelect, fondoSelect, valores[index]);
                            await setValores(carteraSelect, fondoSelect);
                            //PageFondo page = PageFondo().eliminarValor() ;
                          },
                          child: SizedBox(
                            height: 30,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _getId(valores[index].tipo, index),
                                ),
                                Expanded(
                                    flex: 3,
                                    child: Text(
                                      //_epochFormat(valoresCopy[index].date),
                                      FechaUtil.epochToString(
                                          valores[index].date),
                                      textAlign: TextAlign.center,
                                    )),
                                Expanded(
                                    flex: 3,
                                    child: Text(
                                      '${valores[index].precio}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16),
                                    )),
                                Expanded(
                                  flex: 2,
                                  child: _diferencia(valores[index]),
                                ),
                                /*Expanded(
                                  flex: 1,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      print('EDITAR');
                                    },
                                  ),
                                )*/
                              ],
                            ),
                          ));
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
