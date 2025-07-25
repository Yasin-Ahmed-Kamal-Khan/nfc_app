import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:path_provider/path_provider.dart';

class JsonTransmitTab extends StatefulWidget {
  const JsonTransmitTab({super.key});

  @override
  State<JsonTransmitTab> createState() => _JsonTransmitTabState();
}

class _JsonTransmitTabState extends State<JsonTransmitTab> {
  String statusMessage = 'Select a Medical Record to transmit';
  String? fileName;
  Uint8List? jsonData;
  bool isTransmitting = false;
  List<String> availableJsonFiles = [];
  bool isLoadingFiles = false;
  String? jsonPreview; // <-- Add this field

  @override
  void initState() {
    super.initState();
    _loadJsonFiles();
  }

  Future<void> _loadJsonFiles() async {
    setState(() {
      isLoadingFiles = true;
      statusMessage = 'Loading JSON files...';
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final directoryContents = directory.listSync();

      final jsonFiles = directoryContents
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .map((entity) => entity.path.split('/').last)
          .toList();

      setState(() {
        availableJsonFiles = jsonFiles;
        isLoadingFiles = false;
        if (jsonFiles.isEmpty) {
          statusMessage = 'No JSON files found in app directory';
        } else {
          statusMessage = 'Select a Medical Record to transmit';
        }
      });
    } catch (e) {
      setState(() {
        isLoadingFiles = false;
        statusMessage = 'Error loading files: $e';
      });
    }
  }

  Future<void> selectJsonFile(String selectedFileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$selectedFileName');

      if (!await file.exists()) {
        setState(() {
          statusMessage = 'File no longer exists';
          jsonPreview = null; // <-- Update here
        });
        _loadJsonFiles(); // Refresh the list
        return;
      }

      final content = await file.readAsBytes();

      // Validate JSON
      try {
        final decoded = jsonDecode(utf8.decode(content));
        setState(() {
          fileName = selectedFileName;
          jsonData = content;
          statusMessage = 'Ready to transmit: $selectedFileName';
          jsonPreview = const JsonEncoder.withIndent('  ').convert(decoded);
        });
      } catch (e) {
        setState(() {
          statusMessage = 'Invalid JSON file: $e';
          jsonPreview = null; // <-- Update here
        });
        return;
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Error reading file: $e';
        jsonPreview = null; // <-- Update here
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

          if (ndef.maxSize <= 0 || ndef.maxSize >= jsonData!.length) {
            print("${ndef.maxSize} it fell here");
            await transmitJsonToPhone(ndef);
          } else {
            print("${ndef.maxSize} it fell here instead");
            await transmitJsonToNfcTag(ndef);
          }
        },
      );
    } catch (e) {
      setState(() {
        statusMessage = 'NFC error: $e';
        isTransmitting = false;
      });
    }
  }

  Future<void> transmitJsonToPhone(Ndef ndef) async {
    final Map<String, dynamic> metadata = {
      "source": "phone",
      "payloadType": "single",
      "version": 1,
    };

    final Uint8List metaPayload = Uint8List.fromList(
      utf8.encode(jsonEncode(metadata)),
    );

    final metaRecord = NdefRecord(
      type: Uint8List.fromList('application/json'.codeUnits),
      payload: metaPayload,
      typeNameFormat: TypeNameFormat.media,
      identifier: Uint8List(0),
    );

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
  }

  Future<void> transmitJsonToNfcTag(Ndef ndef) async {
    final Map<String, dynamic> metadata = {
      "source": "tag",
      "payloadType": "single",
      "version": 1,
    };

    final Uint8List metaPayload = Uint8List.fromList(
      utf8.encode(jsonEncode(metadata)),
    );

    final metaRecord = NdefRecord(
      type: Uint8List.fromList('application/json'.codeUnits),
      payload: metaPayload,
      typeNameFormat: TypeNameFormat.media,
      identifier: Uint8List(0),
    );

    final originalMap =
        jsonDecode(utf8.decode(jsonData!)) as Map<String, dynamic>;
    final limitedMap = <String, dynamic>{};

    for (final entry in originalMap.entries) {
      final testMap = {...limitedMap, entry.key: entry.value};
      final testPayload = Uint8List.fromList(utf8.encode(jsonEncode(testMap)));
      final dataRecord = NdefRecord(
        type: Uint8List.fromList('application/json'.codeUnits),
        payload: testPayload,
        typeNameFormat: TypeNameFormat.media,
        identifier: Uint8List(0),
      );

      final totalSize = metaRecord.byteLength + dataRecord.byteLength;
      if (totalSize > ndef.maxSize) break;

      limitedMap[entry.key] = entry.value;
    }

    final dataPayload = Uint8List.fromList(utf8.encode(jsonEncode(limitedMap)));

    final dataRecord = NdefRecord(
      type: Uint8List.fromList('application/json'.codeUnits),
      payload: dataPayload,
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
  }

  void _clearSelection() {
    setState(() {
      fileName = null;
      jsonData = null;
      jsonPreview = null; // <-- Clear preview
      statusMessage = availableJsonFiles.isEmpty
          ? 'No JSON files found in app directory'
          : 'Select a Medical Record to transmit';
    });
  }

  Future<void> _deleteJsonFile(String fileToDelete) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileToDelete');
    if (await file.exists()) {
      await file.delete();
    }
    // If the deleted file was selected, clear selection
    if (fileName == fileToDelete) {
      _clearSelection();
    }
    await _loadJsonFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Medical Records',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: isLoadingFiles ? null : _loadJsonFiles,
                icon: isLoadingFiles
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh file list',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // File list
          if (isLoadingFiles)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (availableJsonFiles.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No JSON files found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JSON files saved by the app will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Expanded(
              child:
                  fileName ==
                      null // <-- Only show the box if no file is selected
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: availableJsonFiles.length,
                        itemBuilder: (context, index) {
                          final file = availableJsonFiles[index];
                          final isSelected = fileName == file;

                          return ListTile(
                            leading: Icon(
                              Icons.description,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            title: Text(
                              file,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : null,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete file',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete JSON File'),
                                        content: Text(
                                          'Are you sure you want to delete "$file"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _deleteJsonFile(file);
                                    }
                                  },
                                ),
                              ],
                            ),
                            selected: isSelected,
                            onTap: () => selectJsonFile(file),
                          );
                        },
                      ),
                    )
                  : ListView.builder(
                      itemCount: availableJsonFiles.length,
                      itemBuilder: (context, index) {
                        final file = availableJsonFiles[index];
                        final isSelected = fileName == file;

                        return ListTile(
                          leading: Icon(
                            Icons.description,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(
                            file,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : null,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Delete file',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete JSON File'),
                                      content: Text(
                                        'Are you sure you want to delete "$file"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _deleteJsonFile(file);
                                  }
                                },
                              ),
                            ],
                          ),
                          selected: isSelected,
                          onTap: () => selectJsonFile(file),
                        );
                      },
                    ),
            ),

          const SizedBox(height: 20),

          // Selected file info
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
                  if (jsonData != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Size: ${(jsonData!.length / 1024).toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),

          // JSON preview
          if (jsonPreview != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonPreview!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Transmit button
          ElevatedButton(
            onPressed: isTransmitting ? null : transmitJsonViaNfc,
            child: isTransmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Transmitting...'),
                    ],
                  )
                : const Text('Transmit via NFC'),
          ),

          const SizedBox(height: 20),

          // Status message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusMessage,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),

          // Clear selection button
          if (fileName != null) ...[
            const SizedBox(height: 16),
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
