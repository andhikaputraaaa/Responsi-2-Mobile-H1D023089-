class Inventaris {
  final int id;
  final String nama;
  final int harga;
  final int jumlah;
  final String tanggalMasuk;

  Inventaris({
    required this.id,
    required this.nama,
    required this.harga,
    required this.jumlah,
    required this.tanggalMasuk,
  });

  factory Inventaris.fromJson(Map<String, dynamic> json) {
    return Inventaris(
      id: json['id'],
      nama: json['nama'],
      harga: json['harga'],
      jumlah: json['jumlah'],
      tanggalMasuk: json['tanggal_masuk'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'harga': harga,
      'jumlah': jumlah,
      'tanggal_masuk': tanggalMasuk,
    };
  }
}