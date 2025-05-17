import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }


  signup() async{
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
      //Navigate to the auth screen which will handle redirection
      Navigator.of(context).pushReplacementNamed('toAuth');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign up';
      
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already in use';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'Email/password accounts are not enabled';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 200,
                width: 200,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2000),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.fill,),),
              ),

              SizedBox(height: 30,),

              Text("SIGN UP", style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lora',
                  color: HexColor('#6c1448')
                // fontStyle: FontStyle.italic
              ),
              ),

              SizedBox(height: 20,),

              //subtitle
              Text("Welcome to our app! Hope to enjoy", style:
              TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  fontFamily: "DancingScript",
                  color: HexColor('#916d35')
              ),
              ),

              SizedBox(height: 10,),

              Container(
                padding: EdgeInsetsDirectional.fromSTEB(20, 10, 20, 10),
                child: TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  controller: emailController,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email),
                    labelText: 'Enter your email',
                    labelStyle: TextStyle(
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              //TextFormField -> password
              Container(
                padding: EdgeInsetsDirectional.fromSTEB(20, 10, 20, 10),
                child: TextFormField(
                  controller: passwordController,
                  cursorColor: Colors.black,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.key),
                    labelStyle: TextStyle(
                      color: Colors.black,
                    ),
                    labelText: 'Enter your password',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.black,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),




              //Forget password ? TextButton


              //Button -> sign in
              Container(
                width: double.infinity,
                height: 40,
                margin: EdgeInsetsDirectional.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: MaterialButton(
                  shape: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: HexColor('#916d35'),
                  onPressed: signup,
                  child: Text("sign up", style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Lora",
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                  ),
                ),
              ),




              SizedBox(height: 20,),
              //Text -> don't have an account? TextButton
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account ?",
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: "Lora",
                      fontSize: 15,
                    ),
                  ),
                  TextButton(
                    onPressed: (){
                      Navigator.of(context).pushReplacementNamed('toLoginScreen');
                    },
                    child:
                    Text("Sign In",
                      style: TextStyle(
                          color: Colors.green[500],
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Lora",
                          fontStyle: FontStyle.italic
                      ),
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
