import 'package:flutter/material.dart';
import 'package:patientcarehub/HomeScreen/HomeScreenPatient.dart';
import 'package:patientcarehub/Services/authentication.dart';
import 'package:patientcarehub/USER_Regestration/login_screen.dart';
import 'package:patientcarehub/widgets/button.dart';
import 'package:patientcarehub/widgets/snack_bar.dart';
import 'package:patientcarehub/widgets/text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void signUpUser() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showSnackBar(context, "All fields are required.");
      return;
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      showSnackBar(context, "Name should contain only letters.");
      return;
    }

    // Email should not start with a number and must be valid
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      showSnackBar(
          context, "Enter a valid email that does not start with a number.");
      return;
    }

    // Password must contain both letters and numbers and be at least 6 characters long
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$').hasMatch(password)) {
      showSnackBar(context,
          "Password must be at least 6 characters and contain both letters and numbers.");
      return;
    }

    // Passwords should match
    if (password != confirmPassword) {
      showSnackBar(context, "Passwords do not match.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    String res = await AuthServices().signUpUser(
      email: email,
      password: password,
      name: name,
    );

    setState(() {
      isLoading = false;
    });

    if (res == "Successfully") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Homescreenpatient(),
        ),
      );
    } else {
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: height / 2.7,
                  child: Image.asset("assets/otp.jpg"),
                ),
                const SizedBox(height: 20),
                TextFieldInput(
                  textEditingController: nameController,
                  hintText: "Enter Your Name",
                  icon: Icons.person,
                ),
                const SizedBox(height: 20),
                TextFieldInput(
                  textEditingController: emailController,
                  hintText: "Enter Your Email",
                  icon: Icons.email,
                ),
                const SizedBox(height: 20),
                TextFieldInput(
                  textEditingController: passwordController,
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
                const SizedBox(height: 20),
                TextFieldInput(
                  textEditingController: confirmPasswordController,
                  hintText: "Confirm Your Password",
                  isPass: !isConfirmPasswordVisible,
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isConfirmPasswordVisible = !isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: UseButton(
                    onTab: isLoading ? null : signUpUser,
                    text: isLoading ? "Loading..." : "Sign Up",
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : null,
                  ),
                ),
                SizedBox(height: height / 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(fontSize: 16),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        " Log In",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
