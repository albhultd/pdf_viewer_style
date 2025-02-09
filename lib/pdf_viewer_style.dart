import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// A PDF nézegető megjelenésének testreszabásához használt osztály.
class PdfViewerStyle {
  /// A nézegető konténerének dekorációja.
  /// Például keret nélküli megjelenítéshez: Border.fromBorderSide(BorderSide.none).
  final BoxDecoration? containerDecoration;

  /// A konténer belső margója.
  final EdgeInsets? padding;

  /// A konténer háttérszíne.
  final Color? backgroundColor;

  /// Opcionális zoom faktor, ha a natív implementáció ezt támogatná.
  final double? zoomFactor;

  /// Egyedi ikon asset elérési útja.
  /// (Pl. Androidon: az adott drawable asset neve, iOS-en pedig az asset neve.)
  final String? customIcon;

  const PdfViewerStyle({
    this.containerDecoration,
    this.padding,
    this.backgroundColor,
    this.zoomFactor,
    this.customIcon,
  });
}

/// Egy aszinkron PDF nézegető widget, amely a megadott forrásból tölti le a PDF fájlt,
/// majd a letöltött adatokat a stílusban megadott paraméterekkel jeleníti meg.
/// 
/// FIGYELMEZTETÉS: Ebben a példában nem történik tényleges PDF renderelés, csupán
/// egy egyszerű demonstráció a PDF letöltésére és az opciók (pl. egyedi ikon) alkalmazására.
class CustomPdfViewer extends StatefulWidget {
  /// A PDF forrása: lehet URL, asset vagy akár fájl elérési út.
  final String pdfSource;

  /// A PDF nézegető testreszabásához használt stílus.
  final PdfViewerStyle? style;

  /// Opcionális callback, amelyet oldalváltásnál lehet meghívni.
  final void Function(int currentPage)? onPageChanged;

  const CustomPdfViewer({
    Key? key,
    required this.pdfSource,
    this.style,
    this.onPageChanged,
  }) : super(key: key);

  @override
  State<CustomPdfViewer> createState() => _CustomPdfViewerState();
}

class _CustomPdfViewerState extends State<CustomPdfViewer> {
  late Future<Uint8List> _pdfDataFuture;

  @override
  void initState() {
    super.initState();
    _pdfDataFuture = _loadPdfData();
  }

  /// Aszinkron módon letölti a PDF fájl adatait.
  /// Ha a pdfSource URL, akkor HTTP GET kéréssel tölti le,
  /// egyébként az assetből olvassa be az adatokat.
  Future<Uint8List> _loadPdfData() async {
    if (widget.pdfSource.startsWith('http')) {
      final response = await http.get(Uri.parse(widget.pdfSource));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('PDF letöltési hiba: ${response.statusCode}');
      }
    } else {
      final data = await rootBundle.load(widget.pdfSource);
      return data.buffer.asUint8List();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _pdfDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Betöltés alatt: egy körkörös progress indicator jelenik meg.
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Hiba esetén a hibaüzenet jelenik meg.
          return Center(child: Text('Hiba: ${snapshot.error}'));
        }

        // Itt a letöltött PDF adatokat használhatnád fel a tényleges PDF rendereléshez.
        // Példánkban csak a letöltött byte-ok számát jelenítjük meg.
        return Container(
          padding: widget.style?.padding ?? const EdgeInsets.all(8),
          decoration: widget.style?.containerDecoration,
          color: widget.style?.backgroundColor ?? Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ha van megadva egyedi ikon, azt megjelenítjük.
              if (widget.style?.customIcon != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.asset(widget.style!.customIcon!),
                ),
              Text(
                'PDF sikeresen letöltve.\nMéret: ${snapshot.data!.lengthInBytes} byte',
                textAlign: TextAlign.center,
              ),
              // Itt adhatsz hozzá további UI elemeket,
              // illetve implementálhatod az oldalváltás eseményét is.
            ],
          ),
        );
      },
    );
  }
}
