import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:bookdify/models/book.dart';

class PDFViewerScreen extends StatefulWidget {
  final Book book;

  const PDFViewerScreen({super.key, required this.book});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int? totalPages;
  int currentPage = 0;
  bool isReady = false;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.book.filePath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage,
            fitPolicy: FitPolicy.WIDTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                totalPages = pages;
                isReady = true;
                isLoading = false;
              });
            },
            onError: (error) {
              print('Error loading PDF: $error');
              setState(() {
                isLoading = false;
              });
            },
            onPageError: (page, error) {
              print('Error on page $page: $error');
            },
            onViewCreated: (controller) {
              // PDF view created
            },
            onPageChanged: (int? page, int? total) {
              if (page != null) {
                setState(() {
                  currentPage = page;
                });
              }
            },
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : !isReady
                  ? const Center(
                      child: Text('Failed to load PDF'),
                    )
                  : Container(),
          if (isReady && totalPages != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page ${currentPage + 1} of $totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
