import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/nutrilift_header.dart';
import '../services/gym_service.dart';

class GymDetailsScreen extends StatefulWidget {
  final String placeId;

  const GymDetailsScreen({Key? key, required this.placeId}) : super(key: key);

  @override
  State<GymDetailsScreen> createState() => _GymDetailsScreenState();
}

class _GymDetailsScreenState extends State<GymDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GymService _gymService = GymService();
  GymDetails? _gym;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGymDetails();
  }

  Future<void> _loadGymDetails() async {
    setState(() => _isLoading = true);
    try {
      final gym = await _gymService.getGymDetails(widget.placeId);
      setState(() {
        _gym = gym;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading gym details: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_gym == null) return;
    
    try {
      if (_gym!.isFavorite) {
        await _gymService.removeFromFavorites(_gym!.placeId);
        setState(() => _gym = GymDetails(
              placeId: _gym!.placeId,
              name: _gym!.name,
              address: _gym!.address,
              latitude: _gym!.latitude,
              longitude: _gym!.longitude,
              rating: _gym!.rating,
              userRatingsTotal: _gym!.userRatingsTotal,
              isOpen: _gym!.isOpen,
              photos: _gym!.photos,
              priceLevel: _gym!.priceLevel,
              phone: _gym!.phone,
              website: _gym!.website,
              reviews: _gym!.reviews,
              openingHours: _gym!.openingHours,
              isFavorite: false,
            ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      } else {
        await _gymService.addToFavorites(_gym!.placeId, _gym!.name, _gym!.address);
        setState(() => _gym = GymDetails(
              placeId: _gym!.placeId,
              name: _gym!.name,
              address: _gym!.address,
              latitude: _gym!.latitude,
              longitude: _gym!.longitude,
              rating: _gym!.rating,
              userRatingsTotal: _gym!.userRatingsTotal,
              isOpen: _gym!.isOpen,
              photos: _gym!.photos,
              priceLevel: _gym!.priceLevel,
              phone: _gym!.phone,
              website: _gym!.website,
              reviews: _gym!.reviews,
              openingHours: _gym!.openingHours,
              isFavorite: true,
            ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _call() async {
    if (_gym?.phone == null) return;
    final uri = Uri.parse('tel:${_gym!.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite() async {
    if (_gym?.website == null) return;
    final uri = Uri.parse(_gym!.website!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDirections() async {
    if (_gym == null) return;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${_gym!.latitude},${_gym!.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return NutriLiftScaffold(
        title: 'Loading...',
        showBackButton: true,
        showDrawer: false,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_gym == null) {
      return NutriLiftScaffold(
        title: 'Error',
        showBackButton: true,
        showDrawer: false,
        body: const Center(child: Text('Gym not found')),
      );
    }

    return NutriLiftScaffold(
      title: _gym!.name,
      showBackButton: true,
      showDrawer: false,
      actions: [
        IconButton(
          icon: Icon(
            _gym!.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _gym!.isFavorite ? Colors.red : Colors.black,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
      body: Column(
        children: [
          // Image Carousel
          if (_gym!.photos.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: _gym!.photos.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    _gym!.photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.fitness_center, size: 64),
                    ),
                  );
                },
              ),
            ),
          
          // Quick Info Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      _gym!.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Rating', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${_gym!.userRatingsTotal}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Reviews', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      _gym!.priceDisplay,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const Text('Price', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _gym!.isOpen == true ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _gym!.isOpen == true ? 'Open' : 'Closed',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Status', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _call,
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openDirections,
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFE53935),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFE53935),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Hours'),
              Tab(text: 'Reviews'),
            ],
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildHoursTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.location_on, _gym!.address),
          if (_gym!.phone != null) _buildInfoRow(Icons.phone, _gym!.phone!),
          if (_gym!.website != null)
            InkWell(
              onTap: _openWebsite,
              child: _buildInfoRow(Icons.language, _gym!.website!, isLink: true),
            ),
          const SizedBox(height: 24),
          const Text(
            'Photos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _gym!.photos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _gym!.photos[index],
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursTab() {
    final hours = _gym!.weekdayHours;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hours[index].split(':')[0],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                hours[index].substring(hours[index].indexOf(':') + 1).trim(),
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    if (_gym!.reviews.isEmpty) {
      return const Center(child: Text('No reviews available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _gym!.reviews.length,
      itemBuilder: (context, index) {
        final review = _gym!.reviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(review.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(review.text),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isLink ? Colors.blue : Colors.black87,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
