import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:internet_file/internet_file.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pdfx/pdfx.dart' as pdf;
import '../main.dart';
import 'package:http/http.dart' as http;
import '../utils/Common.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../utils/Extensions/app_common.dart';

class PDFViewer extends StatefulWidget {
  final String invoice;
  final String? filename;

  PDFViewer({required this.invoice, this.filename = ""});

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  PdfController? pdfController;

  @override
  void initState() {
    super.initState();
    viewPDF();
  }

  Future<void> viewPDF() async {
    try {
      pdfController = PdfController(document: pdf.PdfDocument.openData(InternetFile.get("${widget.invoice}",)),initialPage: 0,);
    } catch (e) {
      print('Error viewing PDF: $e');
    }
  }

  Future<void> downloadPDF() async {
    appStore.setLoading(true);
    final response = await http.get(Uri.parse(widget.invoice));
    if (response.statusCode == 200) {
      try{

        final bytes = response.bodyBytes;
        String path ="~";
        if(Platform.isIOS){
          var directory = await getApplicationDocumentsDirectory();
          path =directory.path;
        }else{
          path ="/storage/emulated/0/Download";
        }
        // if(!Directory(path).existsSync()){
        //   await Directory(path).create();
        // }
        String fileName = widget.filename.validate().isEmpty ? "invoice": widget.filename.validate() ;
        File file = File('${path}/${fileName}.pdf');
        await file.writeAsBytes(bytes, flush: true);
        appStore.setLoading(false);
        toast("invoice downloaded at ${file.path}");
        final url = 'content://${file.path}';
        final filef = File(file.path);
        if (await filef.exists()) {
          OpenFile.open(file.path);
        } else {
          throw 'File does not exist';
        }
      }catch(e){
        throw Exception('Failed to download PDF');
      }
    } else {
      appStore.setLoading(false);
      toast("Failed to download pdf");
      throw Exception('Failed to download PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text("${language.invoice}", style: boldTextStyle(color: Colors.white)),
          actions: [
            IconButton(
              onPressed: () {
                downloadPDF();
              },
              icon:Icon(Icons.download, color: Colors.white),
            ),
          ],
        ),
        body: Stack(
          children: [
            PdfView(
              controller: pdfController!
            ),
            PdfPageNumber(
              controller: pdfController!,
              builder: (_, loadingState, page, pagesCount) {
                if(page==0)return loaderWidget();
                return SizedBox();
              },
            ),
            Observer(builder: (context) => Visibility(visible: appStore.isLoading, child: Positioned.fill(child: loaderWidget()))),
          ],
        ));
  }
}