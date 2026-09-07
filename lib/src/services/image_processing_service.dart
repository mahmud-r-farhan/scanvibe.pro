import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../enums.dart';

class ImageProcessingService {
  const ImageProcessingService();

  Future<String> processImage({
    required String inputPath,
    required FilterType filter,
    String? outputPath,
  }) async {
    final dir = p.dirname(inputPath);
    final baseName = p.basenameWithoutExtension(inputPath);
    final outPath = outputPath ?? p.join(dir, '${baseName}_${filter.name}.jpg');

    await Isolate.run(() async {
      final bytes = await File(inputPath).readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // Resize if too large
      if (image.width > 2200) {
        final ratio = 2200 / image.width;
        image = img.copyResize(
          image,
          width: 2200,
          height: (image.height * ratio).round(),
          interpolation: img.Interpolation.linear,
        );
      }

      // Apply filter
      switch (filter) {
        case FilterType.autoEnhance:
          image = _autoEnhance(image);
        case FilterType.blackWhite:
          image = _blackAndWhite(image);
        case FilterType.grayscale:
          image = _grayscale(image);
        case FilterType.magicColor:
          image = _magicColor(image);
        case FilterType.sharpen:
          image = _sharpen(image);
        case FilterType.clean:
          image = _clean(image);
      }

      await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 92));
    });

    return outPath;
  }

  Future<String> rotateImage({
    required String inputPath,
    required int degrees,
    String? outputPath,
  }) async {
    final dir = p.dirname(inputPath);
    final baseName = p.basenameWithoutExtension(inputPath);
    final outPath = outputPath ??
        p.join(dir, '${baseName}_rotated_${DateTime.now().millisecondsSinceEpoch}.jpg');

    await Isolate.run(() async {
      final bytes = await File(inputPath).readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      image = img.copyRotate(image, angle: degrees);
      await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 92));
    });

    return outPath;
  }

  static img.Image _autoEnhance(img.Image image) {
    // Adaptive histogram equalization approximation
    final gray = img.grayscale(image);

    // Calculate histogram
    final histogram = List.filled(256, 0);
    for (final pixel in gray) {
      histogram[pixel.r.toInt()]++;
    }

    // Calculate CDF
    final cdf = List.filled(256, 0.0);
    cdf[0] = histogram[0] / (gray.width * gray.height);
    for (var i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i] / (gray.width * gray.height);
    }

    // Apply contrast stretch
    final result = img.Image(width: image.width, height: image.height);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final grayVal = img.getLuminanceRgb(
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
        final newVal = (cdf[grayVal.toInt()] * 255).clamp(0, 255).toInt();

        // Blend original with enhanced for natural look
        final blend = 0.7;
        final r = (pixel.r * (1 - blend) + newVal * blend).clamp(0, 255).toInt();
        final g = (pixel.g * (1 - blend) + newVal * blend).clamp(0, 255).toInt();
        final b = (pixel.b * (1 - blend) + newVal * blend).clamp(0, 255).toInt();

        result.setPixelRgb(x, y, r, g, b);
      }
    }

    // Sharpen slightly
    return _applySharpenKernel(result);
  }

  static img.Image _blackAndWhite(img.Image image) {
    // Sauvola-like adaptive thresholding
    final gray = img.grayscale(image);
    final result = img.Image(width: image.width, height: image.height);

    final windowSize = 15;
    final k = 0.2;
    final R = 128.0;

    // Precompute integral image and integral of squared image
    final integral = List.generate(
      gray.height + 1,
      (y) => List.filled(gray.width + 1, 0.0),
    );
    final integralSq = List.generate(
      gray.height + 1,
      (y) => List.filled(gray.width + 1, 0.0),
    );

    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        final val = gray.getPixel(x, y).r.toDouble();
        integral[y + 1][x + 1] =
            val + integral[y][x + 1] + integral[y + 1][x] - integral[y][x];
        integralSq[y + 1][x + 1] =
            val * val +
                integralSq[y][x + 1] +
                integralSq[y + 1][x] -
                integralSq[y][x];
      }
    }

    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        final x1 = max(0, x - windowSize ~/ 2);
        final y1 = max(0, y - windowSize ~/ 2);
        final x2 = min(gray.width - 1, x + windowSize ~/ 2);
        final y2 = min(gray.height - 1, y + windowSize ~/ 2);

        final count = (x2 - x1 + 1) * (y2 - y1 + 1);
        final sum =
            integral[y2 + 1][x2 + 1] - integral[y1][x2 + 1] - integral[y2 + 1][x1] + integral[y1][x1];
        final sumSq = integralSq[y2 + 1][x2 + 1] -
            integralSq[y1][x2 + 1] -
            integralSq[y2 + 1][x1] +
            integralSq[y1][x1];

        final mean = sum / count;
        final variance = sumSq / count - mean * mean;
        final stddev = sqrt(max(0, variance));

        final threshold = mean * (1 + k * (stddev / R - 1));

        final pixel = gray.getPixel(x, y).r;
        final bw = pixel > threshold ? 255 : 0;
        result.setPixelRgb(x, y, bw, bw, bw);
      }
    }

    return result;
  }

  static img.Image _grayscale(img.Image image) {
    final gray = img.grayscale(image);

    // Boost contrast
    var minVal = 255;
    var maxVal = 0;
    for (final pixel in gray) {
      final val = pixel.r.toInt();
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }

    final range = maxVal - minVal;
    if (range == 0) return gray;

    final result = img.Image(width: gray.width, height: gray.height);
    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        final pixel = gray.getPixel(x, y).r;
        final normalized = ((pixel - minVal) / range * 255).clamp(0, 255).toInt();
        result.setPixelRgb(x, y, normalized, normalized, normalized);
      }
    }

    return result;
  }

  static img.Image _magicColor(img.Image image) {
    // Boost saturation and contrast
    final result = img.Image(width: image.width, height: image.height);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        // Convert to HSL
        final hsl = img.rgbToHsl(
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
        final h = hsl[0];
        final s = hsl[1];
        final l = hsl[2];

        // Boost saturation by 30%
        final newSat = (s * 1.3).clamp(0.0, 1.0);
        // Boost lightness slightly
        final newLit = (l * 1.05).clamp(0.0, 1.0);

        final rgbOut = [0, 0, 0];
        img.hslToRgb(h, newSat, newLit, rgbOut);
        result.setPixelRgb(x, y, rgbOut[0], rgbOut[1], rgbOut[2]);
      }
    }

    return _applySharpenKernel(result);
  }

  static img.Image _sharpen(img.Image image) {
    return _applySharpenKernel(image);
  }

  static img.Image _clean(img.Image image) {
    // Morphological opening (erosion then dilation) to remove small noise
    var result = _morphologicalErode(image, 1);
    result = _morphologicalDilate(result, 1);

    // Then auto-enhance
    return _autoEnhance(result);
  }

  static img.Image _applySharpenKernel(img.Image image) {
    // Unsharp mask kernel
    final kernel = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0],
    ];

    return _applyConvolution(image, kernel);
  }

  static img.Image _applyConvolution(img.Image image, List<List<int>> kernel) {
    final result = img.Image(width: image.width, height: image.height);
    final kSize = kernel.length;
    final kHalf = kSize ~/ 2;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        var r = 0.0, g = 0.0, b = 0.0;

        for (var ky = 0; ky < kSize; ky++) {
          for (var kx = 0; kx < kSize; kx++) {
            final px = (x + kx - kHalf).clamp(0, image.width - 1);
            final py = (y + ky - kHalf).clamp(0, image.height - 1);
            final pixel = image.getPixel(px, py);
            final weight = kernel[ky][kx];
            r += pixel.r * weight;
            g += pixel.g * weight;
            b += pixel.b * weight;
          }
        }

        result.setPixelRgb(
          x,
          y,
          r.clamp(0, 255).toInt(),
          g.clamp(0, 255).toInt(),
          b.clamp(0, 255).toInt(),
        );
      }
    }

    return result;
  }

  static img.Image _morphologicalErode(img.Image image, int radius) {
    final result = img.Image(width: image.width, height: image.height);
    final gray = img.grayscale(image);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        var minVal = 255;
        for (var dy = -radius; dy <= radius; dy++) {
          for (var dx = -radius; dx <= radius; dx++) {
            final px = (x + dx).clamp(0, image.width - 1);
            final py = (y + dy).clamp(0, image.height - 1);
            final val = gray.getPixel(px, py).r.toInt();
            if (val < minVal) minVal = val;
          }
        }
        final original = image.getPixel(x, y);
        final factor = minVal / 255.0;
        result.setPixelRgb(
          x,
          y,
          (original.r * factor).toInt(),
          (original.g * factor).toInt(),
          (original.b * factor).toInt(),
        );
      }
    }

    return result;
  }

  static img.Image _morphologicalDilate(img.Image image, int radius) {
    final result = img.Image(width: image.width, height: image.height);
    final gray = img.grayscale(image);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        var maxVal = 0;
        for (var dy = -radius; dy <= radius; dy++) {
          for (var dx = -radius; dx <= radius; dx++) {
            final px = (x + dx).clamp(0, image.width - 1);
            final py = (y + dy).clamp(0, image.height - 1);
            final val = gray.getPixel(px, py).r.toInt();
            if (val > maxVal) maxVal = val;
          }
        }
        final original = image.getPixel(x, y);
        final factor = maxVal / 255.0;
        result.setPixelRgb(
          x,
          y,
          (original.r * factor).toInt(),
          (original.g * factor).toInt(),
          (original.b * factor).toInt(),
        );
      }
    }

    return result;
  }

  Future<Uint8List> generateThumbnail(
    String imagePath, {
    int maxWidth = 200,
    int maxHeight = 200,
  }) async {
    return Isolate.run(() async {
      final bytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image for thumbnail');

      image = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodeJpg(image, quality: 80));
    });
  }
}

final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return const ImageProcessingService();
});
