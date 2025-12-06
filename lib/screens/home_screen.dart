import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventaris.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'add_inventaris_screen.dart';
import 'edit_inventaris_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  List<Inventaris> _inventarisList = [];
  bool _isLoading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadInventaris();
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getUserName();
    setState(() {
      _userName = name ?? 'User';
    });
  }

  Future<void> _loadInventaris() async {
    setState(() => _isLoading = true);
    try {
      final inventaris = await _apiService.getInventaris();
      setState(() {
        _inventarisList = inventaris;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _deleteInventaris(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteInventaris(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inventaris berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadInventaris();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus inventaris'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Inventaris Komputer Dhikamart'),
        backgroundColor: Colors.grey[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInventaris,
              child: _inventarisList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada inventaris',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _inventarisList.length,
                      itemBuilder: (context, index) {
                        final item = _inventarisList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.computer,
                                color: Colors.grey[700],
                              ),
                            ),
                            title: Text(
                              item.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  'Harga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.harga)}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'Jumlah: ${item.jumlah} unit',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'Tanggal Masuk: ${item.tanggalMasuk}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditInventarisScreen(inventaris: item),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadInventaris();
                                  }
                                } else if (value == 'delete') {
                                  _deleteInventaris(item.id);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInventarisScreen()),
          );
          if (result == true) {
            _loadInventaris();
          }
        },
        backgroundColor: Colors.grey[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}