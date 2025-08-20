import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:patientcarehub/Admin_pages/AdminHome.dart';
import 'package:patientcarehub/HomeScreen/HomeScreenDoctor.dart';
import 'package:patientcarehub/HomeScreen/HomeScreenPatient.dart';
import 'package:patientcarehub/USER_Regestration/Forget_password.dart';
import 'package:patientcarehub/USER_Regestration/register_screen.dart';
import 'package:patientcarehub/widgets/button.dart';
import 'package:patientcarehub/widgets/text_field.dart';

import '../Services/authentication.dart';
import '../widgets/snack_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  bool isLoading = false;
  String userType = "";
  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
    });

    String res = await AuthServices().LoginUser(
      email: emailcontroller.text.trim(),
      password: passwordcontroller.text.trim(),
    );

    if (res == "Successfully") {
      await fetchUserType(emailcontroller.text.trim().toLowerCase());

      if (userType == "Patient") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Homescreenpatient()),
        );
      } else if (userType == "Doctor") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomescreenDoctor()),
        );
      } else if (userType == "Admin") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
      } else {
        showSnackBar(context, "User type not recognized!");
      }
    } else {
      showSnackBar(context, res);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchUserType(String email) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email_id', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          userType = querySnapshot.docs.first['userType'];
        });
      } else {
        showSnackBar(context, "User not found in database!");
      }
    } catch (e) {
      showSnackBar(context, "Error fetching user type: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: height / 2.7,
                      child: Image.asset("assets/login.jpg", fit: BoxFit.cover),
                    ),
                    TextFieldInput(
                      textEditingController: emailcontroller,
                      hintText: "Enter Your Email",
                      icon: Icons.email,
                    ),
                    TextFieldInput(
                      textEditingController: passwordcontroller,
                      hintText: "Enter Your Password",
                      isPass: !isPasswordVisible,
                      icon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen()),
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    UseButton(onTab: loginUser, text: "Log in"),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(fontSize: 16),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
