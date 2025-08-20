import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patientcarehub/Doctor_Registration/Image_picker.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() =>
      _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController clinicNameController = TextEditingController();
  final TextEditingController licenseNoController = TextEditingController();
  final TextEditingController clinicIdController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  // List of Indian States
  final List<String> indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal"
  ];

  String? selectedState;

  Future<void> _registerDoctor() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        String doctorId = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({
          'firstName': firstNameController.text,
          'lastName': lastNameController.text,
          'specialization': specializationController.text,
          'experience': int.parse(experienceController.text),
          'clinicName': clinicNameController.text,
          'licenseNo': licenseNoController.text,
          'clinicId': clinicIdController.text,
          'street': streetController.text,
          'city': cityController.text,
          'state': stateController.text,
          'zipCode': zipCodeController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'doctorId': doctorId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor registered successfully')),
        );

        // Navigate to the next screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UploadDoctorImages(), // Navigate to ImageCollector screen
          ),
        );
      } catch (e) {
        print('Error registering doctor: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error registering doctor')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctor Registration')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter first name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter last name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: specializationController,
                  decoration: InputDecoration(labelText: 'Specialization'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Specialization';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: experienceController,
                  decoration: InputDecoration(labelText: 'Experience'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Experience';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: clinicNameController,
                  decoration: InputDecoration(labelText: 'Clinic Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Clinic Name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: licenseNoController,
                  decoration: InputDecoration(labelText: 'License No.'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter License No.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: clinicIdController,
                  decoration: InputDecoration(labelText: 'Clinic ID'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Clinic ID';
                    }
                    return null;
                  },
                ),

                // 🔹 Updated State Selection with Dropdown
                DropdownButtonFormField<String>(
                  value: selectedState,
                  decoration: InputDecoration(
                    labelText: "Select State",
                    border: OutlineInputBorder(),
                  ),
                  items: indianStates.map((String state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedState = newValue;
                      stateController.text = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a state';
                    }
                    return null;
                  },
                ),

                TextFormField(
                  controller: cityController,
                  decoration: InputDecoration(labelText: 'City'),
                ),
                TextFormField(
                  controller: streetController,
                  decoration: InputDecoration(labelText: 'Street'),
                ),
                TextFormField(
                  controller: zipCodeController,
                  decoration: InputDecoration(labelText: 'Zip Code'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, // Allows only numbers
                    LengthLimitingTextInputFormatter(
                        6), // Restricts input to 6 digits
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Zip Code';
                    }
                    if (value.length != 6) {
                      return 'Zip Code must be exactly 6 digits';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : _registerDoctor, // Disable button during loading
                  child: Text(isLoading ? 'Registering...' : 'Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
