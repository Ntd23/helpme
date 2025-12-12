import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../screens/EditProfileScreen.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import '../utils/Extensions/StringExtensions.dart';

import '../components/OTPDialog.dart';
import '../main.dart';
import '../network/RestApis.dart';
import '../screens/DashBoardScreen.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import 'AuthService1.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> loginWithOTP(BuildContext context, String phoneNumber) async {
  appStore.setLoading(true);
  return await _auth.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    verificationCompleted: (PhoneAuthCredential credential) async {
      appStore.setLoading(false);
    },
    verificationFailed: (FirebaseAuthException e) {
      if (e.code == 'invalid-phone-number') {
        toast('The provided phone number is not valid.');
        throw 'The provided phone number is not valid.';
      } else {
        log('**************${e.toString()}');
        appStore.setLoading(false);
        toast(e.toString());
        throw e.toString();
      }
    },
    codeSent: (String verificationId, int? resendToken) async {
      Navigator.pop(context);
      appStore.setLoading(false);
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: OTPDialog(
            verificationId: verificationId,
            isCodeSent: true,
            phoneNumber: phoneNumber,
          ),
        ),
        barrierDismissible: false,
      );
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      appStore.setLoading(false);
    },
  );
}

class GoogleAuthServices {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  AuthServices authService = AuthServices();
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    await _googleSignIn.initialize(
      clientId:
          '949004985438-egojtjtbf1kkqs7t4nqk8mfbfg5ha28r.apps.googleusercontent.com',
      // nếu Firebase báo cần serverClientId thì truyền web client ID vào đây:
      // serverClientId: 'YOUR_WEB_CLIENT_ID',
    );
    _isInitialized = true;
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _ensureInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        // chỉ xảy ra trên web; app ông mobile thì bình thường
        throw Exception(
          'GoogleSignIn.authenticate() is not supported on this platform',
        );
      }
      // v7: authenticate() thay cho signIn()
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: const ['email'],
      );
      // v7: authentication là sync property, KHÔNG await
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        // accessToken: googleSignInAuthentication.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential authResult = await _auth.signInWithCredential(
        credential,
      );
      final User user = authResult.user!;

      assert(!user.isAnonymous);

      final User currentUser = _auth.currentUser!;
      assert(user.uid == currentUser.uid);
      // ngắt phiên Google bên ngoài (tuỳ ông có muốn giữ không)
      await _googleSignIn.disconnect();

      await loginFromFirebase(user, LoginTypeGoogle, googleAuth.idToken);
    } on GoogleSignInException catch (e) {
      // user cancel, config lỗi… đều nhảy vào đây
      log('GoogleSignInException: code=${e.code.name}, desc=${e.description}');
      throw e;
    } catch (e) {
      log('Google sign-in error: $e');
      throw e;
    }
  }
}

/// Sign-In with Apple.
Future<void> appleLogIn() async {
  if (await TheAppleSignIn.isAvailable()) {
    AuthorizationResult result = await TheAppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName]),
    ]);
    switch (result.status) {
      case AuthorizationStatus.authorized:
        final appleIdCredential = result.credential!;
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          accessToken: String.fromCharCodes(
            appleIdCredential.authorizationCode!,
          ),
        );
        final authResult = await _auth.signInWithCredential(credential);
        final user = authResult.user!;

        if (result.credential!.email != null) {
          await saveAppleData(result);
        }

        await loginFromFirebase(
          user,
          LoginTypeApple,
          String.fromCharCodes(appleIdCredential.authorizationCode!),
        );
        break;
      case AuthorizationStatus.error:
        throw ("Sign in failed: ${result.error!.localizedDescription}");
      case AuthorizationStatus.cancelled:
        throw ('User cancelled');
    }
  } else {
    throw ('Apple SignIn is not available for your device');
  }
}

Future<void> saveAppleData(AuthorizationResult result) async {
  await sharedPref.setString('appleEmail', result.credential!.email.validate());
  await sharedPref.setString(
    'appleGivenName',
    result.credential!.fullName!.givenName.validate(),
  );
  await sharedPref.setString(
    'appleFamilyName',
    result.credential!.fullName!.familyName.validate(),
  );
}

Future deleteUser(String email, String password) async {
  if (FirebaseAuth.instance.currentUser != null) {
    FirebaseAuth.instance.currentUser!.delete();
    await FirebaseAuth.instance.signOut();
  }
}

Future<void> loginFromFirebase(
  User currentUser,
  String loginType,
  String? accessToken,
) async {
  String firstName = '';
  String lastName = '';
  if (loginType == LoginTypeGoogle) {
    if (currentUser.displayName.validate().split(' ').length >= 1)
      firstName = currentUser.displayName.splitBefore(' ');
    if (currentUser.displayName.validate().split(' ').length >= 2)
      lastName = currentUser.displayName.splitAfter(' ');
  } else {
    firstName = sharedPref.getString('appleGivenName').validate();
    lastName = sharedPref.getString('appleFamilyName').validate();
  }
  Map req = {
    "email": currentUser.email,
    "login_type": loginType,
    "user_type": RIDER,
    "first_name": firstName,
    "last_name": lastName,
    "username": (firstName + lastName).toLowerCase(),
    "uid": currentUser.uid,
    'accessToken': accessToken,
    "player_id": sharedPref.getString(PLAYER_ID).validate(),
    if (!currentUser.phoneNumber.isEmptyOrNull)
      'contact_number': currentUser.phoneNumber.validate(),
  };

  await logInApi(req, isSocialLogin: true)
      .then((value) async {
        AuthServices authService = AuthServices();
        authService
            .loginFromFirebaseUser(
              currentUser,
              loginDetail: value,
              fullName: (firstName + lastName).toLowerCase(),
            )
            .then((value) {});
        Navigator.pop(getContext);
        sharedPref.setString(UID, currentUser.uid);
        await appStore.setUserProfile(currentUser.photoURL.toString());
        await sharedPref.setString(
          USER_PROFILE_PHOTO,
          currentUser.photoURL.toString(),
        );
        if (value.data!.contactNumber.isEmptyOrNull) {
          launchScreen(
            getContext,
            EditProfileScreen(isGoogle: true),
            isNewTask: true,
            pageRouteAnimation: PageRouteAnimation.Slide,
          );
        } else {
          if (value.data!.uid.isEmptyOrNull) {
            await updateProfile(
                  uid: sharedPref.getString(UID).toString(),
                  userEmail: currentUser.email.validate(),
                )
                .then((value) {
                  launchScreen(
                    getContext,
                    DashBoardScreen(),
                    isNewTask: true,
                    pageRouteAnimation: PageRouteAnimation.Slide,
                  );
                })
                .catchError((error) {
                  log(error.toString());
                });
          } else if (value.data!.playerId.isEmptyOrNull) {
            await updatePlayerId()
                .then((value) {
                  launchScreen(
                    getContext,
                    DashBoardScreen(),
                    isNewTask: true,
                    pageRouteAnimation: PageRouteAnimation.Slide,
                  );
                })
                .catchError((error) {
                  log(error.toString());
                });
          } else {
            launchScreen(
              getContext,
              DashBoardScreen(),
              isNewTask: true,
              pageRouteAnimation: PageRouteAnimation.Slide,
            );
          }
        }
      })
      .catchError((e) {
        log(e.toString());
        throw e;
      });
}
