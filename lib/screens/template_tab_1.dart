import 'package:flutter/material.dart';
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
        try {
          String result = "";

          // Get basic tag info first
          result += "Tag detected!\n";

          // Get tag identifier - simplified approach
          String tagId = "Tag ID not available";
          result += "$tagId\n";

          // Try NDEF first
          final ndef = Ndef.from(tag);
          if (ndef != null) {
            result += "Tag Type: NDEF Compatible\n";

            try {
              final message = await ndef.read();
              if (message != null && message.records.isNotEmpty) {
                result += "\nNDEF Content:\n";

                for (final record in message.records) {
                  final typeBytes = record.type;
                  final payload = record.payload;
                  final typeString = String.fromCharCodes(typeBytes);

                  if (typeString == 'T') {
                    // Text record
                    if (payload.isNotEmpty) {
                      final statusByte = payload[0];
                      final languageCodeLength = statusByte & 0x3F;
                      if (payload.length > 1 + languageCodeLength) {
                        final textBytes = payload.sublist(1 + languageCodeLength);
                        final text = String.fromCharCodes(textBytes);
                        result += "Text: $text\n";
                      }
                    }
                  } else if (typeString == 'U') {
                    // URI record
                    if (payload.isNotEmpty) {
                      final uriCode = payload[0];
                      final uriBytes = payload.sublist(1);
                      final uri = String.fromCharCodes(uriBytes);
                      String fullUri = _getUriPrefix(uriCode) + uri;
                      result += "URI: $fullUri\n";
                    }
                  } else {
                    // Other record types
                    try {
                      final payloadString = String.fromCharCodes(payload);
                      if (payloadString.isNotEmpty) {
                        result += "Type '$typeString': $payloadString\n";
                      } else {
                        result += "Type '$typeString': [Binary data]\n";
                      }
                    } catch (e) {
                      result += "Type '$typeString': [Binary data]\n";
                    }
                  }
                }

                // Show NDEF metadata
                result += "\nNDEF Info:\n";
                result += "Max Size: ${ndef.maxSize} bytes\n";
                result += "Writable: ${ndef.isWritable}\n";

                // Calculate current size from message
                int currentSize = 0;
                for (final record in message.records) {
                  currentSize += record.payload.length + record.type.length + 3; // approximate overhead
                }
                result += "Estimated Current Size: $currentSize bytes\n";
              } else {
                result += "NDEF tag but no data found\n";
              }
            } catch (e) {
              result += "Error reading NDEF data: $e\n";
            }
          } else {
            result += "Tag Type: Non-NDEF (Raw tag)\n";
            result += "\nThis tag doesn't use the NDEF format.\n";
            result += "It may be:\n";
            result += "- A proprietary format tag\n";
            result += "- An unformatted tag\n";
            result += "- A tag requiring special authentication\n";
            result += "- A MIFARE Classic or other specialized format\n";
          }

          setState(() {
            nfcMessage = result;
            isLoading = false;
          });
          NfcManager.instance.stopSession();

        } catch (e) {
          setState(() {
            nfcMessage = "Error reading tag: $e";
            isLoading = false;
          });
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

String _getUriPrefix(int code) {
  switch (code) {
    case 0x01:
      return 'http://www.';
    case 0x02:
      return 'https://www.';
    case 0x03:
      return 'http://';
    case 0x04:
      return 'https://';
    case 0x05:
      return 'tel:';
    case 0x06:
      return 'mailto:';
    case 0x07:
      return 'ftp://anonymous:anonymous@';
    case 0x08:
      return 'ftp://ftp.';
    case 0x09:
      return 'ftps://';
    case 0x0A:
      return 'sftp://';
    case 0x0B:
      return 'smb://';
    case 0x0C:
      return 'nfs://';
    case 0x0D:
      return 'ftp://';
    case 0x0E:
      return 'dav://';
    case 0x0F:
      return 'news:';
    case 0x10:
      return 'telnet://';
    case 0x11:
      return 'imap:';
    case 0x12:
      return 'rtsp://';
    case 0x13:
      return 'urn:';
    case 0x14:
      return 'pop:';
    case 0x15:
      return 'sip:';
    case 0x16:
      return 'sips:';
    case 0x17:
      return 'tftp:';
    case 0x18:
      return 'btspp://';
    case 0x19:
      return 'btl2cap://';
    case 0x1A:
      return 'btgoep://';
    case 0x1B:
      return 'tcpobex://';
    case 0x1C:
      return 'irdaobex://';
    case 0x1D:
      return 'file://';
    case 0x1E:
      return 'urn:epc:id:';
    case 0x1F:
      return 'urn:epc:tag:';
    case 0x20:
      return 'urn:epc:pat:';
    case 0x21:
      return 'urn:epc:raw:';
    case 0x22:
      return 'urn:epc:';
    case 0x23:
      return 'urn:nfc:';
    default:
      return '';
  }
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
