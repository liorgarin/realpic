// lib/main.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'buy_new_film_page.dart'; // Import the new page

void main() {
  runApp(const PhotoSaverApp());
}

class PhotoSaverApp extends StatelessWidget {
  const PhotoSaverApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Saver App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FilmHomePage(),
    );
  }
}

class FilmHomePage extends StatefulWidget {
  const FilmHomePage({Key? key}) : super(key: key);

  @override
  _FilmHomePageState createState() => _FilmHomePageState();
}

class _FilmHomePageState extends State<FilmHomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int _currentIndex = 0;

  // Define the statuses and corresponding icons
  final List<String> _statuses = [
    FilmStatus.active,
    FilmStatus.readyToPrint,
    FilmStatus.onTheWay,
    FilmStatus.arrived,
  ];

  final List<IconData> _icons = [
    Icons.camera_alt,        // Active
    Icons.print,             // Ready to Print
    Icons.local_shipping,    // On the Way
    Icons.check,             // Arrived
  ];

  // Store the counts of films per status
  Map<String, int> _statusCounts = {
    FilmStatus.active: 0,
    FilmStatus.readyToPrint: 0,
    FilmStatus.onTheWay: 0,
    FilmStatus.arrived: 0,
  };

  // GlobalKey to control FilmList
  final Map<String, GlobalKey<_FilmListState>> _filmListKeys = {
    FilmStatus.active: GlobalKey<_FilmListState>(),
    FilmStatus.readyToPrint: GlobalKey<_FilmListState>(),
    FilmStatus.onTheWay: GlobalKey<_FilmListState>(),
    FilmStatus.arrived: GlobalKey<_FilmListState>(),
  };

  @override
  void initState() {
    super.initState();
    _loadStatusCounts();
    _checkPermissions();
  }

  // Check and request necessary permissions
  Future<void> _checkPermissions() async {
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      await Permission.camera.request();
    }

    var photosStatus = await Permission.photos.status;
    if (photosStatus.isDenied) {
      await Permission.photos.request();
    }
  }

  // Load counts of films per status
  Future<void> _loadStatusCounts() async {
    Map<String, int> newStatusCounts = {
      FilmStatus.active: 0,
      FilmStatus.readyToPrint: 0,
      FilmStatus.onTheWay: 0,
      FilmStatus.arrived: 0,
    };

    for (String status in _statuses) {
      List<Map<String, dynamic>> films = await _dbHelper.getFilmsByStatus(status);
      newStatusCounts[status] = films.length;
      print('Status "$status" has ${films.length} film(s).'); // Debugging
    }

    setState(() {
      _statusCounts = newStatusCounts;
    });

    // Refresh all FilmLists to ensure data consistency
    for (String status in _statuses) {
      _filmListKeys[status]?.currentState?.refreshFilms();
    }
  }

  // Handle tab tapping
  void _onTabTapped(int index) async {
    String status = _statuses[index];
    int count = _statusCounts[status] ?? 0;

    // Allow switching to "Active" tab regardless of count
    if (status == FilmStatus.active || count > 0) {
      setState(() {
        _currentIndex = index;
      });
      print('Switched to "$status" tab.'); // Debugging
    } else {
      print('Tab "$status" is disabled due to no films.'); // Debugging
      // Optionally, show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No films available in "$status" status.')),
      );
    }
  }

  // Build the BottomNavigationBar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      items: List.generate(_statuses.length, (index) {
        String status = _statuses[index];
        int count = _statusCounts[status] ?? 0;
        bool isActiveTab = _currentIndex == index;
        bool hasFilms;

        // "Active" tab is always clickable
        if (status == FilmStatus.active) {
          hasFilms = true;
        } else {
          hasFilms = count > 0;
        }

        Color iconColor;

        if (!hasFilms) {
          iconColor = Colors.grey;
        } else if (isActiveTab) {
          iconColor = Colors.blue;
        } else {
          iconColor = Colors.black;
        }

        return BottomNavigationBarItem(
          icon: Icon(
            _icons[index],
            color: iconColor,
          ),
          label: _capitalize(status),
        );
      }),
      type: BottomNavigationBarType.fixed,
    );
  }

  // Capitalize the first letter of a string
  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    String currentStatus = _statuses[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('${_capitalize(currentStatus)} Films'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BuyNewFilmPage()),
                ).then((_) {
                  // Refresh the film lists when returning from the BuyNewFilmPage
                  _loadStatusCounts();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0), // Rounded corners
                ),
              ),
              child: const Text(
                'Buy New Film',
                style: TextStyle(
                  color: Colors.white, // Text color
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FilmList(
        key: _filmListKeys[currentStatus],
        status: currentStatus,
        onStatusChange: _loadStatusCounts, // Callback to refresh counts
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      // Remove the FAB as it's now replaced by the AppBar button
      // floatingActionButton: _currentIndex == _statuses.indexOf(FilmStatus.active) // Show FAB only on 'active' tab
      //     ? FloatingActionButton(
      //         onPressed: _showAddFilmDialog,
      //         child: const Icon(Icons.add),
      //         tooltip: 'Add New Film',
      //       )
      //     : null,
    );
  }
}

// FilmList Widget to display films based on status
class FilmList extends StatefulWidget {
  final String status;
  final VoidCallback onStatusChange;

  const FilmList({
    Key? key,
    required this.status,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  _FilmListState createState() => _FilmListState();
}

class _FilmListState extends State<FilmList> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> films = [];

  @override
  void initState() {
    super.initState();
    _loadFilms();
  }

  @override
  void didUpdateWidget(FilmList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _loadFilms();
    }
  }

  // Load films based on current status
  Future<void> _loadFilms() async {
    List<Map<String, dynamic>> data = await _dbHelper.getFilmsByStatus(widget.status);
    setState(() {
      films = data;
    });
    print('Loaded ${data.length} film(s) for status "${widget.status}".'); // Debugging
  }

  // Method to refresh films, called from FilmHomePage
  void refreshFilms() {
    _loadFilms();
  }

  @override
  Widget build(BuildContext context) {
    if (films.isEmpty) {
      return const Center(
        child: Text('No films available.'),
      );
    }

    return ListView.builder(
      itemCount: films.length,
      itemBuilder: (context, index) {
        return FilmTile(
          film: films[index],
          onStatusChange: () async {
            await _loadFilms(); // Refresh films in current list
            widget.onStatusChange(); // Notify FilmHomePage to refresh counts
          },
        );
      },
    );
  }
}

// FilmTile Widget representing each film
class FilmTile extends StatefulWidget {
  final Map<String, dynamic> film;
  final VoidCallback onStatusChange;

  const FilmTile({
    Key? key,
    required this.film,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  _FilmTileState createState() => _FilmTileState();
}

class _FilmTileState extends State<FilmTile> {
  int photoCount = 0;
  int maxPhotos = 0;
  String status = '';
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadFilmDetails();
    _loadPhotoCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Load film details
  Future<void> _loadFilmDetails() async {
    Map<String, dynamic>? filmDetails =
        await _dbHelper.getFilmById(widget.film['id']);
    if (filmDetails != null) {
      setState(() {
        maxPhotos = filmDetails['max_photos'] ?? 3; // Default to 3 if null
        status = filmDetails['status'] ?? FilmStatus.active;
      });

      print('Film "${widget.film['name']}" loaded with status "$status" and max photos $maxPhotos.'); // Debugging

      // Start timer if status is 'on the way'
      if (status == FilmStatus.onTheWay) {
        _startArrivalTimer();
      }
    }
  }

  // Load the current photo count
  Future<void> _loadPhotoCount() async {
    int count = await _dbHelper.getPhotoCount(widget.film['id']);
    setState(() {
      photoCount = count;
    });

    print('Film "${widget.film['name']}" has $photoCount photo(s).'); // Debugging
  }

  // Get border color based on status
  Color _getBorderColor(String status) {
    switch (status) {
      case FilmStatus.active:
        return Colors.green;
      case FilmStatus.readyToPrint:
        return Colors.orange;
      case FilmStatus.onTheWay:
        return Colors.grey;
      case FilmStatus.arrived:
        return Colors.blue; // As per user request
      default:
        return Colors.grey;
    }
  }

  // Handle tap on the frame
  void _handleFrameTap() {
    switch (status) {
      case FilmStatus.active:
        _takePhoto();
        break;
      case FilmStatus.readyToPrint:
        _confirmOrder();
        break;
      case FilmStatus.onTheWay:
        // Optionally, show a message or perform another action
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Film is on the way.")),
        );
        print('Film "${widget.film['name']}" is on the way.'); // Debugging
        break;
      case FilmStatus.arrived:
        _navigateToGallery();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unknown film status.")),
        );
        print('Film "${widget.film['name']}" has an unknown status.'); // Debugging
    }
  }

  // Handle taking a photo
  Future<void> _takePhoto() async {
    if (photoCount >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum number of photos reached.")),
      );
      print('Cannot take more photos for film "${widget.film['name']}".'); // Debugging
      return;
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      await _dbHelper.insertPhoto(photo.path, widget.film['id']);
      print('Photo added to film "${widget.film['name']}" at path: ${photo.path}'); // Debugging
      await _loadPhotoCount();

      if (photoCount >= maxPhotos) { // Corrected condition
        await _dbHelper.updateFilmStatus(widget.film['id'], FilmStatus.readyToPrint);
        setState(() {
          status = FilmStatus.readyToPrint;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Film is ready to print.")),
        );
        print('Film "${widget.film['name']}" status updated to "${FilmStatus.readyToPrint}".'); // Debugging
        widget.onStatusChange(); // Notify to refresh counts and lists
      }
    } else {
      print('No photo captured for film "${widget.film['name']}".'); // Debugging
    }
  }

  // Handle confirming the order
  Future<void> _confirmOrder() async {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _phoneController = TextEditingController();
    TextEditingController _countryController = TextEditingController();
    TextEditingController _cityController = TextEditingController();
    TextEditingController _streetAddressController = TextEditingController();
    TextEditingController _postalCodeController = TextEditingController();
    TextEditingController _additionalDetailsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Order"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: "Receiver Name"),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(hintText: "Phone Number"),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _countryController,
                  decoration: const InputDecoration(hintText: "Country"),
                ),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(hintText: "City"),
                ),
                TextField(
                  controller: _streetAddressController,
                  decoration: const InputDecoration(hintText: "Street Address"),
                ),
                TextField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(hintText: "Postal Code"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _additionalDetailsController,
                  decoration:
                      const InputDecoration(hintText: "Additional Details (Optional)"),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty &&
                    _phoneController.text.isNotEmpty &&
                    _countryController.text.isNotEmpty &&
                    _cityController.text.isNotEmpty &&
                    _streetAddressController.text.isNotEmpty &&
                    _postalCodeController.text.isNotEmpty) {
                  await _dbHelper.updateFilmShippingDetails(
                    filmId: widget.film['id'],
                    receiverName: _nameController.text,
                    phoneNumber: _phoneController.text,
                    country: _countryController.text,
                    city: _cityController.text,
                    streetAddress: _streetAddressController.text,
                    postalCode: _postalCodeController.text,
                    additionalDetails: _additionalDetailsController.text,
                  );
                  setState(() {
                    status = FilmStatus.onTheWay;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Order confirmed.")),
                  );
                  print('Order confirmed for film "${widget.film['name']}".'); // Debugging
                  widget.onStatusChange(); // Notify to refresh counts and lists
                  _startArrivalTimer(); // Start the timer after confirming order
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please fill in all the required details.")),
                  );
                  print('Order confirmation failed due to missing details.'); // Debugging
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Ensure button background is blue
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  // Start a timer to automatically update film status to 'arrived'
  void _startArrivalTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 12), () async { // Changed to 12 seconds
      await _dbHelper.updateFilmStatus(widget.film['id'], FilmStatus.arrived);
      setState(() {
        status = FilmStatus.arrived;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your film has arrived.")),
      );
      print('Film "${widget.film['name']}" status updated to "${FilmStatus.arrived}".'); // Debugging
      widget.onStatusChange(); // Notify to refresh counts and lists
    });
    print('Arrival timer started for film "${widget.film['name']}".'); // Debugging
  }

  // Navigate to the gallery page
  Future<void> _navigateToGallery() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPage(
          filmName: widget.film['name'],
          filmId: widget.film['id'],
        ),
      ),
    );
    print('Navigated to Gallery for film "${widget.film['name']}".'); // Debugging
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleFrameTap, // Handle tap based on status
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white, // Frame interior color
          border: Border.all(
            color: _getBorderColor(status),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.film['name'],
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Photos: $photoCount/$maxPhotos',
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.black54,
              ),
            ),
            // Remove status text as it's indicated by the tab and border color
          ],
        ),
      ),
    );
  }
}

// GalleryPage Widget to display photos of a film
class GalleryPage extends StatefulWidget {
  final String filmName;
  final int filmId;

  const GalleryPage({
    Key? key,
    required this.filmName,
    required this.filmId,
  }) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> photos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  // Load photos associated with the film
  Future<void> _loadPhotos() async {
    List<Map<String, dynamic>> data = await _dbHelper.getPhotosByFilm(widget.filmId);
    setState(() {
      photos = data;
    });
    print('Loaded ${data.length} photo(s) for film "${widget.filmName}".'); // Debugging
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery - ${widget.filmName}'),
      ),
      body: photos.isEmpty
          ? const Center(
              child: Text('No photos available for this film.'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns in the grid
                crossAxisSpacing: 4.0, // Horizontal spacing between grid items
                mainAxisSpacing: 4.0, // Vertical spacing between grid items
              ),
              itemBuilder: (BuildContext context, int index) {
                String imagePath = photos[index]['path'];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImagePage(imagePath: imagePath),
                      ),
                    );
                    print('Opened full-screen view for photo at path: $imagePath'); // Debugging
                  },
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
    );
  }
}

// FullScreenImagePage Widget to display a photo in full screen
class FullScreenImagePage extends StatelessWidget {
  final String imagePath;

  const FullScreenImagePage({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with a back button
      appBar: AppBar(),
      // Display the image in full screen
      body: Center(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}