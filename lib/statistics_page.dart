import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statystyki'),
      ),
      body: const Center(
        child: Text('Wkrótce tutaj pojawią się statystyki.'),
      ),
    );
  }
}
