import 'package:flutter/cupertino.dart';

class Dimension {

  static bool land = false;
  static DeviceType deviceType = DeviceType.phone;
  static late double width;
  static late double height;
  static late MediaQueryData query;

  static init(BuildContext context) {
    query = MediaQuery.of(context);
    width = query.size.width;
    height = query.size.height - query.viewPadding.vertical;
    land = width>height;
    deviceType = _getDeviceType();
  }

  static double scalePixel(double px) {
    return px * (land ? height : width) / 100;
  }

  static double mapValue(x,inMin,inMax,outMin,outMax){
    return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  }

  static double scalePt(double pt){
    return (land?height:width)*(pt)/375;
  }

  static DeviceType _getDeviceType(){
    if(query.size.width<=550){
      return DeviceType.phone;
    }
    if(query.size.width<=1000){
      return DeviceType.tablet;
    }
    if(query.size.width<=1400){
      return DeviceType.desktop;
    }
      return DeviceType.ultrawide;
  }

}

enum DeviceType{
  phone,
  tablet,
  desktop,
  ultrawide
}