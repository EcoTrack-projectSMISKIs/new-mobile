import 'package:ecotrack_mobile/features/news_and_updates/news_details.dart';
import 'package:ecotrack_mobile/services/news_service.dart';
import 'package:flutter/material.dart';


class NewsCardPage extends StatefulWidget {
  @override
  _NewsCardPageState createState() => _NewsCardPageState();
}

class _NewsCardPageState extends State<NewsCardPage> {
  late Future<List<dynamic>> newsList;

  @override
  void initState() {
    super.initState();
    newsList = NewsService.fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("News & Updates")),
      body: FutureBuilder<List<dynamic>>(
        future: newsList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading news"));
          }

          final news = snapshot.data!;
          return ListView.builder(
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];
              return ListTile(
                title: Text(item['title'] ?? 'No Title'),
                subtitle: Text(item['date'] ?? 'No Date'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewsDetailsPage(article: item), // ✅ FIXED: proper widget and param name
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}