import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/models/user_model.dart';
// Note: You need to specify web clientId if you are on web. I'll include the one used in previous snippets, but it might need to match exactly.
// The user provided '437822465539-unodc8ggt8habhhh1hoh6n09bp4ljjda.apps.googleusercontent.com'

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '437822465539-unodc8ggt8habhhh1hoh6n09bp4ljjda.apps.googleusercontent.com',
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Sign in with Email/Password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return result.docs.isEmpty;
    } catch (e) {
      print("Error checking username: $e");
      return true; // Fail safe, assume available but let later validation catch it or error
    }
  }

  // Sign Up with Email/Password
  Future<List<String>> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required int age,
    required String gender,
    required String town,
    required String state,
    required String country,
    required String role,
  }) async {
    List<String> errors = [];
    try {
      // 1. Check username again to be safe
      bool available = await isUsernameAvailable(username);
      if (!available) {
        return ["Username is already taken."];
      }

      // 2. Create Auth User
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // 3. Create UserModel
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email!,
          username: username,
          fullName: fullName,
          age: age,
          gender: gender,
          town: town,
          state: state,
          country: country,
          role: role,
          createdAt: DateTime.now(),
        );

        // 4. Save to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // 5. Update Display Name
        await user.updateDisplayName(fullName);
      }
    } on FirebaseAuthException catch (e) {
      errors.add(e.message ?? "Authentication failed");
    } catch (e) {
      errors.add(e.toString());
    }
    return errors;
  }

  // Sign In with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelled
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;
      if (user != null) {
        return await _saveGoogleUserToFirestore(user);
      }
      return null;
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  // Save/Retrieve Google User
  Future<UserModel?> _saveGoogleUserToFirestore(User user) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email!,
          username:
              user.displayName?.replaceAll(' ', '').toLowerCase() ??
              'user${user.uid.substring(0, 5)}',
          fullName: user.displayName ?? '',
          age: 0, // Incomplete
          gender: 'Not Specified',
          town: 'Not Specified',
          state: 'Not Specified',
          country: 'Not Specified',
          role: 'Farmer',
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      print("Error saving Google user: $e");
      return null;
    }
  }

  // Get User Data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      print("Error updating profile: $e");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
