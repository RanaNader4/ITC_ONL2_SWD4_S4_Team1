import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future signIn() async{
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign in';
      
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled';
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
          content: Text('Sign in failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  toSignUP(){
    Navigator.of(context).pushReplacementNamed('toSignupScreen');
  }

  toForget(){
    Navigator.of(context).pushReplacementNamed('toForgetPassword');
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
          
              Text("SIGN IN", style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lora',
                color: HexColor('#6c1448')
                // fontStyle: FontStyle.italic
              ),
              ),
          
              SizedBox(height: 20,),
          
              //subtitle
              Text("Welcome back ! Nice to see you again", style:
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
          
              Padding(
                padding: const EdgeInsets.fromLTRB(200, 0, 0, 0),
                child: TextButton(
                  onPressed: toForget,
                  child: Text('Forget password ?', style: TextStyle(
                      fontSize:15,
                      fontWeight: FontWeight.bold,
                      color: HexColor('#2984d0'),
                      fontFamily: "Lora"
                  ),
                  ),
                ),
              ),
          
              SizedBox(height: 15,),
          
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
                  onPressed: signIn,
                  child: Text("sign in", style: TextStyle(
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
                  Text("Don't have an account ?",
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: "Lora",
                      fontSize: 15,
                    ),
                  ),
                  TextButton(
                    onPressed: toSignUP,
                    child:
                    Text("Sign Up",
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
