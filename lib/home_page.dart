import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String location = "Carregando localização...";
  File? image;
  String horario = "";

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  // 🔐 Pede permissões ao entrar no app
  Future<void> pedirPermissoes() async {
    await Permission.location.request();
    await Permission.camera.request();
  }

  // 🚀 Inicialização geral
  Future<void> _inicializarApp() async {
    await pedirPermissoes();
    await getLocation();
  }

  // 📍 GPS
  Future<void> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        location = "Serviço de localização desativado";
      });
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          location = "Permissão de localização negada";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        location = "Permissão negada permanentemente";
      });
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      location = "Lat: ${pos.latitude}, Lng: ${pos.longitude}";
    });
  }

  // 📸 Câmera
  Future<void> tirarFoto() async {
    var status = await Permission.camera.request();

    if (!status.isGranted) {
      await openAppSettings();
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    if (picked != null) {
      setState(() {
        image = File(picked.path);
        horario = TimeOfDay.now().format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro de Entrada"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 📍 localização
            Text(
              location,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 📸 botão câmera
            ElevatedButton(
              onPressed: tirarFoto,
              child: const Text("Registrar Entrada"),
            ),

            const SizedBox(height: 20),

            // 🖼️ imagem
            if (image != null)
              Image.file(image!, height: 200),

            const SizedBox(height: 10),

            // ⏰ horário
            if (horario.isNotEmpty)
              Text(
                "Horário: $horario",
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}