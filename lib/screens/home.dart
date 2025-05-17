import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Screen', style: TextStyle(
                fontSize: 50
            ),),

            SizedBox(height: 20,),

            MaterialButton(
              onPressed: () async{
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('toAuth');
              },
              color: Colors.green,
              child: Text('Log out', style: TextStyle(
                color: Colors.white
              ),
              ),
            )
          ],
        ),
      ),
    );
  }
}