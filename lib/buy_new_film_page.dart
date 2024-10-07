// lib/buy_new_film_page.dart

import 'package:flutter/material.dart';
import 'database_helper.dart';

class BuyNewFilmPage extends StatefulWidget {
  const BuyNewFilmPage({Key? key}) : super(key: key);

  @override
  _BuyNewFilmPageState createState() => _BuyNewFilmPageState();
}

class _BuyNewFilmPageState extends State<BuyNewFilmPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _filmNameController = TextEditingController();
  int? _selectedMaxPhotos;
  final List<int> _photoOptions = [3, 18, 36, 72];

  @override
  void dispose() {
    _filmNameController.dispose();
    super.dispose();
  }

  Future<void> _buyNewFilm() async {
    if (_formKey.currentState!.validate()) {
      await _dbHelper.insertFilm(
        _filmNameController.text.trim(),
        _selectedMaxPhotos!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New film purchased successfully.")),
      );
      Navigator.of(context).pop(); // Navigate back to the previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buy New Film"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _filmNameController,
                decoration: const InputDecoration(
                  labelText: "Film Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter the film name.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: "Select Max Photos",
                  border: OutlineInputBorder(),
                ),
                value: _selectedMaxPhotos,
                items: _photoOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text("$value Photos"),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedMaxPhotos = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Please select the maximum number of photos.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _buyNewFilm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Button background color
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text(
                    "Buy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}