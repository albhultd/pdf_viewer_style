import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

/// A PDF nézegető testreszabásához használt osztály.
class PdfViewerStyle {
  final BoxDecoration? containerDecoration;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? zoomFactor;
  final String? customIcon;

  const PdfViewerStyle({
    this.containerDecoration,
    this.padding,
    this.backgroundColor,
    this.zoomFactor,
    this.customIcon,
  });
}

/// Egy aszinkron PDF nézegető widget, amely bármilyen méretben elhelyezhető.
class CustomPdfViewer extends StatefulWidget {
  final String pdfSource;
  final PdfViewerStyle? style;
  final void Function(int currentPage)? onPageChanged;

  const CustomPdfViewer({
    super.key,
    required this.pdfSource,
    this.style,
    this.onPageChanged,
  });

  @override
  State<CustomPdfViewer> createState() => _CustomPdfViewerState();
}

class _CustomPdfViewerState extends State<CustomPdfViewer> {
  late Future<Uint8List> _pdfDataFuture;
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfDataFuture = _loadPdfData();
  }

  /// PDF betöltése URL-ről vagy assetből.
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

  /// PDF betöltése a `pdfx`-be, ha sikeresen letöltődött.
  void _initializePdfViewer(Uint8List pdfData) {
    setState(() {
      _pdfController = PdfController(
        document: PdfDocument.openData(pdfData),
      );
    });
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _pdfDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hiba: ${snapshot.error}'));
        }

        if (_pdfController == null) {
          _initializePdfViewer(snapshot.data!);
        }

        return Container(
          padding: widget.style?.padding ?? EdgeInsets.zero,
          decoration: widget.style?.containerDecoration ?? BoxDecoration(),
          color: widget.style?.backgroundColor ?? Colors.white,
          child: _pdfController != null
              ? PdfView(
                  controller: _pdfController!,
                  onPageChanged: (page) {
                    widget.onPageChanged?.call(page);
                  },
                )
              : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
