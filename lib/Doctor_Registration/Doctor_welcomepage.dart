import 'package:flutter/material.dart';
import 'package:patientcarehub/Doctor_Registration/Doctor_registration.dart';

import '../widgets/custom_button.dart';

class DoctorWelcomepage extends StatefulWidget {
  const DoctorWelcomepage({super.key});

  @override
  State<DoctorWelcomepage> createState() => _DoctorWelcomepageState();
}

class _DoctorWelcomepageState extends State<DoctorWelcomepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 25, horizontal: 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/docReg.png",
                        height: 500,
                      ),
                      const SizedBox(height: 20),
                      const Text("Lets's Get Started !!!!!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 10),
                      const Text(
                          "Modernize your practice. Empower your patient care.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black38,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: CustomButton(
                              text: "Get Registered",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DoctorRegistrationScreen(),
                                  ),
                                );
                              }))
                    ],
                  )))),
    );
  }
}
