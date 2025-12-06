import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/inventaris.dart';
import '../services/api_service.dart';

class EditInventarisScreen extends StatefulWidget {
  final Inventaris inventaris;

  const EditInventarisScreen({super.key, required this.inventaris});

  @override
  State<EditInventarisScreen> createState() => _EditInventarisScreenState();
}

class _EditInventarisScreenState extends State<EditInventarisScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _jumlahController;
  late TextEditingController _tanggalController;
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.inventaris.nama);
    _hargaController = TextEditingController(text: widget.inventaris.harga.toString());
    _jumlahController = TextEditingController(text: widget.inventaris.jumlah.toString());
    _tanggalController = TextEditingController(text: widget.inventaris.tanggalMasuk);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.inventaris.tanggalMasuk),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateInventaris() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final inventaris = Inventaris(
          id: widget.inventaris.id,
          nama: _namaController.text,
          harga: int.parse(_hargaController.text),
          jumlah: int.parse(_jumlahController.text),
          tanggalMasuk: _tanggalController.text,
        );

        final result = await _apiService.updateInventaris(
          widget.inventaris.id,
          inventaris,
        );

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inventaris berhasil diupdate'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Gagal mengupdate inventaris'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Edit Inventaris Dhikamart'),
        backgroundColor: Colors.grey[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Komputer',
                          prefixIcon: const Icon(Icons.computer),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hargaController,
                        decoration: InputDecoration(
                          labelText: 'Harga',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga harus diisi';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Harga harus berupa angka';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _jumlahController,
                        decoration: InputDecoration(
                          labelText: 'Jumlah',
                          prefixIcon: const Icon(Icons.inventory),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jumlah harus diisi';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Jumlah harus berupa angka';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tanggalController,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Masuk',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: true,
                        onTap: _selectDate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tanggal masuk harus diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateInventaris,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _jumlahController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }
}