import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'dart:convert';

class JsonQrTab extends StatefulWidget {
  const JsonQrTab({super.key});

  @override
  State<JsonQrTab> createState() => _JsonQrTabState();
}

class _JsonQrTabState extends State<JsonQrTab> {
  List<JsonQrItem> jsonQrItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadJsonFiles();
  }

  Future<void> loadJsonFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final directoryContents = directory.listSync();
      final jsonFiles = directoryContents
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .map((entity) => entity.path.split('/').last)
          .toList();

      List<JsonQrItem> items = [];

      for (String fileName in jsonFiles) {
        try {
          final file = File('${directory.path}/$fileName');
          final jsonString = await file.readAsString();

          // Validate JSON
          json.decode(jsonString);

          items.add(JsonQrItem(fileName: fileName, jsonContent: jsonString));
        } catch (_) {}
      }

      setState(() {
        jsonQrItems = items;
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JSON QR Codes'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              loadJsonFiles();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : jsonQrItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No JSON files found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text('Add JSON files to your documents directory'),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: jsonQrItems.length,
              itemBuilder: (context, index) {
                return JsonQrCard(item: jsonQrItems[index]);
              },
            ),
    );
  }
}

class JsonQrItem {
  final String fileName;
  final String jsonContent;

  const JsonQrItem({required this.fileName, required this.jsonContent});
}

class JsonQrCard extends StatefulWidget {
  final JsonQrItem item;

  const JsonQrCard({super.key, required this.item});

  @override
  State<JsonQrCard> createState() => _JsonQrCardState();
}

class _JsonQrCardState extends State<JsonQrCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.fileName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: widget.item.jsonContent,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ),
            if (isExpanded) ...[
              SizedBox(height: 16),
              Text(
                'JSON Content:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _formatJson(widget.item.jsonContent),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _showQrFullScreen(context),
                  icon: Icon(Icons.fullscreen),
                  label: Text('Full Screen'),
                ),
                TextButton.icon(
                  onPressed: () => _shareQr(context),
                  icon: Icon(Icons.share),
                  label: Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatJson(String jsonString) {
    try {
      final dynamic jsonObject = json.decode(jsonString);
      return JsonEncoder.withIndent('  ').convert(jsonObject);
    } catch (e) {
      return jsonString; // Return original if formatting fails
    }
  }

  void _showQrFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QrFullScreenView(
          fileName: widget.item.fileName,
          jsonContent: widget.item.jsonContent,
        ),
      ),
    );
  }

  void _shareQr(BuildContext context) {
    // You can implement sharing functionality here
    // For example, using the share_plus package
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share QR Code'),
        content: Text(
          'Sharing functionality can be implemented using packages like share_plus or by saving the QR code as an image.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class QrFullScreenView extends StatelessWidget {
  final String fileName;
  final String jsonContent;

  const QrFullScreenView({
    super.key,
    required this.fileName,
    required this.jsonContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: QrImageView(
            data: jsonContent,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.width * 0.8,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
      ),
    );
  }
}
