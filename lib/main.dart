import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SubirFotoPage()),
  );
}

class SubirFotoPage extends StatefulWidget {
  const SubirFotoPage({super.key});

  @override
  State<SubirFotoPage> createState() => _SubirFotoPageState();
}

class _SubirFotoPageState extends State<SubirFotoPage> {
  Uint8List? _bytes;
  String _nombreArchivo = "foto.jpg";
  final TextEditingController _descripcionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _subiendo = false;

  final String apiUrl = kIsWeb
      ? "http://localhost:8000/fotos"
      : "http://10.0.2.2:8000/fotos";

  Future<void> _tomarFoto() async {
    // En web no hay cámara, se abre el selector de archivos
    final XFile? foto = await _picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
    );
    if (foto != null) {
      final bytes = await foto.readAsBytes();
      setState(() {
        _bytes = bytes;
        _nombreArchivo = foto.name;
      });
    }
  }

  Future<void> _subirAApi() async {
    if (_bytes == null || _descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor toma una foto y escribe una descripción"),
        ),
      );
      return;
    }

    setState(() {
      _subiendo = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['descripcion'] = _descripcionController.text.trim();
      request.files.add(
        http.MultipartFile.fromBytes('file', _bytes!, filename: _nombreArchivo),
      );

      var response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto subida correctamente")),
        );
        setState(() {
          _bytes = null;
          _descripcionController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al subir: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _subiendo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subir Foto"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _bytes == null
                ? const Text(
                    "No hay imagen seleccionada",
                    style: TextStyle(fontSize: 16),
                  )
                : Image.memory(_bytes!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _tomarFoto,
              child: Text(kIsWeb ? "Elegir Foto" : "Tomar Foto"),
            ),
            const SizedBox(height: 10),
            _subiendo
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _subirAApi,
                    child: const Text("Subir a API"),
                  ),
          ],
        ),
      ),
    );
  }
}
