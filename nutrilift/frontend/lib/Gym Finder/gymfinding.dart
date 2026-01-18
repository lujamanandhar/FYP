import 'package:flutter/material.dart';
import 'gym_details_screen.dart';

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
      'facilities': ['Cardio', 'Weights', 'Pool', 'Sauna'],
      'address': '123 Fitness Street, Downtown',
      'phone': '+1 234-567-8900',
      'isOpen': true,
      'description': 'A premium fitness center with state-of-the-art equipment and professional trainers. Perfect for all fitness levels with a focus on personalized training programs.',
      'images': [
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
        'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800',
      ],
      'hours': {
        'Monday': '5:00 AM - 11:00 PM',
        'Tuesday': '5:00 AM - 11:00 PM',
        'Wednesday': '5:00 AM - 11:00 PM',
        'Thursday': '5:00 AM - 11:00 PM',
        'Friday': '5:00 AM - 11:00 PM',
        'Saturday': '6:00 AM - 10:00 PM',
        'Sunday': '7:00 AM - 9:00 PM',
      },
      'amenities': [
        'Free WiFi',
        'Parking Available',
        'Locker Rooms',
        'Towel Service',
        'Personal Training',
        'Group Classes',
        'Nutritionist on Site',
      ],
      'pricing': [
        {
          'name': 'Basic Plan',
          'price': '\$29/month',
          'description': 'Access to gym equipment and basic facilities',
          'features': ['Gym Access', 'Locker Room', 'Free WiFi'],
        },
        {
          'name': 'Premium Plan',
          'price': '\$59/month',
          'description': 'Full access with group classes and pool',
          'features': ['Everything in Basic', 'Group Classes', 'Pool Access', 'Sauna'],
        },
        {
          'name': 'VIP Plan',
          'price': '\$99/month',
          'description': 'All-inclusive with personal training sessions',
          'features': ['Everything in Premium', '4 Personal Training Sessions', 'Nutritionist Consultation', 'Priority Booking'],
        },
      ],
      'reviewCount': 127,
      'reviews': [
        {
          'name': 'Sarah Johnson',
          'rating': 5,
          'date': '2 days ago',
          'comment': 'Amazing gym with great equipment and friendly staff. The pool is always clean and the classes are fantastic!',
        },
        {
          'name': 'Mike Chen',
          'rating': 4,
          'date': '1 week ago',
          'comment': 'Good facilities and convenient location. Sometimes gets crowded during peak hours but overall great experience.',
        },
        {
          'name': 'Emma Davis',
          'rating': 5,
          'date': '2 weeks ago',
          'comment': 'Love this place! The personal trainers are knowledgeable and the variety of equipment is impressive.',
        },
      ],
    },
    {
      'name': 'PowerHouse Fitness',
      'distance': '1.2 km',
      'rating': 4.8,
      'facilities': ['Weights', 'CrossFit', 'Yoga', 'Boxing'],
      'address': '456 Strength Avenue, Midtown',
      'phone': '+1 234-567-8901',
      'isOpen': true,
      'description': 'Hardcore training facility specializing in strength training and CrossFit. Perfect for serious athletes and fitness enthusiasts looking to push their limits.',
      'images': [
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
        'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800',
      ],
      'hours': {
        'Monday': '5:00 AM - 12:00 AM',
        'Tuesday': '5:00 AM - 12:00 AM',
        'Wednesday': '5:00 AM - 12:00 AM',
        'Thursday': '5:00 AM - 12:00 AM',
        'Friday': '5:00 AM - 12:00 AM',
        'Saturday': '24 Hours',
        'Sunday': '24 Hours',
      },
      'amenities': [
        'Free WiFi',
        'Parking Available',
        'Locker Rooms',
        'Supplement Store',
        'Personal Training',
        'CrossFit Classes',
        'Boxing Ring',
      ],
      'pricing': [
        {
          'name': 'Standard',
          'price': '\$39/month',
          'description': 'Access to all equipment and basic classes',
          'features': ['Gym Access', 'Basic Classes', 'Locker Room'],
        },
        {
          'name': 'Elite',
          'price': '\$79/month',
          'description': 'Unlimited classes and premium features',
          'features': ['Everything in Standard', 'Unlimited Classes', 'Boxing Access', 'Supplement Discount'],
        },
      ],
      'reviewCount': 89,
      'reviews': [
        {
          'name': 'John Smith',
          'rating': 5,
          'date': '3 days ago',
          'comment': 'Best CrossFit gym in the city! Coaches are amazing and the community is very supportive.',
        },
        {
          'name': 'Lisa Wong',
          'rating': 4,
          'date': '1 week ago',
          'comment': 'Great for serious training. Equipment is top-notch and well-maintained.',
        },
      ],
    },
    {
      'name': 'Elite Sports Center',
      'distance': '2.1 km',
      'rating': 4.3,
      'facilities': ['Cardio', 'Boxing', 'Spinning', 'Basketball'],
      'address': '789 Sports Complex, Uptown',
      'phone': '+1 234-567-8902',
      'isOpen': false,
      'description': 'Multi-sport facility with diverse training options. Features indoor basketball court, boxing ring, and state-of-the-art spinning studio.',
      'images': [
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
      ],
      'hours': {
        'Monday': '6:00 AM - 10:00 PM',
        'Tuesday': '6:00 AM - 10:00 PM',
        'Wednesday': '6:00 AM - 10:00 PM',
        'Thursday': '6:00 AM - 10:00 PM',
        'Friday': '6:00 AM - 10:00 PM',
        'Saturday': '7:00 AM - 9:00 PM',
        'Sunday': '8:00 AM - 8:00 PM',
      },
      'amenities': [
        'Free WiFi',
        'Parking Available',
        'Locker Rooms',
        'Basketball Court',
        'Boxing Ring',
        'Spinning Studio',
        'Juice Bar',
      ],
      'pricing': [
        {
          'name': 'Basic Access',
          'price': '\$35/month',
          'description': 'Gym and cardio equipment access',
          'features': ['Gym Access', 'Cardio Equipment', 'Locker Room'],
        },
        {
          'name': 'All Sports',
          'price': '\$65/month',
          'description': 'Full facility access including courts',
          'features': ['Everything in Basic', 'Basketball Court', 'Boxing Ring', 'All Classes'],
        },
      ],
      'reviewCount': 156,
      'reviews': [
        {
          'name': 'Alex Rodriguez',
          'rating': 4,
          'date': '4 days ago',
          'comment': 'Great variety of activities. Love the basketball court and spinning classes.',
        },
        {
          'name': 'Maria Garcia',
          'rating': 4,
          'date': '1 week ago',
          'comment': 'Good facilities but can get busy. The juice bar is a nice touch!',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get filteredGyms {
    List<Map<String, dynamic>> filtered = gyms;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((gym) =>
          gym['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
          gym['facilities'].any((facility) =>
              facility.toLowerCase().contains(_searchController.text.toLowerCase()))).toList();
    }
    
    // Apply category filter
    switch (_selectedFilter) {
      case 'Near Me':
        filtered.sort((a, b) => double.parse(a['distance'].split(' ')[0])
            .compareTo(double.parse(b['distance'].split(' ')[0])));
        break;
      case 'Top Rated':
        filtered.sort((a, b) => b['rating'].compareTo(a['rating']));
        break;
      case 'New':
        // For demo, just reverse the list
        filtered = filtered.reversed.toList();
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Gyms', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[700],
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.map, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Map view coming soon!')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate refresh
          await Future.delayed(Duration(seconds: 1));
          setState(() {});
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search gyms, facilities...',
                    prefixIcon: Icon(Icons.search, color: Colors.red[700]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
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

                // Results Count
                Text(
                  '${filteredGyms.length} gyms found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 16),

                // Gym List
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: filteredGyms.length,
                  itemBuilder: (context, index) {
                    final gym = filteredGyms[index];
                    return _buildGymCard(gym);
                  },
                ),
              ],
            ),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GymDetailsScreen(gym: gym),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.red[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(gym['address'], style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.directions_walk, size: 18, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(gym['distance'], style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: gym['isOpen'] ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      gym['isOpen'] ? 'Open' : 'Closed',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (gym['facilities'] as List)
                    .take(4) // Show only first 4 facilities
                    .map((facility) => Chip(
                          label: Text(facility, style: TextStyle(fontSize: 12, color: Colors.white)),
                          backgroundColor: Colors.red[700],
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ))
                    .toList(),
              ),
              if ((gym['facilities'] as List).length > 4)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '+${(gym['facilities'] as List).length - 4} more facilities',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Call gym
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${gym['phone']}')),
                        );
                      },
                      icon: Icon(Icons.phone, size: 16, color: Colors.red[700]),
                      label: Text('Call', style: TextStyle(color: Colors.red[700])),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[700]!),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GymDetailsScreen(gym: gym),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('View Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}