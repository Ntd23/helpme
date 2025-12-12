import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:taxi_driver/components/OTPDialog.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/screens/DashboardScreen.dart';
import 'package:taxi_driver/screens/DocumentsScreen.dart';
import 'package:taxi_driver/utils/Extensions/StringExtensions.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

import '../main.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/EditProfileScreen.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class AuthServices {
  Future<void> updateUserData(UserData user) async {
    userService.updateDocument({
      'player_id': sharedPref.getString(PLAYER_ID),
      'updatedAt': Timestamp.now(),
    }, user.uid);
  }

  Future<User?> createAuthUser(String? email, String? password, bool isOtpLogin) async {
    User? userCredential;
    try {
      if (!isOtpLogin) {
        await _auth.createUserWithEmailAndPassword(email: email!, password: password!).then((value) {
          userCredential = value.user!;
        });
      } else {
        userCredential = _auth.currentUser;
      }
    } on FirebaseException catch (error) {
      if (error.code == "ERROR_EMAIL_ALREADY_IN_USE" || error.code == "account-exists-with-different-credential" || error.code == "email-already-in-use") {
        await _auth.signInWithEmailAndPassword(email: email!, password: password!).then((value) {
          userCredential = value.user!;
        });
      } else {
        toast(getMessageFromErrorCode(error));
      }
    }
    return userCredential;
  }

  Future<void> signUpWithEmailPassword(
    context, {
    String? email,
    String? password,
    String? mobileNumber,
    String? fName,
    String? lName,
    String? userName,
    String? userType,
    bool isOtpLogin = false,
  }) async {
    try {
      createAuthUser(email, password, isOtpLogin).then((user) async {
        if (user != null) {
          User currentUser = user;

          UserData userModel = UserData();

          /// Create user
          userModel.uid = currentUser.uid.validate();
          userModel.email = email;
          userModel.contactNumber = mobileNumber.validate();
          userModel.username = userName.validate();
          userModel.userType = userType.validate();
          userModel.displayName = fName.validate() + " " + lName.validate();
          userModel.firstName = fName.validate();
          userModel.lastName = lName.validate();
          userModel.createdAt = Timestamp.now().toDate().toString();
          userModel.updatedAt = Timestamp.now().toDate().toString();
          userModel.playerId = sharedPref.getString(PLAYER_ID).validate();
          sharedPref.setString(UID, user.uid.validate());

          await userService.addDocumentWithCustomId(currentUser.uid, userModel.toJson()).then((value) async {
            Map request = {
              "email": userModel.email,
              "password": password,
              "player_id": sharedPref.getString(PLAYER_ID).validate(),
              'user_type':DRIVER,
            };
            if (isOtpLogin) {
              appStore.setLoading(false);
              updateProfileUid();
              if (sharedPref.getInt(IS_Verified_Driver) == 1) {
                launchScreen(context, DashboardScreen());
              } else {
                launchScreen(context, DocumentsScreen(isShow: true), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
              }
            } else {
              await logInApi(request).then((res) async {
                appStore.setLoading(false);
                updateProfileUid();
                if (sharedPref.getInt(IS_Verified_Driver) == 1) {
                  launchScreen(context, DashboardScreen());
                } else {
                  launchScreen(context, DocumentsScreen(isShow: true), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
                }
              }).catchError((e) {
                appStore.setLoading(false);
                log(e.toString());
                toast(e.toString());
              });
            }
          });
        } else {
          appStore.setLoading(false);
          throw 'Something went wrong';
        }
      });
    } on FirebaseException catch (error) {
      appStore.setLoading(false);
      toast(getMessageFromErrorCode(error));
    }
  }

  Future<void> signInWithEmailPassword(context, {required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password).then((value) async {
      appStore.setLoading(true);
      final User user = value.user!;
      UserData userModel = await userService.getUser(email: user.email);
      await updateUserData(userModel);

      appStore.setLoading(true);
      //Login Details to SharedPreferences
      sharedPref.setString(UID, userModel.uid.validate());
      sharedPref.setString(USER_EMAIL, userModel.email.validate());
      sharedPref.setBool(IS_LOGGED_IN, true);

      //Login Details to AppStore
      appStore.setUserEmail(userModel.email.validate());
      appStore.setUId(userModel.uid.validate());

      //
    }).catchError((e) {
      toast(e.toString());
      log(e.toString());
    });
  }

  Future<void> loginFromFirebaseUser(User currentUser, {LoginResponse? loginDetail, String? fullName, String? fName, String? lName}) async {
    UserData userModel = UserData();

    if (await userService.isUserExist(loginDetail!.data!.email)) {
      ///Return user data
      await userService.userByEmail(loginDetail.data!.email).then((user) async {
        userModel = user;
        appStore.setUserEmail(userModel.email.validate());
        appStore.setUId(userModel.uid.validate());

        await updateUserData(user);
      }).catchError((e) {
        log(e);
        throw e;
      });
    } else {
      /// Create user
      userModel.uid = currentUser.uid.validate();
      userModel.id = loginDetail.data!.id;
      userModel.email = loginDetail.data!.email.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.email = loginDetail.data!.email.validate();

      if (Platform.isIOS) {
        userModel.username = fullName;
      } else {
        userModel.username = loginDetail.data!.username.validate();
      }

      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.profileImage = loginDetail.data!.profileImage.validate();
      userModel.playerId = sharedPref.getString(PLAYER_ID);

      sharedPref.setString(UID, currentUser.uid.validate());
      log(sharedPref.getString(UID)!);
      sharedPref.setString(USER_EMAIL, userModel.email.validate());
      sharedPref.setBool(IS_LOGGED_IN, true);

      log(userModel.toJson());

      await userService.addDocumentWithCustomId(currentUser.uid, userModel.toJson()).then((value) {
        //
      }).catchError((e) {
        throw e;
      });
    }
  }

  Future<void> loginWithOTP(BuildContext context, String phoneNumber) async {
    return await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          toast('The provided phone number is not valid.');
          throw 'The provided phone number is not valid.';
        } else {
          toast(e.toString());
          throw e.toString();
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        Navigator.pop(context);
        appStore.setLoading(false);
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(content: OTPDialog(verificationId: verificationId, isCodeSent: true, phoneNumber: phoneNumber)),
          barrierDismissible: false,
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        //
      },
    );
  }

  Future deleteUserFirebase() async {
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.currentUser!.delete();
      await FirebaseAuth.instance.signOut();
    }
  }
}

class GoogleAuthServices {
  // v7: dùng singleton instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  AuthServices authService = AuthServices();

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    await _googleSignIn.initialize(
      // dùng luôn web client ID giống Rider (nếu 2 app chung 1 Firebase project)
      clientId:
      '949004985438-egojtjtbf1kkqs7t4nqk8mfbfg5ha28r.apps.googleusercontent.com',
      // nếu Firebase báo cần serverClientId cho Android Credential Manager
      // thì dùng cùng giá trị web client ID ở đây:
      // serverClientId: '949004985438-egojtjtbf1kkqs7t4nqk8mfbfg5ha28r.apps.googleusercontent.com',
    );

    _isInitialized = true;
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      appStore.setLoading(true);

      // Đảm bảo đã init GoogleSignIn v7
      await _ensureInitialized();

      // v7: kiểm tra platform có hỗ trợ authenticate() không
      if (!_googleSignIn.supportsAuthenticate()) {
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

      // chỉ cần idToken cho Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // Nếu backend cần accessToken thì có thể thêm:
        // accessToken: googleAuth.accessToken,
      );

      final UserCredential authResult =
      await _auth.signInWithCredential(credential);
      final User user = authResult.user!;

      assert(!user.isAnonymous);

      final User currentUser = _auth.currentUser!;
      assert(user.uid == currentUser.uid);

      // Ngắt session Google bên ngoài (tuỳ ông có muốn giữ không)
      await _googleSignIn.disconnect();

      // Ở Driver: truyền idToken (Rider cũng truyền idToken)
      await loginFromFirebase(user, LoginTypeGoogle, googleAuth.idToken);
    } on GoogleSignInException catch (e) {
      // Lỗi từ plugin google_sign_in (user cancel, config sai, thiếu clientId, ...)
      log('GoogleSignInException: code=${e.code.name}, desc=${e.description}');
      toast(e.description ?? e.code.name);
      rethrow;
    } catch (e) {
      log('Google sign-in error: $e');
      toast(e.toString());
      rethrow;
    } finally {
      appStore.setLoading(false);
    }
  }
}


/// Sign-In with Apple.
Future<void> appleLogIn() async {
  if (await TheAppleSignIn.isAvailable()) {
    AuthorizationResult result = await TheAppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);
    switch (result.status) {
      case AuthorizationStatus.authorized:
        final appleIdCredential = result.credential!;
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          accessToken: String.fromCharCodes(appleIdCredential.authorizationCode!),
        );
        final authResult = await _auth.signInWithCredential(credential);
        final user = authResult.user!;

        if (result.credential!.email != null) {
          await saveAppleData(result);
        }

        await loginFromFirebase(user, LoginTypeApple, String.fromCharCodes(appleIdCredential.authorizationCode!));
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
  await sharedPref.setString('appleGivenName', result.credential!.fullName!.givenName.validate());
  await sharedPref.setString('appleFamilyName', result.credential!.fullName!.familyName.validate());
}

Future<void> loginFromFirebase(User currentUser, String loginType, String? accessToken) async {
  String firstName = '';
  String lastName = '';
  if (loginType == LoginTypeGoogle) {
    if (currentUser.displayName.validate().split(' ').length >= 1) firstName = currentUser.displayName.splitBefore(' ');
    if (currentUser.displayName.validate().split(' ').length >= 2) lastName = currentUser.displayName.splitAfter(' ');
  } else {
    firstName = sharedPref.getString('appleGivenName').validate();
    lastName = sharedPref.getString('appleFamilyName').validate();
  }
  Map req = {
    "email": currentUser.email,
    "login_type": loginType,
    "user_type": DRIVER,
    "first_name": firstName,
    "last_name": lastName,
    "username": currentUser.email,
    "uid": currentUser.uid,
    'accessToken': accessToken,
    if (!currentUser.phoneNumber.isEmptyOrNull) 'contact_number': currentUser.phoneNumber.validate(),
  };

  await logInApi(req, isSocialLogin: true).then((value) async {
    AuthServices authService = AuthServices();
    authService.loginFromFirebaseUser(currentUser, loginDetail: value, fullName: (firstName + lastName).toLowerCase()).then((value) {});
    Navigator.pop(getContext);
    sharedPref.setString(UID, currentUser.uid);
    await appStore.setUserProfile(currentUser.photoURL.toString());
    if (value.data!.contactNumber.isEmptyOrNull) {
      launchScreen(getContext, EditProfileScreen(isGoogle: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
    } else {
      if (value.data!.uid.isEmptyOrNull) {
        await updateProfile(
          uid: sharedPref.getString(UID).toString(),
          userEmail: currentUser.email.validate(),
        ).then((value) {
          if (sharedPref.getInt(IS_Verified_Driver) == 1) {
            launchScreen(getContext, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          } else {
            launchScreen(getContext, DocumentsScreen(isShow: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          }
        }).catchError((error) {
          log(error.toString());
        });
      } else if (value.data!.playerId.isEmptyOrNull) {
        await updatePlayerId().then((value) {
          if (sharedPref.getInt(IS_Verified_Driver) == 1) {
            launchScreen(getContext, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          } else {
            launchScreen(getContext, DocumentsScreen(isShow: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          }
        }).catchError((error) {
          log(error.toString());
        });
      } else {
        if (sharedPref.getInt(IS_Verified_Driver) == 1) {
          launchScreen(getContext, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        } else {
          launchScreen(getContext, DocumentsScreen(isShow: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        }
      }
    }
  }).catchError((e) {
    log(e.toString());
    throw e;
  });
}
