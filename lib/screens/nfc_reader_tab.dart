import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_app/models/user_details.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'enter_data_tab.dart';

class NfcQrScannerScreen extends StatefulWidget {
  const NfcQrScannerScreen({super.key});

  @override
  State<NfcQrScannerScreen> createState() => _NfcQrScannerScreenState();
}

class _NfcQrScannerScreenState extends State<NfcQrScannerScreen>
    with SingleTickerProviderStateMixin {
  String scanMessage = "Choose scan method to read data";
  bool isLoading = false;
  late TabController _tabController;
  MobileScannerController? qrController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    qrController?.dispose();
    super.dispose();
  }

  // NFC Methods (existing functionality)
  Future<void> readNfcTag() async {
    setState(() {
      isLoading = true;
      scanMessage = "Hold your phone near an NFC tag...";
    });

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        setState(() {
          scanMessage = "NFC not supported on this device";
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
              scanMessage = message;
              isLoading = false;
            });
          } catch (e) {
            setState(() {
              scanMessage = "Error reading tag: $e";
              isLoading = false;
            });
          } finally {
            NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      setState(() {
        scanMessage = "Failed to start NFC session: $e";
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

    final userFromNfc = UserDetails.fromJson(data);


    return 'Received data from NFC ${metadata?['source'] ?? "card"}:\n'
        '${const JsonEncoder.withIndent('  ').convert(data)}';
  }

  // QR Code Methods
  void _onQrDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final String? code = barcode.rawValue;

      if (code != null) {
        qrController?.stop();
        _handleQrData(code);
      }
    }
  }

  void _handleQrData(String data) {
    setState(() {
      scanMessage = _processQrData(data);
      isLoading = false;
    });
  }

  String _processQrData(String data) {
    try {
      // Try to parse as JSON
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return 'Received data from QR code:\n'
            '${const JsonEncoder.withIndent('  ').convert(decoded)}';
      } else {
        return 'QR Code data (non-JSON):\n$data';
      }
    } catch (e) {
      // Not JSON, return as plain text
      return 'QR Code data:\n$data';
    }
  }

  void _startQrScanning() {
    setState(() {
      isLoading = true;
      scanMessage = "Point camera at QR code...";
    });

    qrController?.start();
  }

  void _stopQrScanning() {
    setState(() {
      isLoading = false;
      scanMessage = "Choose scan method to read data";
    });

    qrController?.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NFC & QR Scanner"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.nfc), text: "NFC"),
            Tab(icon: Icon(Icons.qr_code), text: "QR Code"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // NFC Tab
          _buildNfcTab(),
          // QR Code Tab
          _buildQrTab(),
        ],
      ),
    );
  }

  Widget _buildNfcTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nfc,
            size: 64,
            color: isLoading ? Colors.blue : Colors.grey,
          ),
          const SizedBox(height: 20),
          if (isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton.icon(
              onPressed: readNfcTag,
              icon: const Icon(Icons.nfc),
              label: const Text("Scan NFC Tag"),
            ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  scanMessage,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrTab() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            child: qrController == null
                ? _buildQrInitialView()
                : MobileScanner(
                    controller: qrController!,
                    onDetect: _onQrDetected,
                  ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: qrController == null ? _initializeQrScanner : _startQrScanning,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(qrController == null ? "Initialize Camera" : "Start Scan"),
                    ),
                    if (qrController != null)
                      ElevatedButton.icon(
                        onPressed: _stopQrScanning,
                        icon: const Icon(Icons.stop),
                        label: const Text("Stop"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        scanMessage,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            "Initialize camera to start QR scanning",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _initializeQrScanner() {
    setState(() {
      qrController = MobileScannerController();
      scanMessage = "Camera initialized. Tap 'Start Scan' to begin.";
    });
  }
}