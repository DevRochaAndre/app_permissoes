import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String location = "Carregando localização...";
  File? image;
  String horario = "";

  // 🔵 Lista de dispositivos Bluetooth
  List<ScanResult> devices = [];

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  // 🔐 Pede permissões
  Future<void> pedirPermissoes() async {
    await Permission.location.request();
    await Permission.camera.request();

    // Bluetooth Android 12+
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  // 🚀 Inicialização
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

  // 📸 Tirar foto
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

  // 🔵 Buscar dispositivos Bluetooth
  Future<void> scanBluetooth() async {
    devices.clear();

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 4),
    );

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        devices = results;
      });
    });
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
            // 📍 Localização
            Text(
              location,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 📸 Botão câmera
            ElevatedButton(
              onPressed: tirarFoto,
              child: const Text("Registrar Entrada"),
            ),

            const SizedBox(height: 20),

            // 🔵 Botão Bluetooth
            ElevatedButton(
              onPressed: scanBluetooth,
              child: const Text("Buscar dispositivos Bluetooth"),
            ),

            const SizedBox(height: 20),

            // 🖼️ Imagem
            if (image != null)
              Image.file(
                image!,
                height: 200,
              ),

            const SizedBox(height: 10),

            // ⏰ Horário
            if (horario.isNotEmpty)
              Text(
                "Horário: $horario",
                style: const TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 20),

            // 🔵 Lista Bluetooth
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index].device;

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(
                        device.platformName.isNotEmpty
                            ? device.platformName
                            : "Dispositivo desconhecido",
                      ),
                      subtitle: Text(
                        device.remoteId.toString(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}