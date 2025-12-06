# Responsi 2 Mobile Paket 1 (H1D023089)

## Aplikasi Inventaris Komputer Dhikamart

- **Nama**: Andhika Putra Restu Ilahi
- **NIM**: H1D023089
- **Shift Baru**: Shift A
- **Shift Asal**: Shift F

## Demo Aplikasi

https://github.com/user-attachments/assets/5846be4f-ea63-46d9-be3d-1920f642920c

---

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Laravel 12 REST API
- **Authentication**: Laravel Sanctum (Bearer Token)
- **Storage Lokal**: SharedPreferences
- **HTTP Client**: package `http`

---

## Spesifikasi API Backend (Laravel 12)

### Base Configuration

- **Base URL**: `http://127.0.0.1:8000`
- **API Prefix**: `/api`
- **Authentication**: Bearer Token (Sanctum)
- **Headers**:
  ```
  Content-Type: application/json
  Accept: application/json
  Authorization: Bearer <token>  // untuk endpoint terproteksi
  ```

### Endpoints

| Method | Endpoint               | Auth | Deskripsi              |
| ------ | ---------------------- | ---- | ---------------------- |
| POST   | `/api/register`        | ❌   | Registrasi user baru   |
| POST   | `/api/login`           | ❌   | Login & dapatkan token |
| POST   | `/api/logout`          | ✅   | Logout & revoke token  |
| GET    | `/api/inventaris`      | ✅   | Ambil list inventaris  |
| POST   | `/api/inventaris`      | ✅   | Tambah inventaris baru |
| GET    | `/api/inventaris/{id}` | ✅   | Detail inventaris      |
| PUT    | `/api/inventaris/{id}` | ✅   | Update inventaris      |
| DELETE | `/api/inventaris/{id}` | ✅   | Hapus inventaris       |


---

## Cara Menjalankan Aplikasi

### Backend (Laravel 12)

```bash
# Pastikan .env sudah dikonfigurasi
php artisan serve
```

### Frontend (Flutter)

```bash
# Install dependencies
flutter pub get

# Sesuaikan baseUrl di lib/services/api_service.dart

# Run aplikasi
flutter run
```

---

## Struktur Aplikasi

```
lib/
├── main.dart                          # Entry point & splash screen
├── models/
│   ├── inventaris.dart               # Model data inventaris
│   └── user.dart                     # Model data user
├── screens/
│   ├── login_screen.dart             # Halaman login
│   ├── register_screen.dart          # Halaman registrasi
│   ├── home_screen.dart              # Halaman daftar inventaris
│   ├── add_inventaris_screen.dart    # Halaman tambah inventaris
│   └── edit_inventaris_screen.dart   # Halaman edit inventaris
└── services/
    ├── api_service.dart              # Service untuk komunikasi API
    └── auth_service.dart             # Service untuk manajemen autentikasi
```

---

## Alur Aplikasi

### 1. Flow Authentication

```
SplashScreen → Cek Token
    ├─ Token ada → HomeScreen
    └─ Token tidak ada → LoginScreen
        ├─ Belum punya akun → RegisterScreen
        └─ Login berhasil → HomeScreen
```

### 2. Flow CRUD Inventaris

```
HomeScreen (List)
    ├─ Tambah → AddInventarisScreen → Save → Kembali ke HomeScreen (Refresh)
    ├─ Edit → EditInventarisScreen → Update → Kembali ke HomeScreen (Refresh)
    └─ Hapus → Konfirmasi → Delete → Refresh HomeScreen
```

### 3. Flow Logout

```
HomeScreen → Logout Button → Konfirmasi → Hapus Token → LoginScreen
```

---

## Penjelasan Kode per File

### 📱 `lib/main.dart`

**Entry point aplikasi dengan splash screen.**

#### Fungsi Penting:

- **`main()`**: Entry point Flutter, menjalankan widget `MyApp`.

- **`MyApp`**: Widget root yang mengatur MaterialApp dengan tema dan routing.

  - Set `debugShowCheckedModeBanner: false` untuk hilangkan banner debug
  - Tema menggunakan `ColorScheme.fromSeed` dengan warna abu-abu
  - Home diarahkan ke `SplashScreen`

- **`SplashScreen._checkLoginStatus()`**:
  ```dart
  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));  // Delay 2 detik
    final isLoggedIn = await _authService.isLoggedIn();  // Cek token

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }
  ```
  - Menunggu 2 detik untuk efek splash
  - Memanggil `AuthService.isLoggedIn()` untuk cek keberadaan token
  - Navigasi conditional: jika ada token → `HomeScreen`, jika tidak → `LoginScreen`
  - `mounted` check untuk pastikan widget masih aktif sebelum navigasi

---

### 📦 `lib/models/inventaris.dart`

**Model data untuk inventaris komputer.**

#### Struktur Data:

```dart
class Inventaris {
  final int id;
  final String nama;
  final int harga;
  final int jumlah;
  final String tanggalMasuk;
}
```

#### Fungsi Penting:

- **`Inventaris.fromJson(Map<String, dynamic> json)`**:

  ```dart
  factory Inventaris.fromJson(Map<String, dynamic> json) {
    return Inventaris(
      id: json['id'],
      nama: json['nama'],
      harga: json['harga'],
      jumlah: json['jumlah'],
      tanggalMasuk: json['tanggal_masuk'],  // Snake case dari API
    );
  }
  ```

  - Factory constructor untuk parsing respons API ke objek Dart
  - Mapping field `tanggal_masuk` (snake_case dari Laravel) ke `tanggalMasuk` (camelCase)

- **`toJson()`**:
  ```dart
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'harga': harga,
      'jumlah': jumlah,
      'tanggal_masuk': tanggalMasuk,  // Kirim ke API dalam snake_case
    };
  }
  ```
  - Mengubah objek ke Map untuk dikirim sebagai payload API
  - Note: `id` tidak disertakan karena di-generate oleh backend

---

### 👤 `lib/models/user.dart`

**Model data untuk user.**

#### Fungsi Penting:

- **`User.fromJson()`**: Parsing data user dari respons login/register
  ```dart
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
  ```

---

### 🔐 `lib/services/auth_service.dart`

**Service untuk manajemen autentikasi & penyimpanan lokal.**

#### Fungsi Penting:

- **`saveToken(String token)`**:

  ```dart
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  ```

  - Menyimpan token Sanctum ke SharedPreferences
  - Token ini digunakan untuk autentikasi API selanjutnya

- **`saveUserData(String name, String email)`**:

  ```dart
  Future<void> saveUserData(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
  }
  ```

  - Menyimpan data user untuk ditampilkan di UI
  - Tidak perlu request ulang ke API untuk data dasar

- **`getToken()`**:

  ```dart
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  ```

  - Mengambil token tersimpan untuk header Authorization API
  - Return `null` jika tidak ada (belum login)

- **`isLoggedIn()`**:

  ```dart
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
  ```

  - Cek apakah user sudah login dengan memeriksa keberadaan token
  - Digunakan di splash screen untuk conditional routing

- **`logout()`**:
  ```dart
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }
  ```
  - Menghapus semua data user dari SharedPreferences
  - User harus login ulang setelah logout

---

### 🌐 `lib/services/api_service.dart`

**Service untuk komunikasi dengan REST API Laravel.**

#### Konfigurasi:

```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

#### Fungsi Penting:

- **`_getHeaders()`**:

  ```dart
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  ```

  - Helper private untuk menyiapkan headers API
  - Otomatis menambahkan `Authorization: Bearer <token>` jika token ada
  - `Content-Type` & `Accept` untuk JSON request/response

- **`register(String name, String email, String password)`**:

  ```dart
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }
  ```

  - POST request ke `/register`
  - Mengirim data user sebagai JSON body
  - Return decoded response (biasanya berisi `success`, `message`, `data`)

- **`login(String email, String password)`**:

  ```dart
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }
  ```

  - POST request ke `/login`
  - Response biasanya berisi `token` yang harus disimpan
  - Token digunakan untuk request berikutnya

- **`logout()`**:

  ```dart
  Future<void> logout() async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: headers,
    );
  }
  ```

  - POST request ke `/logout` dengan token
  - Backend akan revoke token Sanctum
  - Frontend juga harus hapus token lokal via `AuthService.logout()`

- **`getInventaris()`**:

  ```dart
  Future<List<Inventaris>> getInventaris() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/inventaris'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> inventarisList = data['data'];
      return inventarisList.map((json) => Inventaris.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load inventaris');
    }
  }
  ```

  - GET request dengan Authorization header
  - Parse response: `data['data']` karena Laravel wrap data dalam key `data`
  - Mapping setiap item JSON ke objek `Inventaris` menggunakan `fromJson()`
  - Throw exception jika status bukan 200

- **`addInventaris(Inventaris inventaris)`**:

  ```dart
  Future<Map<String, dynamic>> addInventaris(Inventaris inventaris) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/inventaris'),
      headers: headers,
      body: jsonEncode(inventaris.toJson()),
    );
    return jsonDecode(response.body);
  }
  ```

  - POST request dengan data inventaris
  - Menggunakan `toJson()` untuk convert objek ke Map
  - `jsonEncode()` convert Map ke JSON string

- **`updateInventaris(int id, Inventaris inventaris)`**:

  ```dart
  Future<Map<String, dynamic>> updateInventaris(int id, Inventaris inventaris) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/inventaris/$id'),
      headers: headers,
      body: jsonEncode(inventaris.toJson()),
    );
    return jsonDecode(response.body);
  }
  ```

  - PUT request ke endpoint dengan ID spesifik
  - Mengirim data inventaris lengkap

- **`deleteInventaris(int id)`**:
  ```dart
  Future<Map<String, dynamic>> deleteInventaris(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/inventaris/$id'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }
  ```
  - DELETE request dengan ID
  - Tidak ada body, hanya butuh Authorization

---

### 🔑 `lib/screens/login_screen.dart`

**Halaman login user.**

#### Fungsi Penting:

- **`_login()`**:
  ```dart
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {  // Validasi form dulu
      setState(() => _isLoading = true);  // Tampilkan loading

      try {
        final result = await _apiService.login(
          _emailController.text,
          _passwordController.text,
        );

        if (result['success']) {
          // Simpan token dan data user
          await _authService.saveToken(result['data']['token']);
          await _authService.saveUserData(
            result['data']['user']['name'],
            result['data']['user']['email'],
          );

          if (mounted) {
            // Navigasi ke HomeScreen (replace agar tidak bisa back)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          // Tampilkan error dari API
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Login gagal'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Handle exception (network error, dll)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan. Periksa koneksi Anda.'),
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
  ```
  - Validasi form menggunakan `GlobalKey<FormState>`
  - State management `_isLoading` untuk disable button & tampilkan progress
  - Simpan token dan data user setelah login sukses
  - `pushReplacement` agar user tidak bisa back ke login setelah berhasil
  - Error handling dengan try-catch dan snackbar
  - `mounted` check sebelum `setState` atau `Navigator` untuk hindari error

#### UI Features:

- **Toggle Password Visibility**:

  ```dart
  suffixIcon: IconButton(
    icon: Icon(
      _obscurePassword ? Icons.visibility : Icons.visibility_off,
    ),
    onPressed: () {
      setState(() => _obscurePassword = !_obscurePassword);
    },
  ),
  ```

  - Icon berubah sesuai state
  - Toggle `obscureText` property TextField

- **Form Validation**:
  ```dart
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Email harus diisi';
    }
    if (!value.contains('@')) {
      return 'Email tidak valid';
    }
    return null;
  }
  ```
  - Validasi email tidak kosong dan format valid
  - Password minimal 6 karakter

---

### 📝 `lib/screens/register_screen.dart`

**Halaman registrasi user baru.**

#### Fungsi Penting:

- **`_register()`**:
  ```dart
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final result = await _apiService.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );

        if (result['success']) {
          // Langsung login setelah registrasi
          await _authService.saveToken(result['data']['token']);
          await _authService.saveUserData(
            result['data']['user']['name'],
            result['data']['user']['email'],
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Registrasi gagal'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan. Periksa koneksi Anda.'),
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
  ```
  - Flow mirip login, tapi ada field nama tambahan
  - Backend langsung return token setelah registrasi sukses
  - User langsung masuk ke HomeScreen tanpa perlu login lagi

---

### 🏠 `lib/screens/home_screen.dart`

**Halaman utama menampilkan daftar inventaris.**

#### Fungsi Penting:

- **`initState()`**:

  ```dart
  @override
  void initState() {
    super.initState();
    _loadUserName();  // Load nama user untuk ditampilkan
    _loadInventaris();  // Load data inventaris
  }
  ```

  - Dipanggil sekali saat widget dibuat
  - Load data awal

- **`_loadInventaris()`**:

  ```dart
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
  ```

  - Fetch data dari API
  - Update state `_inventarisList` untuk rebuild UI
  - Error handling dengan snackbar

- **`_logout()`**:

  ```dart
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
      await _apiService.logout();  // Revoke token di backend
      await _authService.logout();  // Hapus token lokal
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }
  ```

  - Tampilkan dialog konfirmasi
  - Return `bool` dari dialog
  - Jika confirm, logout dari backend dan frontend
  - Navigate ke LoginScreen

- **`_deleteInventaris(int id)`**:

  ```dart
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
          _loadInventaris();  // Refresh list
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
  ```

  - Dialog konfirmasi sebelum hapus
  - Call API delete
  - Refresh list jika sukses

#### UI Features:

- **RefreshIndicator**:

  ```dart
  RefreshIndicator(
    onRefresh: _loadInventaris,  // Pull to refresh
    child: ListView.builder(...)
  )
  ```

  - User bisa swipe down untuk refresh data

- **Conditional UI**:

  ```dart
  body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          child: _inventarisList.isEmpty
              ? Center(child: Text('Belum ada inventaris'))
              : ListView.builder(...)
        )
  ```

  - Tampilkan loading saat fetch data
  - Tampilkan empty state jika list kosong
  - Tampilkan ListView jika ada data

- **PopupMenuButton**:
  ```dart
  PopupMenuButton(
    itemBuilder: (context) => [
      PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit),
            SizedBox(width: 8),
            Text('Edit'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
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
        if (result == true) _loadInventaris();
      } else if (value == 'delete') {
        _deleteInventaris(item.id);
      }
    },
  )
  ```
  - Menu titik tiga untuk Edit/Hapus
  - Navigate ke EditScreen dengan pass data inventaris
  - Refresh jika return `true` (berhasil update)

---

### ➕ `lib/screens/add_inventaris_screen.dart`

**Halaman tambah inventaris baru.**

#### Fungsi Penting:

- **`_selectDate()`**:

  ```dart
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
  ```

  - Tampilkan date picker native
  - Format tanggal ke `yyyy-MM-dd` (format MySQL)
  - Set ke TextField controller

- **`_saveInventaris()`**:

  ```dart
  Future<void> _saveInventaris() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final inventaris = Inventaris(
          id: 0,  // ID tidak penting, akan di-generate backend
          nama: _namaController.text,
          harga: int.parse(_hargaController.text),
          jumlah: int.parse(_jumlahController.text),
          tanggalMasuk: _tanggalController.text,
        );

        final result = await _apiService.addInventaris(inventaris);

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inventaris berhasil ditambahkan'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);  // Return true ke HomeScreen
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Gagal menambahkan inventaris'),
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
  ```

  - Validasi form
  - Buat objek `Inventaris` dari input
  - Parse string ke int untuk harga & jumlah
  - POST ke API
  - `Navigator.pop(context, true)` untuk return result ke HomeScreen
  - HomeScreen akan refresh jika dapat `true`

#### UI Features:

- **Input Formatters**:

  ```dart
  TextFormField(
    controller: _hargaController,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    // ...
  )
  ```

  - `digitsOnly` untuk hanya terima angka
  - Keyboard otomatis numeric

- **ReadOnly TextField untuk Tanggal**:

  ```dart
  TextFormField(
    controller: _tanggalController,
    readOnly: true,  // Tidak bisa edit manual
    onTap: _selectDate,  // Buka date picker saat di-tap
    // ...
  )
  ```

- **Dispose Controllers**:
  ```dart
  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _jumlahController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }
  ```
  - Wajib dispose controller untuk hindari memory leak

---

### ✏️ `lib/screens/edit_inventaris_screen.dart`

**Halaman edit inventaris.**

#### Fungsi Penting:

- **`initState()`**:

  ```dart
  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.inventaris.nama);
    _hargaController = TextEditingController(text: widget.inventaris.harga.toString());
    _jumlahController = TextEditingController(text: widget.inventaris.jumlah.toString());
    _tanggalController = TextEditingController(text: widget.inventaris.tanggalMasuk);
  }
  ```

  - Inisialisasi controller dengan data yang sudah ada
  - Data dari `widget.inventaris` yang dipassing dari HomeScreen

- **`_updateInventaris()`**:

  ```dart
  Future<void> _updateInventaris() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final inventaris = Inventaris(
          id: widget.inventaris.id,  // Gunakan ID yang sama
          nama: _namaController.text,
          harga: int.parse(_hargaController.text),
          jumlah: int.parse(_jumlahController.text),
          tanggalMasuk: _tanggalController.text,
        );

        final result = await _apiService.updateInventaris(
          widget.inventaris.id,  // Pass ID untuk endpoint
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
  ```

  - Mirip dengan add, tapi gunakan ID existing
  - PUT request ke `/inventaris/{id}`

- **`_selectDate()`**:

  ```dart
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.inventaris.tanggalMasuk),  // Set initial dari data
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
  ```

  - `initialDate` dari data yang sedang diedit

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0 # HTTP client
  shared_preferences: ^2.2.2 # Local storage
  intl: ^0.18.1 # Date formatting
```

---
