import 'dart:io';
import 'analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final void Function(OFPAnalysisData data)? onAnalysisReady;
  const HomeScreen({super.key, this.onAnalysisReady});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---- stato ----
  String? _fileName;
  bool _isLoading = false;
  String? _errorMessage;
  bool _fileLoaded = false;
  File? _selectedFile; // <-- unica variabile, usata ovunque

  // ---- colori ----
  static const _bgColor = Color(0xFFF2F4F7);
  static const _cardColor = Colors.white;
  static const _borderColor = Color(0xFF3B6FD4);
  static const _accentColor = Color(0xFF3B6FD4);
  static const _textPrimary = Color(0xFF1A1D23);
  static const _textSecondary = Color(0xFF6B7280);

  // ---- selezione file ----
  Future<void> _pickPdf() async {
    setState(() => _errorMessage = null);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() {
      _selectedFile = File(result.files.single.path!);
      _fileName = result.files.single.name;
      _fileLoaded = true;
      _errorMessage = null;
    });
  }

  // ---- analisi PDF ----
  Future<void> _analyzePdf() async {
    if (_selectedFile == null) {
      // <-- usa _selectedFile
      setState(() => _errorMessage = 'Seleziona prima un file PDF.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uploadResponse = await ApiService.uploadPdf(_selectedFile!);
      debugPrint(
        'PDF uploaded to server: ${uploadResponse.filename} '
        '(${uploadResponse.sizeBytes} bytes)',
      );

      if (mounted) {
        final analysisData = uploadResponse.analysisData;
        if (analysisData == null) {
          throw const ApiException(
            'Server response does not contain parsed OFP data.',
          );
        }

        widget.onAnalysisReady?.call(analysisData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF parsed:\n${uploadResponse.filename}'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Errore durante upload PDF: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- reset ----
  void _resetFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileLoaded = false;
      _errorMessage = null;
    });
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildCard(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildError(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OFP Analysis',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Upload a flight plan to calculate recommended extra fuel',
          style: TextStyle(fontSize: 14, color: _textSecondary),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDropZone(),
          const SizedBox(height: 24),
          _buildAnalyzeButton(),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickPdf,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 220),
        decoration: BoxDecoration(
          color: _fileLoaded
              ? _accentColor.withOpacity(0.04)
              : Colors.transparent,
          border: Border.all(
            color: _fileLoaded ? _accentColor : _borderColor.withOpacity(0.4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _fileLoaded ? _buildFilePreview() : _buildEmptyZone(),
      ),
    );
  }

  Widget _buildEmptyZone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.upload_rounded,
            size: 28,
            color: _accentColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Drop your OFP PDF here',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'or click to browse files',
          style: TextStyle(fontSize: 13, color: _textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          'Supports OFP formats from Lido, SITA, and Jeppesen',
          style: TextStyle(
            fontSize: 12,
            color: _textSecondary.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFilePreview() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: _accentColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'PDF pronto per l\'analisi',
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _resetFile,
            icon: const Icon(Icons.close_rounded, color: _textSecondary),
            tooltip: 'Rimuovi file',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: (_isLoading || !_fileLoaded) ? null : _analyzePdf,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.analytics_rounded, size: 20),
        label: Text(
          _isLoading ? 'Analisi in corso...' : 'Analyze OFP',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentColor.withOpacity(0.4),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
