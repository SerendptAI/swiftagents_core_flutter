import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


class GetCachedImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final Widget? placeholder;
  final String placeholderPath;
  final BoxFit fit;
  final BoxFit placeholderFit;

  const GetCachedImage({
    this.url,
    this.placeholder,
    this.placeholderPath = 'assets/images/food_placeholder.png',
    this.width = 30,
    this.height = 30,
    this.fit = BoxFit.cover,
    this.placeholderFit = BoxFit.contain,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: fit),
          ),
        ),
        errorWidget: (context, url, error) => kDebugMode
            ? Container(
                width: width,
                height: height,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image,
                  color: Colors.red,
                ),
              )
            : Image.asset(
                placeholderPath,
                fit: BoxFit.contain,
                width: width,
                height: height,
              ),
          progressIndicatorBuilder: (context, url, downloadProgress) =>
              Container(
                width: width,
                height: height,
                alignment: Alignment.center,
                child: placeholder ?? Image.asset(
                  placeholderPath,
                  fit: placeholderFit,
                  width: width,
                  height: height,
                ),
              ),
      );
    } else {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        child: placeholder ?? Image.asset(
          placeholderPath,
          fit: placeholderFit,
          width: width,
          height: height,
        ),
      );
    }
  }
}
