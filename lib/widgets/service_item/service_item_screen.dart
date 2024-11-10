import 'package:flutter/material.dart';

class ServiceItemScreen extends StatefulWidget {
  const ServiceItemScreen({super.key});

  @override
  State<ServiceItemScreen> createState() => _ScaffoldExampleState();
}

class _ScaffoldExampleState extends State<ServiceItemScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a service Item'),
      ),
      body: Center(child: Text('You have added $_count service items.')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        tooltip: 'Service item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
