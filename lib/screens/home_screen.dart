import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:bookdify/models/book.dart';
import 'package:bookdify/screens/pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getStringList('books') ?? [];

      final loadedBooks = booksJson
          .map((bookJson) => Book.fromJson(json.decode(bookJson)))
          .toList();

      // Check if files still exist
      final validBooks = <Book>[];
      for (final book in loadedBooks) {
        final file = File(book.filePath);
        if (await file.exists()) {
          validBooks.add(book);
        }
      }

      setState(() {
        books = validBooks;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading books: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addBook() async {
    try {
      // Pick a PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // Show dialog to rename the book
        final bookName = await showDialog<String>(
          context: context,
          builder: (context) => _buildRenameDialog(context, fileName),
        );

        if (bookName != null && bookName.isNotEmpty) {
          // Create new book entry
          final newBook = Book(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: bookName,
            filePath: filePath,
            addedDate: DateTime.now(),
          );

          setState(() {
            books.add(newBook);
          });

          await saveBooks();
        }
      }
    } catch (e) {
      print('Error adding book: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add book: $e')),
      );
    }
  }

  Future<void> deleteBook(Book book) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Book'),
          content: Text('Are you sure you want to delete "${book.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          books.removeWhere((b) => b.id == book.id);
        });

        await saveBooks();
      }
    } catch (e) {
      print('Error deleting book: $e');
    }
  }

  Future<void> renameBook(Book book) async {
    try {
      final newName = await showDialog<String>(
        context: context,
        builder: (context) => _buildRenameDialog(context, book.name),
      );

      if (newName != null && newName.isNotEmpty && newName != book.name) {
        setState(() {
          final index = books.indexWhere((b) => b.id == book.id);
          if (index != -1) {
            books[index] = books[index].copyWith(name: newName);
          }
        });

        await saveBooks();
      }
    } catch (e) {
      print('Error renaming book: $e');
    }
  }

  Future<void> saveBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson =
          books.map((book) => json.encode(book.toJson())).toList();

      await prefs.setStringList('books', booksJson);
    } catch (e) {
      print('Error saving books: $e');
    }
  }

  Widget _buildRenameDialog(BuildContext context, String initialName) {
    final controller = TextEditingController(text: initialName);
    return AlertDialog(
      title: const Text('Enter Book Name'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Book Name',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookDiFy'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No books added yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: addBook,
                        icon: const Icon(Icons.add),
                        label: const Text('Add a PDF Book'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading:
                            const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(book.name),
                        subtitle: Text(
                          'Added: ${book.formattedDate}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => renameBook(book),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteBook(book),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PDFViewerScreen(book: book),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: books.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: addBook,
              tooltip: 'Add PDF',
              child: const Icon(Icons.add),
            ),
    );
  }
}
