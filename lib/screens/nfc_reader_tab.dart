import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcReaderScreen extends StatefulWidget {
  const NfcReaderScreen({super.key});

  @override
  State<NfcReaderScreen> createState() => _NfcReaderScreenState();
}

class _NfcReaderScreenState extends State<NfcReaderScreen> {
  String nfcMessage = "Tap an NFC tag to read it";
  bool isLoading = false;

  Future<void> readNfcTag() async {
    setState(() {
      isLoading = true;
      nfcMessage = "Hold your phone near an NFC tag...";
    });

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        setState(() {
          nfcMessage = "NFC not supported on this device";
          isLoading = false;
        });
        return;
      }

      NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          setState(() {
            isLoading = true;
          });

          try {
            final message = await handleNfcTag(tag);
            setState(() {
              nfcMessage = message;
              isLoading = false;
            });
          } catch (e) {
            setState(() {
              nfcMessage = "Error reading tag: $e";
              isLoading = false;
            });
          } finally {
            NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      setState(() {
        nfcMessage = "Failed to start NFC session: $e";
        isLoading = false;
      });
    }
  }

  Future<NdefMessage?> readNdefMessage(Ndef ndef) async {
    final message = await ndef.read();
    if (message == null || message.records.isEmpty) {
      return null;
    }
    return message;
  }

  Map<String, dynamic>? tryParseMetadata(NdefRecord record) {
    try {
      final payloadString = utf8.decode(record.payload);
      final decoded = jsonDecode(payloadString);
      if (decoded is Map && decoded.containsKey('source')) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Parsing failed, return null
    }
    return null;
  }

  Map<String, dynamic>? tryParseData(NdefRecord record) {
    try {
      final payloadString = utf8.decode(record.payload);
      final decoded = jsonDecode(payloadString);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<String> handleNfcTag(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      return 'NDEF not supported on this tag';
    }

    final message = await readNdefMessage(ndef);
    if (message == null) {
      return 'No NDEF records found';
    }

    final records = message.records;
    Map<String, dynamic>? metadata = tryParseMetadata(records.first);
    Map<String, dynamic>? data;

    if (metadata != null && records.length > 1) {
      data = tryParseData(records[1]);
      if (data == null) return 'Error parsing JSON data record';
    } else {
      data = tryParseData(records.first);
      if (data == null) return 'Error parsing JSON from tag';
    }

    return 'Received data from ${metadata?['source'] ?? "card"}:\n'
        '${const JsonEncoder.withIndent('  ').convert(data)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NFC Reader")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: readNfcTag,
                child: const Text("Scan NFC Tag"),
              ),
            const SizedBox(height: 20),
            Text(nfcMessage),
          ],
        ),
      ),
    );
  }
}
