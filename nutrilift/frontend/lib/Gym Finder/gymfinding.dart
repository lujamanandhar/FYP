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
        title: Text('Find Gyms'),
        backgroundColor: Colors.deepOrange,
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
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Near Me', 'Top Rated', 'New']
                      .map((filter) => Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() => _selectedFilter = filter);
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              SizedBox(height: 20),

              // Gym List
              Text(
                'Nearby Gyms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
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
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  gym['name'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text('${gym['rating']}'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(gym['distance'], style: TextStyle(color: Colors.grey)),
              ],
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: (gym['facilities'] as List)
                  .map((facility) => Chip(
                        label: Text(facility, style: TextStyle(fontSize: 12)),
                        backgroundColor: Colors.deepOrange[100],
                      ))
                  .toList(),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                minimumSize: Size(double.infinity, 40),
              ),
              child: Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}