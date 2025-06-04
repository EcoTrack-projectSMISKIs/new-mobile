import 'package:ecotrack_mobile/features/news_and_updates/news_details.dart';
import 'package:ecotrack_mobile/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsAndUpdates extends StatefulWidget {
  const NewsAndUpdates({Key? key}) : super(key: key);

  @override
  _NewsAndUpdatesState createState() => _NewsAndUpdatesState();
}

class _NewsAndUpdatesState extends State<NewsAndUpdates> {
  List<dynamic> announcements = [];
  List<dynamic> updates = [];
  bool _isRefreshing = false;

  static final String apiUrl =
      '${dotenv.env['BASE_URL']}/api/news?status=published';

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          announcements =
              data
                  .where(
                    (item) =>
                        item['category'] == 'brownout' ||
                        item['category'] == 'maintenance',
                  )
                  .toList();
          updates =
              data
                  .where(
                    (item) =>
                        item['category'] != 'brownout' &&
                        item['category'] != 'maintenance',
                  )
                  .toList();
        });
      } else {
        throw Exception("Failed to load news");
      }
    } catch (e) {
      print("Error fetching news: $e");
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    // Wait for minimum 3 seconds
    await Future.wait([
      fetchNews(),
      Future.delayed(const Duration(seconds: 3)),
    ]);

    setState(() {
      _isRefreshing = false;
    });
  }

  // Vertical card for Updates
  Widget buildNewsCard(dynamic news) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailsPage(article: news),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // 🌟 Image Container
              Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: news['image'] ?? '',
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news['title'] ?? "No Title",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 25,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      news['createdAt'] != null
                          ? news['createdAt'].toString().substring(0, 10)
                          : "",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Horizontal card for Announcements
  Widget buildHorizontalNewsCard(dynamic news) {
    return Container(
      width: 250,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewsDetailsPage(article: news),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 MAIN Image Container
              Center(
                child: Container(
                  height: 165,
                  width: 213,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                      bottom: Radius.circular(50), // 🎯 bottom radius set here
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                      bottom: Radius.circular(16), // Match rounded look
                    ),
                    child: CachedNetworkImage(
                      imageUrl: news['image'] ?? '',
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F5E8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF119718),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child:
                newsArticlesEmpty() && !_isRefreshing
                    ? ListView(
                        children: const [
                          SizedBox(height: 200),
                          Center(child: CircularProgressIndicator(color: Color(0xFF119718))),
                        ],
                      )
                    : ListView(
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          "Announcements",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 180,
                          child: announcements.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No announcements available",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: announcements.length,
                                  itemBuilder: (context, index) {
                                    return buildHorizontalNewsCard(
                                      announcements[index],
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          "Updates",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (updates.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "No updates available",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          ...updates.map((news) => buildNewsCard(news)).toList(),
                        const SizedBox(height: 20), // Extra space at bottom
                      ],
                    ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: CustomBottomNavBar(selectedIndex: 3),
      ),
    );
  }

  bool newsArticlesEmpty() {
    return announcements.isEmpty && updates.isEmpty;
  }
}