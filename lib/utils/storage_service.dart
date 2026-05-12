import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static Future<String> uploadPostImage(String folder, File image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child(folder)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (kIsWeb) {
        // 웹 환경: 바이트 데이터로 업로드
        final bytes = await image.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        // 모바일 환경
        await ref.putFile(image);
      }
      return await ref.getDownloadURL();
    } catch (e) {
      print("StorageService 에러: $e");
      rethrow; // 에러를 위로 던져서 _submit의 catch에서 잡히게 함
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } catch (e) {
      print('이미지 삭제 실패: $e');
    }
  }
}
