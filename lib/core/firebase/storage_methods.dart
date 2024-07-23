import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageMethods {
  var myId = "";
  StorageMethods();
  FirebaseStorage storage = FirebaseStorage.instance;
  Reference getStorageRef(List<String> path) {
    return storage.ref(path.join("/"));
  }

  Future<void> deleteFile(List<String> path) async {
    try {
      final ref = getStorageRef(path);
      await ref.delete();
    } on Exception catch (e) {}
  }

  Future<void> uploadFile(List<String> path, String filePath, String mediaType,
      {void Function(String url, String thumbnail)? onComplete,
      void Function()? onError,
      void Function(double)? onProgress}) async {
    try {
      String time = DateTime.now().millisecondsSinceEpoch.toString();
      final ext = mediaType == "photo"
          ? ".jpg"
          : mediaType == "video"
              ? ".mp4"
              : mediaType == "audio"
                  ? ".mp3"
                  : "";
      List<String> thumbPath = [];
      thumbPath.addAll(path);
      path.add("$time$ext");
      thumbPath.add("${time}_thumb.jpg");

      File file = File(filePath);
      final exist = await file.exists();
      if (!exist) return;
      // Uint8List? thumbFile;
      // if (mediaType == "photo") {
      //   thumbFile =
      //       await FlutterImageCompress.compressWithFile(filePath, quality: 30);
      // } else if (mediaType == "video") {
      //   thumbFile =
      //       await VideoCompress.getByteThumbnail(filePath, quality: 30);
      // }
      String thumbnail = "";
      // if (thumbFile != null) {
      //   final thumbUploadTask = getStorageRef(thumbPath).putData(thumbFile);
      //   final thumbtaskSnapshot = await thumbUploadTask;
      //   thumbnail = await thumbtaskSnapshot.ref.getDownloadURL();
      // }

      final uploadTask = getStorageRef(path).putFile(file);
      final taskSnapshot = await uploadTask;
      final url = await taskSnapshot.ref.getDownloadURL();
      if (onComplete != null) onComplete(url, thumbnail);
    } on Exception catch (e) {}
  }
}
