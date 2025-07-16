import 'package:flutter/material.dart';

class CardMonitor extends StatelessWidget {
  final String measurement;
  final String measurementType;

  const CardMonitor(
      {super.key, required this.measurement, required this.measurementType});

  @override
  Widget build(BuildContext context) {
    return Card(
        color: const Color.fromARGB(255, 61, 9, 93),
        child: Center(
          child: Column(
            children: [
              Text(
                measurement,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 100,
                ),
              ),
              Text(measurementType,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ))
            ],
          ),
        ));
  }
}
