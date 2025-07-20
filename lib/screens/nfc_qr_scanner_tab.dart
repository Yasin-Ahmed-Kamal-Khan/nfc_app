import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_app/models/user_details.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

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
  Map<String, dynamic>? scannedData;
  String? dataSource;

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

  // Helper method to filter out empty/null values
  Map<String, dynamic> _filterEmptyValues(Map<String, dynamic> data) {
    final filtered = <String, dynamic>{};

    for (final entry in data.entries) {
      final value = entry.value;

      // Skip null, empty strings, and "None" values
      if (value == null ||
          (value is String && (value.isEmpty || value.toLowerCase() == 'none')) ||
          (value is List && value.isEmpty) ||
          (value is Map && value.isEmpty)) {
        continue;
      }

      // Recursively filter nested maps
      if (value is Map<String, dynamic>) {
        final filteredNested = _filterEmptyValues(value);
        if (filteredNested.isNotEmpty) {
          filtered[entry.key] = filteredNested;
        }
      } else {
        filtered[entry.key] = value;
      }
    }

    return filtered;
  }

  // NFC Methods (existing functionality)
  Future<void> readNfcTag() async {
    setState(() {
      isLoading = true;
      scanMessage = "Hold your phone near an NFC tag...";
      scannedData = null;
      dataSource = null;
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
            await handleNfcTag(tag);
          } catch (e) {
            setState(() {
              scanMessage = "Error reading tag: $e";
              isLoading = false;
              scannedData = null;
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
        scannedData = null;
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

  Future<void> handleNfcTag(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      setState(() {
        scanMessage = 'NDEF not supported on this tag';
        isLoading = false;
        scannedData = null;
      });
      return;
    }

    final message = await readNdefMessage(ndef);
    if (message == null) {
      setState(() {
        scanMessage = 'No NDEF records found';
        isLoading = false;
        scannedData = null;
      });
      return;
    }

    final records = message.records;
    Map<String, dynamic>? metadata = tryParseMetadata(records.first);
    Map<String, dynamic>? data;

    if (metadata != null && records.length > 1) {
      data = tryParseData(records[1]);
      if (data == null) {
        setState(() {
          scanMessage = 'Error parsing JSON data record';
          isLoading = false;
          scannedData = null;
        });
        return;
      }
    } else {
      data = tryParseData(records.first);
      if (data == null) {
        setState(() {
          scanMessage = 'Error parsing JSON from tag';
          isLoading = false;
          scannedData = null;
        });
        return;
      }
    }

    final userFromNfc = UserDetails.fromJson(data);
    final filteredData = _filterEmptyValues(data);

    setState(() {
      scannedData = filteredData;
      dataSource = 'NFC ${metadata?['source'] ?? "card"}';
      scanMessage = "Data successfully scanned!";
      isLoading = false;
    });
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
      isLoading = false;
    });

    try {
      // Try to parse as JSON
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        final filteredData = _filterEmptyValues(Map<String, dynamic>.from(decoded));
        setState(() {
          scannedData = filteredData;
          dataSource = 'QR Code';
          scanMessage = "Data successfully scanned!";
        });
      } else {
        setState(() {
          scanMessage = 'QR Code data (non-JSON):\n$data';
          scannedData = null;
          dataSource = null;
        });
      }
    } catch (e) {
      // Not JSON, return as plain text
      setState(() {
        scanMessage = 'QR Code data:\n$data';
        scannedData = null;
        dataSource = null;
      });
    }
  }

  void _startQrScanning() {
    setState(() {
      isLoading = true;
      scanMessage = "Point camera at QR code...";
      scannedData = null;
      dataSource = null;
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
    if (scannedData != null && _tabController.index == 0) {
      return _buildDataDisplayView();
    }

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
    if (scannedData != null && _tabController.index == 1) {
      return _buildDataDisplayView();
    }

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

  Widget _buildDataDisplayView() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Scanned from $dataSource',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    scannedData = null;
                    dataSource = null;
                    scanMessage = "Choose scan method to read data";
                  });
                },
                tooltip: 'Scan Again',
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (scannedData != null) ..._buildDataCards(scannedData!),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataCards(Map<String, dynamic> data) {
    final widgets = <Widget>[];

    data.forEach((key, value) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatKey(key),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _getIconForKey(key),
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildValueWidget(value),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });

    return widgets;
  }

  Widget _buildValueWidget(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '${_formatKey(entry.key)}:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      return Text(
        value.toString(),
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  String _formatKey(String key) {
    // Convert snake_case and camelCase to Title Case
    return key
        .replaceAllMapped(RegExp(r'[_]([a-z])'), (match) => ' ${match.group(1)!.toUpperCase()}')
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  IconData _getIconForKey(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('name')) return Icons.person;
    if (lowerKey.contains('email')) return Icons.email;
    if (lowerKey.contains('phone')) return Icons.phone;
    if (lowerKey.contains('address')) return Icons.location_on;
    if (lowerKey.contains('id') || lowerKey.contains('number')) return Icons.tag;
    if (lowerKey.contains('date') || lowerKey.contains('time')) return Icons.calendar_today;
    if (lowerKey.contains('company') || lowerKey.contains('organization')) return Icons.business;
    if (lowerKey.contains('url') || lowerKey.contains('website')) return Icons.link;
    return Icons.info;
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