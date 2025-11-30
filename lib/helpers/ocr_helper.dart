import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrHelper {
  static Future<String?> scanTextFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo == null) return null;

      final InputImage inputImage = InputImage.fromFilePath(photo.path);
      final TextRecognizer textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String text = recognizedText.text;
      
      await textRecognizer.close();

      return text;
    } catch (e) {
      print('Erro no OCR: $e');
      return null;
    }
  }
}
