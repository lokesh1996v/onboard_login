import '../countrycodes/country.dart';
import '../dimension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class OnBoarding extends StatefulWidget{
  const OnBoarding({Key? key}) : super(key: key);

  @override
  State<OnBoarding> createState() => _OnBoardingState();


  Future<bool> isUserLoggedIn();

  SplashScreen splashParams();

  Widget buildSplashScreen(){
    //use material background
    return Scaffold(
      backgroundColor: splashParams().backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if(splashParams().backgroundImage!=null)
            Image(image: splashParams().backgroundImage!, fit: BoxFit.cover,),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if(splashParams().centerLogo!=null)
                splashParams().centerLogo!,
              if(splashParams().centerLogo!=null)
              const SizedBox(height: 12,),
              if(splashParams().progressIndicator!=null)
                splashParams().progressIndicator!,
              if(splashParams().progressIndicator!=null)
              const SizedBox(height: 12,),
              if(splashParams().logoText!=null)
                splashParams().logoText!
            ],
          )
        ],
      ),
    );
  }

  List<OnboardingItem> onboardingParams();

  List<Widget> buildOnboardScreen(
      {required BuildContext context, required Function(int index) onNext}){
    return List.generate(onboardingParams().length, (index) {
      final item = onboardingParams()[index];
      return Scaffold(
        backgroundColor: splashParams().backgroundColor,
        body: InkWell(
          onTap: (){
            onNext(index);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(image: item.image, fit: BoxFit.cover,),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black12,
                      Colors.black12,
                      Colors.black54,
                      Colors.black87,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                alignment: Alignment.center,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: 520
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32,left: 20, right: 12),
                    child: Row(
                      children: [
                        Text((index+1).toString(), style: TextStyle(fontSize: 84, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 24,right: 20),
                            child: Text.rich(TextSpan(
                                children: [
                                  TextSpan(text: "${item.title}\n", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                                  TextSpan(text: item.subtitle, style: const TextStyle(fontSize: 18, color: Colors.white)),
                                ]
                            ), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.start,),
                          ),
                        ),
                        IconButton(onPressed: (){
                          onNext(index);
                        },
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white,))
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  Widget buildLoginPage(BuildContext context,LoginParams params);

  onLoading(bool loading);

  onCodeSent();

  onVerificationSuccess();

  onAuthFailed(String? message,{bool otpFailed = false});

  onNextPage({bool isNewUser = true});

}

class _OnBoardingState extends State<OnBoarding> {

  final _controller = PageController();
  late SharedPreferences _preferences;

  final phoneNumber = TextEditingController();
  final otp = TextEditingController();
  Country country = Country.SE;
  FocusNode otpNode = FocusNode();
  FocusNode phoneNode = FocusNode();

  //LOGIN
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //phone login
  String? _verificationId;
  ConfirmationResult? confirmationResultWeb;
  AuthState state = AuthState.STATUS_NONE;
  bool loading = false;


  @override
  initState(){
    super.initState();
    SharedPreferences.getInstance().then((value) {
      _preferences = value;
      widget.isUserLoggedIn().then((value) {
        if(value){
          widget.onNextPage();
        }else{
          _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      });
    });
  }

  @override
  void setState(VoidCallback fn) {
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      super.setState(fn);
    });
  }

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          widget.buildSplashScreen(),
          for(var a in widget.buildOnboardScreen(context: context, onNext: (index){
            // if(widget.onboardingParams().length==index){
            //   _preferences.setBool("onboard", true);
            // }
              _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
          }))
          a,
          widget.buildLoginPage(context,LoginParams(country: country, phoneNumber: phoneNumber, otp: otp, onCountryChange: (country){}, state: state, sendOtp: (){}, verifyOtp: (){})),
        ],
      ),
    );
  }

  onStateUpdate(AuthState state,{String? message}){
    if((this.state==AuthState.STATUS_CODE_SENT || this.state==AuthState.STATUS_FAILED) && state==AuthState.STATUS_FAILED){
      this.state = AuthState.STATUS_FAILED_OTP;
    }else{
      this.state = state;
    }
    String? newMessage;
    if(message?.isNotEmpty??false) {
      newMessage = (message?.split("]")??[""]).last;
    }
    setState(() {

    });
    switch(state){
      case AuthState.STATUS_CODE_SENT: widget.onCodeSent();
      break;
      case AuthState.STATUS_VERFIED: widget.onVerificationSuccess();
      break;
      case AuthState.STATUS_FAILED:widget.onAuthFailed(newMessage);
      break;
      case AuthState.STATUS_FAILED_OTP:widget.onAuthFailed(newMessage, otpFailed: true);
      break;
      case AuthState.STATUS_SUCCESS:widget.onNextPage();
      break;
      default:
    }
  }

  Future<void> verifyPhone() async {
    if(phoneNumber.text.length<9){
      onStateUpdate(AuthState.STATUS_FAILED, message: "Invalid phone number!");
      return;
    }
    phoneNode.unfocus();
    setState(() {
      loading = true;
    });
    if(kIsWeb){
      try {
        confirmationResultWeb = await _auth.signInWithPhoneNumber(
          "+"+country.dialingCode+phoneNumber.text,);
        _verificationId = confirmationResultWeb?.verificationId;
        if (_verificationId != null) {
          onStateUpdate(AuthState.STATUS_CODE_SENT);
          otpNode.requestFocus();
        }
      }catch(err){
        onStateUpdate(AuthState.STATUS_FAILED,message: err.toString());
      }
      setState(() {
        loading = false;
      });
    }else{
      await _auth.verifyPhoneNumber(
        phoneNumber: "+"+country.dialingCode+phoneNumber.text,
        codeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
        codeSent: (String? verId, [int? forceCodeResend]) {
          _verificationId = verId;
          setState(() {
            loading = false;
          });
          otpNode.requestFocus();
          onStateUpdate(AuthState.STATUS_CODE_SENT);
        },
        timeout: const Duration(seconds: 120),
        verificationCompleted: (credential) async {
          _phoneSignIn(credential);
          onStateUpdate(AuthState.STATUS_VERFIED);
        },
        verificationFailed: (exception) {
          setState(() {
            loading = false;
          });
          onStateUpdate(AuthState.STATUS_FAILED_OTP,message: exception.message?.toString());
        },
      );
    }
  }

  phoneVerifyOtp() async{
    if(otp.text.isEmpty){
      onStateUpdate(AuthState.STATUS_FAILED,message: "Invalid OTP");
      return;
    }
    otpNode.unfocus();
    setState(() {
      loading = true;
    });
    try{
      // FAuth.instance.pause();
      if(kIsWeb){
        final creds = await confirmationResultWeb?.confirm(otp.text);
        onStateUpdate(AuthState.STATUS_VERFIED);
        setState(() {
          loading = false;
        });
        moveToNext(creds!);
      }else{
        AuthCredential credential = PhoneAuthProvider.credential(verificationId: _verificationId??"", smsCode: otp.text);
        setState(() {
          loading = false;
        });
        _phoneSignIn(credential);
      }
    }catch(err){
      setState(() {
        loading = false;
      });
      await (_auth.currentUser?.reload());
      onStateUpdate(AuthState.STATUS_FAILED_OTP,message:(err as FirebaseAuthException).message??"Phone number not verified!");
    }
  }

  _phoneSignIn(AuthCredential credential) async {
    setState(() {
      loading = true;
    });
    try{
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() {
        loading = false;
      });
      if(result.user!=null){
        moveToNext(result);
      }else{
        onStateUpdate(AuthState.STATUS_FAILED,message:"Failed to authenticate account with this phone number");
      }
    }catch(err){
      setState(() {
        loading = false;
      });
      print(err);
      try{
        onStateUpdate(AuthState.STATUS_FAILED,message: err.toString().split(",").last);
      }catch(errr){
        onStateUpdate(AuthState.STATUS_FAILED,message: err.toString());
      }
    }
  }

  moveToNext(UserCredential result,{bool isGoogle = false}) async{
    if(result.user!=null){
      setState(() {
        loading = true;
      });
      final user = await FirebaseAuth.instance.currentUser;
      await user?.reload();
      if(user!=null){
        _preferences.setBool('auth', true);
        onStateUpdate(AuthState.STATUS_SUCCESS,message: result.additionalUserInfo?.isNewUser.toString());
      }else{
        onStateUpdate(AuthState.STATUS_FAILED,message: "Failed to login");
      }
      setState(() {
        loading = false;
      });
    }else{
      onStateUpdate(AuthState.STATUS_FAILED,message: "Something went wrong");
    }
  }
}

class SplashScreen{
  ImageProvider? backgroundImage;
  Image? centerLogo;
  Color backgroundColor;
  Text? logoText;
  ProgressIndicator? progressIndicator;

  SplashScreen(
      {this.backgroundImage,
      this.centerLogo,
      this.logoText,
        required this.backgroundColor,
      this.progressIndicator});
}

class OnboardingItem{
  ImageProvider image;
  String title;
  String subtitle;

  OnboardingItem({required this.image, required this.title, required this.subtitle});
}

class LoginParams{
  Country country;
  TextEditingController phoneNumber;
  TextEditingController otp;
  Function(Country) onCountryChange;
  AuthState state;
  Function() sendOtp;
  Function() verifyOtp;
  Function()? resetFields;
  bool isLoading;
  LoginParams({required this.country,
    required this.phoneNumber,
    required this.otp, required this.onCountryChange, required this.state, required this.sendOtp, required this.verifyOtp, this.resetFields, this.isLoading = false});
}

enum AuthState{
  STATUS_NONE,
  STATUS_LOADING,
  STATUS_FAILED,
  STATUS_CODE_SENT,
  STATUS_FAILED_OTP,
  STATUS_VERFIED,
  STATUS_SUCCESS,
  //phone
}