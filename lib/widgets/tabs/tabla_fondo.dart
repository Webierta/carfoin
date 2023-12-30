import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cartera.dart';
import '../../models/cartera_provider.dart';
import '../../services/database_helper.dart';
import '../../themes/styles_theme.dart';
import '../../utils/fecha_util.dart';
import '../../utils/number_util.dart';
import '../background_dismissible.dart';

class TablaFondo extends StatefulWidget {
  const TablaFondo({super.key});
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

    changeSort() {
      if (!_isSortDesc) {
        valores.sort((a, b) => b.date.compareTo(a.date));
      } else {
        valores.sort((a, b) => a.date.compareTo(b.date));
      }
      setState(() => _isSortDesc = !_isSortDesc);
    }

    Text diferencia(Valor valor) {
      int index = _isSortDesc ? 1 : -1;
      bool condition = _isSortDesc
          ? valores.length > (valores.indexOf(valor) + 1)
          : valores.length > (valores.indexOf(valor) - 1) &&
              valores.indexOf(valor) > 0;
      if (condition) {
        var dif = valor.precio - valores[valores.indexOf(valor) + index].precio;
        return Text(
          NumberUtil.decimalFixed(dif, long: false),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColor.textRedGreen(dif)),
        );
      }
      return const Text('');
    }

    Widget getId(int? tipo, int index) {
      getTxt() {
        return Text(
          _isSortDesc ? '${valores.length - index}' : '${index + 1}',
          textAlign: TextAlign.center,
        );
      }

      if (tipo == 1 || tipo == 0) {
        return CircleAvatar(
          backgroundColor: tipo == 1 ? AppColor.verde : AppColor.rojo,
          foregroundColor: AppColor.negro,
          child: getTxt(),
        );
      }
      return getTxt();
    }

    return valores.isEmpty
        ? const Center(child: Text('Sin datos'))
        : Column(
            children: [
              Container(
                color: AppColor.ambar,
                child: Row(
                  children: [
                    Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: const Icon(Icons.swap_vert,
                              color: AppColor.light900),
                          onPressed: () => changeSort(),
                        )),
                    const Expanded(
                        flex: 3,
                        child: Text(
                          'FECHA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColor.light900),
                        )),
                    const Expanded(
                        flex: 3,
                        child: Text(
                          'PRECIO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColor.light900),
                        )),
                    const Expanded(
                        flex: 2,
                        child: Text(
                          '+/-',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColor.light900),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 10),
                  separatorBuilder: (context, index) => const Divider(
                      color: AppColor.gris,
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
                        background: const BackgroundDismissible(
                          slide: Slide.left,
                          label: 'Eliminar',
                          icon: Icons.highlight_remove,
                          marginVertical: 0.0,
                        ),
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
                                  child: getId(valores[index].tipo, index)),
                              Expanded(
                                  flex: 3,
                                  child: Text(
                                    FechaUtil.epochToString(
                                        valores[index].date),
                                    textAlign: TextAlign.center,
                                  )),
                              Expanded(
                                  flex: 3,
                                  child: Text(
                                    NumberUtil.decimalFixed(
                                        valores[index].precio,
                                        long: false),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16),
                                  )),
                              Expanded(
                                flex: 2,
                                child: diferencia(valores[index]),
                              ),
                            ],
                          ),
                        ));
                  },
                ),
              ),
            ],
          );
  }
}
