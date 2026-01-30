import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';

class GymDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> gym;

  const GymDetailsScreen({Key? key, required this.gym}) : super(key: key);

  @override
  State<GymDetailsScreen> createState() => _GymDetailsScreenState();
}

class _GymDetailsScreenState extends State<GymDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: widget.gym['name'],
      showBackButton: true,
      showDrawer: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.black),
          onPressed: () {
            // Add to favorites
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to favorites!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black),
          onPressed: () {
            // Share gym
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sharing ${widget.gym['name']}')),
            );
          },
        ),
      ],
      body: Column(
        children: [
          // Hero Image Section
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.gym['images'][0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.fitness_center, size: 100, color: Colors.grey[600]),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Quick Info Section
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red[700],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('${widget.gym['rating']}', 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 18, color: Colors.red[700]),
                                const SizedBox(width: 4),
                                Text(widget.gym['distance'], 
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.gym['isOpen'] ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.gym['isOpen'] ? 'Open Now' : 'Closed',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Icon(Icons.place, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.gym['address'],
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Quick Actions
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Call gym
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Calling ${widget.gym['phone']}')),
                                  );
                                },
                                icon: const Icon(Icons.phone, color: Colors.white),
                                label: const Text('Call', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Opening directions...')),
                                  );
                                },
                                icon: Icon(Icons.directions, color: Colors.red[700]),
                                label: Text('Directions', style: TextStyle(color: Colors.red[700])),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.red[700]!),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.red[700],
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.red[700],
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Photos'),
                        Tab(text: 'Pricing'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                ),

                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildPhotosTab(),
                      _buildPricingTab(),
                      _buildReviewsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
        ),
        child: ElevatedButton(
          onPressed: () {
            _showBookingDialog();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Book Now',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'About',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            widget.gym['description'],
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 24),

          
          Text(
            'Facilities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (widget.gym['facilities'] as List)
                .map((facility) => Chip(
                      label: Text(facility, style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red[700],
                    ))
                .toList(),
          ),
          SizedBox(height: 24),

          // Operating Hours
          Text(
            'Operating Hours',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          ...widget.gym['hours'].entries.map((entry) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: TextStyle(fontSize: 16)),
                    Text(entry.value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
          SizedBox(height: 24),

          // Amenities
          Text(
            'Amenities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          ...widget.gym['amenities'].map((amenity) => Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text(amenity, style: TextStyle(fontSize: 16)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.gym['images'].length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _showImageViewer(index);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.gym['images'][index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Membership Plans',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...widget.gym['pricing'].map((plan) => Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            plan['name'],
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red[700],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              plan['price'],
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        plan['description'],
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 12),
                      ...plan['features'].map((feature) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.check, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text(feature, style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          )),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _showBookingDialog(selectedPlan: plan);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Select Plan', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary
          Row(
            children: [
              Text(
                '${widget.gym['rating']}',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red[700]),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) => Icon(
                            index < widget.gym['rating'].floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          )),
                    ),
                    SizedBox(height: 4),
                    Text('Based on ${widget.gym['reviewCount']} reviews'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Reviews List
          Text(
            'Reviews',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...widget.gym['reviews'].map((review) => Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.red[700],
                            child: Text(
                              review['name'][0],
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                                Row(
                                  children: List.generate(5, (index) => Icon(
                                        index < review['rating']
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      )),
                                ),
                              ],
                            ),
                          ),
                          Text(review['date'], style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(review['comment']),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showImageViewer(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          height: 400,
          child: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: widget.gym['images'].length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.gym['images'][index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.image, size: 100, color: Colors.grey),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBookingDialog({Map<String, dynamic>? selectedPlan}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book ${widget.gym['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedPlan != null) ...[
              Text('Selected Plan: ${selectedPlan['name']}'),
              Text('Price: ${selectedPlan['price']}'),
              SizedBox(height: 16),
            ],
            Text('Choose your preferred booking option:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Booking confirmed! You will receive a confirmation email.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: Text('Confirm Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}