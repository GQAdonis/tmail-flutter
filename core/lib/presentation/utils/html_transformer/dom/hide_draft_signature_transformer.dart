import 'package:core/data/network/dio_client.dart';
import 'package:core/presentation/utils/html_transformer/base/dom_transformer.dart';
import 'package:html/dom.dart';

class HideDraftSignatureTransformer extends DomTransformer {

  const HideDraftSignatureTransformer();

  @override
  Future<void> process({
    required Document document,
    required DioClient dioClient,
    Map<String, String>? mapUrlDownloadCID
  }) async {
    final signature = document.querySelector('div.tmail-signature');
    if (signature == null) return;
    final currentStyle = signature.attributes['style']?.trim();
    if (currentStyle == null) {
      signature.attributes['style'] = 'display: none;';
    } else if (currentStyle.endsWith(';')) {
      signature.attributes['style'] = '$currentStyle display: none;';
    } else {
      signature.attributes['style'] = '$currentStyle; display: none;';
    }
  }
}