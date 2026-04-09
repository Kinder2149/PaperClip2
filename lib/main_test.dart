import 'package:flutter/material.dart';

void main() {
  print('🔥🔥🔥 TEST: Application starting 🔥🔥🔥');
  
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TEST APP',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text('If you see this, Flutter is working!'),
            ],
          ),
        ),
      ),
    ),
  );
}
