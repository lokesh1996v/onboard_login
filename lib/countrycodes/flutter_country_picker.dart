import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dimension.dart';
import 'country.dart';

export 'country.dart';

Future<List<Country>> _fetchLocalizedCountryNames() async {
  List<Country> renamed = [];
  var isoCodes = <String>[];
  Country.ALL.forEach((Country country) {
    isoCodes.add(country.isoCode);
  });

  for (var country in Country.ALL) {
    renamed.add(country);
  }
  renamed.sort(
      (Country a, Country b) => a.name.compareTo(b.name));

  return renamed;
}

/// The country picker widget exposes an dialog to select a country from a
/// pre defined list, see [Country.ALL]
class CountryPicker extends StatelessWidget {
  const CountryPicker({
    Key? key,
    this.selectedCountry,
    required this.onChanged,
    this.dense = false,
    this.showDialingCode = false,
    this.showName = true,
  }) : super(key: key);

  final Country? selectedCountry;
  final ValueChanged<Country> onChanged;
  final bool dense;
  final bool showDialingCode;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Country? displayCountry = selectedCountry;

    displayCountry ??= Country.findByIsoCode(Localizations.localeOf(context).countryCode??"");

    return dense
        ? _renderDenseDisplay(context, displayCountry!)
        : _renderDefaultDisplay(context, displayCountry!);
  }

  _renderDefaultDisplay(BuildContext context, Country displayCountry) {
    return InkWell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
              child: showDialingCode
                  ? Text(
                      " (+${displayCountry.dialingCode})",
                      style: const TextStyle(fontSize: 18.0, color: Colors.black),
                    )
                  : Container()),
          Icon(Icons.arrow_drop_down,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : Colors.grey),
        ],
      ),
      onTap: () {
        _selectCountry(context, displayCountry);
      },
    );
  }

  _renderDenseDisplay(BuildContext context, Country displayCountry) {
    return InkWell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(Icons.arrow_drop_down,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade700
                  : Colors.white70),
        ],
      ),
      onTap: () {
        _selectCountry(context, displayCountry);
      },
    );
  }

  Future<Null> _selectCountry(
      BuildContext context, Country defaultCountry) async {
    final Country? picked = await showCountryPicker(
      context: context,
      defaultCountry: defaultCountry,
    );

    if (picked != null && picked != selectedCountry) onChanged(picked);
  }
}

/// Display an [Dialog] with the country list to selection
/// you can pass and [defaultCountry], see [Country.findByIsoCode]
Future<Country?> showCountryPicker({
  required BuildContext context,
  Country? defaultCountry,
}) async {
  // assert(Country.findByIsoCode(defaultCountry.isoCode) != null);

  return await showDialog<Country>(
    context: context,
    builder: (BuildContext context) => _CountryPickerDialog(
          defaultCountry: defaultCountry,
        ),
  );
}

class _CountryPickerDialog extends StatefulWidget {
  const _CountryPickerDialog({
    Key? key,
    Country? defaultCountry,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  TextEditingController controller = new TextEditingController();
  String? filter;
  late List<Country> countries;

  @override
  void initState() {
    super.initState();

    countries = Country.ALL;

    _fetchLocalizedCountryNames().then((renamed) {
      setState(() {
        countries = renamed;
      });
    });

    controller.addListener(() {
      setState(() {
        filter = controller.text;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: Dimension.scalePixel(98),
          child: Card(
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          hintText: MaterialLocalizations.of(context).searchFieldLabel,
                          prefixIcon: const Icon(Icons.search),
                          // suffixIcon: filter == null || filter == ""
                          //     ? Container(
                          //         height: 0.0,
                          //         width: 0.0,
                          //       )
                          //     : InkWell(
                          //         child: Icon(Icons.clear),
                          //         onTap: () {
                          //           controller.clear();
                          //         },
                          //       ),
                        ),
                        controller: controller,
                      ),
                    ),
                    const CloseButton()
                  ],
                ),
                const Divider(height: 1,),
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: countries.length,
                      itemBuilder: (BuildContext context, int index) {
                        Country country = countries[index];
                        if (filter == null ||
                            filter == "" ||
                            country.name
                                .toLowerCase()
                                .contains(filter!.toLowerCase()) ||
                            country.isoCode.contains(filter??"--")) {
                          return InkWell(
                            child: ListTile(
                              trailing: Text("+ ${country.dialingCode}"),
                              title: Container(
                                margin: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  country.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context, country);
                            },
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
