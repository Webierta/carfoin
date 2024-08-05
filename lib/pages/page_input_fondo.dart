import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/cartera.dart';
import '../models/cartera_provider.dart';
import '../services/yahoo_finance.dart';
import '../themes/styles_theme.dart';
import '../themes/theme_provider.dart';
import '../widgets/dialogs/custom_messenger.dart';

enum Options { isin, nombre }

class PageInputFondo extends StatefulWidget {
  const PageInputFondo({super.key});
  @override
  State<PageInputFondo> createState() => _PageInputFondoState();
}

class _PageInputFondoState extends State<PageInputFondo> {
  late TextEditingController _controller;
  //late ApiService apiService;
  bool? _validIsin;
  Fondo? locatedFond;
  bool _buscando = false;
  bool? _errorDataApi;
  TextEditingController controllerName = TextEditingController();
  List<String> nombreFondos = [];
  List<Fondo> fondosSugeridos = [];
  Options selectedOption = Options.isin;
  bool searchingNames = false;

  @override
  void initState() {
    _controller = TextEditingController();
    //apiService = ApiService();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    controllerName.dispose();
    _validIsin = null;
    _errorDataApi = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Provider.of<ThemeProvider>(context).darkTheme;
    Cartera carteraSelect = context.read<CarteraProvider>().carteraSelect;

    return Container(
      decoration: darkTheme ? AppBox.darkGradient : AppBox.lightGradient,
      child: Scaffold(
        appBar: AppBar(title: const Text('Añadir Fondo')),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            children: [
              Chip(
                avatar: const Icon(Icons.business_center),
                label: Text(carteraSelect.name),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity:
                        const VisualDensity(horizontal: -1, vertical: -1),
                    //fixedSize: MaterialStateProperty.all(Size.fromWidth(50)),
                  ),
                  segments: <ButtonSegment<Options>>[
                    ButtonSegment<Options>(
                      value: Options.isin,
                      label: Text(Options.isin.name.toUpperCase()),
                    ),
                    ButtonSegment<Options>(
                      value: Options.nombre,
                      label: Text(Options.nombre.name.toUpperCase()),
                    ),
                  ],
                  selected: <Options>{selectedOption},
                  onSelectionChanged: (Set<Options> newSelection) {
                    setState(() {
                      selectedOption = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              if (selectedOption == Options.isin) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Introduce el ISIN del nuevo Fondo:'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                onChanged: (text) {
                                  setState(() {
                                    _validIsin = null;
                                    _errorDataApi = null;
                                  });
                                },
                                textCapitalization:
                                    TextCapitalization.characters,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp('[a-zA-Z0-9]'))
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'ISIN',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            _resultIsValid(),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.security),
                              label: const Text('Validar'),
                              onPressed: _controller.text.isNotEmpty
                                  ? () => setState(() => _validIsin =
                                      _checkIsin(_controller.value.text))
                                  : null,
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.search),
                              label: const Text('Buscar'),
                              onPressed: _controller.text.isEmpty
                                  ? null
                                  : () async {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      if (_checkIsin(_controller.value.text)) {
                                        setState(() {
                                          _validIsin = true;
                                          _buscando = true;
                                        });
                                        locatedFond = await _searchIsin(
                                            _controller.value.text);
                                        setState(() => _buscando = false);
                                      } else {
                                        setState(() => _validIsin = false);
                                        showMsg(
                                          msg: 'Código ISIN no válido',
                                          color: AppColor.rojo900,
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _resultSearch(),
              ],
              if (selectedOption == Options.nombre) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Introduce parte del nombre del Fondo:'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controllerName,
                              ),
                            ),
                            MaterialButton(
                              onPressed: () async {
                                FocusManager.instance.primaryFocus?.unfocus();
                                if (controllerName.text.trim().length > 3) {
                                  setState(() => searchingNames = true);
                                  /* List<String> listaFondos =
                                      await YahooFinance().getFondoByName(
                                          controllerName.text.trim());
                                  if (listaFondos.isNotEmpty) {
                                    List<Fondo> searchIsinYahoo =
                                        await YahooFinance()
                                            .searchIsin(listaFondos); */
                                  List<Fondo> listaFondos = await YahooFinance()
                                      .getFondosByName(
                                          controllerName.text.trim());
                                  //if (listaFondos.isNotEmpty) {
                                  setState(() => fondosSugeridos = listaFondos);
                                  //}
                                  setState(() => searchingNames = false);
                                } else {
                                  showMsg(
                                    msg: 'Dame alguna pista más',
                                    color: AppColor.rojo900,
                                  );
                                }
                              },
                              child: const Icon(Icons.search),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (searchingNames == true) const CircularProgressIndicator(),
                if (searchingNames == false && fondosSugeridos.isEmpty)
                  const Text('Sin resultados'),
                if (searchingNames == false && fondosSugeridos.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: fondosSugeridos.length,
                      itemBuilder: (context, index) {
                        Fondo fondo = fondosSugeridos[index];
                        String isin = fondo.isin.isEmpty
                            ? 'ISIN no encontrado'
                            : fondo.isin;
                        String divisa = fondo.divisa ?? '';
                        return Card(
                          key: ValueKey(fondosSugeridos[index].isin),
                          color: AppColor.ambar,
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: ListTile(
                            enabled: fondo.isin.isNotEmpty,
                            title: Text(
                              fondo.name,
                              style: const TextStyle(
                                color: AppColor.negro,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  isin,
                                  style: const TextStyle(
                                    color: AppColor.gris700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  divisa,
                                  style: const TextStyle(
                                    color: AppColor.gris700,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context, fondo);
                            },
                            trailing: Icon(fondo.isin.isEmpty
                                ? Icons.block_outlined
                                : Icons.add_circle_outline),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Icon _resultIsValid() {
    if (_validIsin == true) {
      return const Icon(Icons.check_box, color: AppColor.verde);
    } else if (_validIsin == false) {
      return const Icon(Icons.disabled_by_default, color: AppColor.rojo);
    } else {
      return const Icon(Icons.check_box_outline_blank);
    }
  }

  Widget _resultSearch() {
    if (_buscando) {
      return const Center(child: CircularProgressIndicator());
    } else {
      if (_errorDataApi == false) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locatedFond!.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('¿Añadir a la cartera?'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () {
                          setState(() {
                            _validIsin = null;
                            _errorDataApi = null;
                          });
                        }),
                    TextButton(
                        child: const Text('Aceptar'),
                        onPressed: () {
                          var fondo = Fondo(
                            name: locatedFond!.name,
                            isin: locatedFond!.isin,
                            divisa: locatedFond!.divisa,
                            valores: locatedFond!.valores,
                            ticker: locatedFond!.ticker,
                          );
                          Navigator.pop(context, fondo);
                        }),
                  ],
                ),
              ],
            ),
          ),
        );
      } else if (_errorDataApi == true) {
        return const Center(child: Text('Fondo no encontrado'));
      } else {
        return const Text('');
      }
    }
  }

  bool _checkIsin(String inputIsin) {
    var isin = inputIsin.trim().toUpperCase();
    if (isin.length != 12) {
      return false;
    }
    RegExp regExp = RegExp("^[A-Z]{2}[A-Z0-9]{9}");
    if (!regExp.hasMatch(isin)) {
      return false;
    }
    var digitos = <int>[];
    for (var char in isin.codeUnits) {
      if (char >= 65 && char <= 90) {
        final value = char - 55;
        digitos.add(value ~/ 10);
        digitos.add(value % 10);
      } else if (char >= 48 && char <= 57) {
        digitos.add(char - 48);
      } else {
        return false;
      }
    }
    digitos.removeLast();
    digitos = digitos.reversed.toList();
    var suma = 0;
    digitos.asMap().forEach((index, value) {
      if (index.isOdd) {
        suma += value;
      } else {
        var doble = value * 2;
        suma += doble < 9 ? doble : (doble ~/ 10) + (doble % 10);
      }
    });
    var valor = ((suma / 10).ceil() * 10);
    var dc = valor - suma;
    if (dc != int.parse(isin[11])) {
      return false;
    } else {
      return true;
    }
  }

  Future<Fondo> _searchIsin(String inputIsin) async {
    final Fondo? getFondo = await YahooFinance().getFondoByIsin(inputIsin);
    if (getFondo != null) {
      setState(() => _errorDataApi = false);
      return getFondo;
    } else {
      setState(() => _errorDataApi = true);
      return Fondo(name: 'Fondo no encontrado', isin: inputIsin);
    }
  }

  void showMsg({required String msg, Color? color}) =>
      CustomMessenger(context: context, msg: msg, color: color)
          .generateDialog();
}
