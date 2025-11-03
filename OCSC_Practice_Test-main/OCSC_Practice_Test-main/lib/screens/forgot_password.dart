import 'package:flutter/material.dart';
import 'login.dart';
import 'otp_verification.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ForgotPassword extends StatefulWidget {
   const ForgotPassword({super.key});
   @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}
class _ForgotPasswordState extends State<ForgotPassword> {
   final TextEditingController emailController = TextEditingController();
    bool isEmailValid = false;
  get style => null;

  @override
  void initState(){
    super.initState();
    emailController.addListener(() {
      setState(() {
        isEmailValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(emailController.text);
      });
    });
  }


  Future<void> sendPasswordResetEmail(String email) async{
    try{
      await FirebaseAuth.instance.sendPasswordResetEmail(email:email);
      print("Password reset email sent to $email");
    }catch(e){
      print("Error sending password reset email:$e");
      
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Forgot Password',
            style:TextStyle(fontSize:28,
            fontWeight: FontWeight.bold,)),
            SizedBox(height: 10,),
            Text("Don't worry! It occurs. Please enter the email address linked with your account.",
            style: TextStyle(fontSize:16,
            color:Colors.grey[600])),
            SizedBox(height:30),
            TextField(
              controller:emailController,
              decoration:InputDecoration(
              hintText: 'Enter your email',
              filled:true,
              fillColor: Colors.grey[100],
              border:OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,)
              ,

            ) ,
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:isEmailValid ? () async {
                  final email = emailController.text.trim();
                  if(email.isNotEmpty){
                  await sendPasswordResetEmail(email);
                  print("Password reset email sent to $email");
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("An email has been sent to $email to reset your password.")));
                  Navigator.pop(context);
                }
                : null,
                style:ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical:15),
                  shape:RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )
                ),
                child: Text('Send Code',style:TextStyle(fontSize:16),)
                ,
              ),
            ),
            Spacer(),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Remember your password?',
                  style:TextStyle(color:Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap:(){
                      Navigator.pop(context);
                    },
                    child:Text('Login',
                    style:TextStyle(
                      color:Colors.blue,
                    fontWeight: FontWeight.bold )
                    ),

                  )
                ],),
            ),
            
          ],
        ),),
















   
   
   
   
   
    );
  
  
  
  
  
  
  }
}
