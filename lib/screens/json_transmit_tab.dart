import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:file_picker/file_picker.dart';

class JsonTransmitTab extends StatefulWidget {
  const JsonTransmitTab({super.key});

  @override
  State<JsonTransmitTab> createState() => _JsonTransmitTabState();
}

class _JsonTransmitTabState extends State<JsonTransmitTab> {
  String statusMessage = 'Select a JSON file to transmit';
  String? fileName;
  Uint8List? jsonData;
  bool isTransmitting = false;

  Future<void> pickJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsBytes();

      setState(() {
        fileName = result.files.single.name;
        jsonData = content;
        statusMessage = 'Ready to transmit: ${result.files.single.name}';
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> transmitJsonViaNfc() async {
    if (jsonData == null) {
      setState(() => statusMessage = 'No JSON file selected');
      return;
    }

    setState(() {
      isTransmitting = true;
      statusMessage = 'Hold device near NFC tag to transmit...';
    });

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (tag) async {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            setState(() {
              statusMessage = 'Tag is not writable';
              isTransmitting = false;
            });
            NfcManager.instance.stopSession();
            return;
          }

          final Map<String, dynamic> metadata = {
            "source": "phone",
            "payloadType": "single", // or "multipart" if chunking
            "version": 1,
          };

          // Encode metadata JSON string into bytes
          final Uint8List metaPayload = Uint8List.fromList(
            utf8.encode(jsonEncode(metadata)),
          );

          final metaRecord = NdefRecord(
            type: Uint8List.fromList('application/json'.codeUnits),
            payload: metaPayload,
            typeNameFormat: TypeNameFormat.media,
            identifier: Uint8List(0),
          );

          // Create NDEF record with MIME type application/json
          final dataRecord = NdefRecord(
            type: Uint8List.fromList('application/json'.codeUnits),
            payload: jsonData!,
            typeNameFormat: TypeNameFormat.media,
            identifier: Uint8List(0),
          );

          final message = NdefMessage(records: [metaRecord, dataRecord]);

          try {
            await ndef.write(message: message);
            setState(() {
              statusMessage = 'Successfully transmitted $fileName!';
              isTransmitting = false;
            });
          } catch (e) {
            setState(() {
              statusMessage = 'Error writing to tag: $e';
              isTransmitting = false;
            });
          }

          NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      setState(() {
        statusMessage = 'NFC error: $e';
        isTransmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: pickJsonFile,
            child: const Text('Select JSON File'),
          ),
          const SizedBox(height: 20),
          if (fileName != null) Text('Selected file: $fileName'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isTransmitting ? null : transmitJsonViaNfc,
            child: isTransmitting
                ? const CircularProgressIndicator()
                : const Text('Transmit via NFC'),
          ),
          const SizedBox(height: 20),
          Text(
            statusMessage,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
