import 'package:flutter/material.dart';

class GymFindingScreen extends StatefulWidget {
  @override
  State<GymFindingScreen> createState() => _GymFindingScreenState();
}

class _GymFindingScreenState extends State<GymFindingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> gyms = [
    {
      'name': 'FitZone Gym',
      'distance': '0.5 km',
      'rating': 4.5,
      'facilities': ['Cardio', 'Weights', 'Pool'],
    },
    {
      'name': 'PowerHouse Fitness',
      'distance': '1.2 km',
      'rating': 4.8,
      'facilities': ['Weights', 'CrossFit', 'Yoga'],
    },
    {
      'name': 'Elite Sports Center',
      'distance': '2.1 km',
      'rating': 4.3,
      'facilities': ['Cardio', 'Boxing', 'Spinning'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Gyms', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[700],
        elevation: 4,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search gyms...',
                  prefixIcon: Icon(Icons.search, color: Colors.red[700]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Near Me', 'Top Rated', 'New']
                      .map((filter) => Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter, style: TextStyle(fontWeight: FontWeight.w500)),
                              selected: _selectedFilter == filter,
                              selectedColor: Colors.red[700],
                              labelStyle: TextStyle(
                                color: _selectedFilter == filter ? Colors.white : Colors.black,
                              ),
                              onSelected: (selected) {
                                setState(() => _selectedFilter = filter);
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              SizedBox(height: 24),

              // Gym List
              Text(
                'Nearby Gyms',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: gyms.length,
                itemBuilder: (context, index) {
                  final gym = gyms[index];
                  return _buildGymCard(gym);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGymCard(Map<String, dynamic> gym) {
    return Card(
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
                Expanded(
                  child: Text(
                    gym['name'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text('${gym['rating']}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.red[700]),
                SizedBox(width: 8),
                Text(gym['distance'], style: TextStyle(color: Colors.grey[700], fontSize: 14)),
              ],
            ),
            SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (gym['facilities'] as List)
                  .map((facility) => Chip(
                        label: Text(facility, style: TextStyle(fontSize: 12, color: Colors.white)),
                        backgroundColor: Colors.red[700],
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ))
                  .toList(),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('View Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}