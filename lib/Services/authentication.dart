import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  //for storing data in cloud firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //for authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

//for signUp
  Future<String> signUpUser(
      {required String email,
      required String password,
      required String name}) async {
    String res = "Some Error Occured";
    try {
      if (email.isNotEmpty || password.isNotEmpty || name.isNotEmpty) {
//For register User in firebase
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        //For Adding User to our Cloud Firestore
        await _firestore.collection("Users").doc(credential.user!.uid).set({
          "name": name,
          "email_id": email,
          "uid": credential.user!.uid,
          "userType": "Patient",
          "Login": "True"
        });
        res = "Successfully";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }

  Future<String> LoginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some Error Occured";
    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        //login user with email and password
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        res = "Successfully";
      } else {
        res = "Please Enter all The fields ";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }
}
