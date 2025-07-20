import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:file_picker/file_picker.dart';

class NfcCardWriteTab extends StatefulWidget {
  const NfcCardWriteTab({super.key});

  @override
  State<NfcCardWriteTab> createState() => _NfcCardWriteTabState();
}

class _NfcCardWriteTabState extends State<NfcCardWriteTab> {
  String statusMessage = 'Select a JSON file to write to NFC card';
  String? fileName;
  Uint8List? jsonData;
  bool isWriting = false;

  Future<void> pickJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsBytes();

      // Validate JSON
      try {
        jsonDecode(utf8.decode(content));
      } catch (e) {
        setState(() {
          statusMessage = 'Invalid JSON file: $e';
        });
        return;
      }

      setState(() {
        fileName = result.files.single.name;
        jsonData = content;
        statusMessage = 'Ready to write: ${result.files.single.name}';
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> writeToNfcCard() async {
    if (jsonData == null) {
      setState(() => statusMessage = 'No JSON file selected');
      return;
    }

    setState(() {
      isWriting = true;
      statusMessage = 'Hold NFC card near device to write...';
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
              statusMessage = 'NFC card is not writable';
              isWriting = false;
            });
            NfcManager.instance.stopSession();
            return;
          }

          try {
            // Create metadata record
            final Map<String, dynamic> metadata = {
              "source": "phone",
              "payloadType": "single",
              "version": 1,
              "fileName": fileName,
            };

            final Uint8List metaPayload = Uint8List.fromList(
              utf8.encode(jsonEncode(metadata)),
            );

            final metaRecord = NdefRecord(
              type: Uint8List.fromList('application/json'.codeUnits),
              payload: metaPayload,
              typeNameFormat: TypeNameFormat.media,
              identifier: Uint8List.fromList('meta'.codeUnits),
            );

            // Create JSON data record
            final dataRecord = NdefRecord(
              type: Uint8List.fromList('application/json'.codeUnits),
              payload: jsonData!,
              typeNameFormat: TypeNameFormat.media,
              identifier: Uint8List.fromList('data'.codeUnits),
            );

            final message = NdefMessage(records: [metaRecord, dataRecord]);

            await ndef.write(message: message);
            setState(() {
              statusMessage = 'Successfully wrote $fileName to NFC card!';
              isWriting = false;
            });
          } catch (e) {
            setState(() {
              statusMessage = 'Error writing to card: $e';
              isWriting = false;
            });
          }

          NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      setState(() {
        statusMessage = 'NFC error: $e';
        isWriting = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      fileName = null;
      jsonData = null;
      statusMessage = 'Select a JSON file to write to NFC card';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: pickJsonFile,
            child: const Text('Select JSON File'),
          ),
          const SizedBox(height: 20),
          if (fileName != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Selected file:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Size: ${(jsonData!.length / 1024).toStringAsFixed(1)} KB',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isWriting ? null : writeToNfcCard,
            child: isWriting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Writing...'),
                    ],
                  )
                : const Text('Write to NFC Card'),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusMessage,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          if (fileName != null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: _clearSelection,
              child: const Text('Clear Selection'),
            ),
          ],
        ],
      ),
    );
  }
}
