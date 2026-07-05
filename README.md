# Aplikasi Mobile Prediksi Perawatan Pasien (EHR)

Aplikasi ini terdiri dari 2 bagian:
1. **backend/** — server Python (FastAPI) yang menjalankan model terbaik dari notebook (FCNN atau TabNet)
2. **flutter_app/** — aplikasi mobile Flutter dengan form input EHR yang ramah pengguna

Arsitekturnya: **Flutter (form input) → HTTP request → Backend Python (model) → hasil prediksi ditampilkan di HP**

Kenapa lewat backend, bukan model langsung di dalam HP? Karena model terbaikmu bisa jadi **TabNet**
(berbasis PyTorch) yang sulit dijalankan langsung di Flutter. Pendekatan backend API ini bekerja
untuk FCNN **maupun** TabNet, jadi kamu tidak perlu ganti arsitektur aplikasi tergantung model mana yang menang.

---

## Langkah 1 — Ekspor model terbaik dari notebook

Setelah menjalankan seluruh notebook `DeepLearning_FCNN_TabNet_EHR.ipynb` (sel evaluasi & komparasi
sudah dijalankan sehingga variabel `acc_fcnn`, `acc_tab`, `model_fcnn`, `model_tabnet`, `scaler` sudah ada),
tambahkan **sel baru di paling akhir notebook** lalu jalankan:

```python
# ── EKSPOR MODEL TERBAIK UNTUK DEPLOYMENT ──
import joblib

joblib.dump(scaler, 'scaler.pkl')

if acc_tab > acc_fcnn:
    model_tabnet.save_model('tabnet_model')  # otomatis jadi tabnet_model.zip
    print("Model terbaik: TabNet -> tersimpan sebagai tabnet_model.zip")
    print("Set MODEL_TYPE = 'tabnet' di backend/app.py")
else:
    model_fcnn.save('model_fcnn.h5')
    print("Model terbaik: FCNN -> tersimpan sebagai model_fcnn.h5")
    print("Set MODEL_TYPE = 'fcnn' di backend/app.py")
```

Ini akan menghasilkan:
- `scaler.pkl` (selalu dibutuhkan)
- `model_fcnn.h5` **atau** `tabnet_model.zip` (tergantung mana yang lebih akurat)

Salin file-file tersebut ke folder `backend/` (sejajar dengan `app.py`).

---

## Langkah 2 — Jalankan backend

```bash
cd backend
pip install -r requirements.txt
# Jika model terbaik FCNN, requirements.txt sudah cukup.
# Jika TabNet, install juga: pip install torch pytorch-tabnet

# set model type sesuai hasil ekspor (default sudah 'fcnn')
export MODEL_TYPE=fcnn      # atau: export MODEL_TYPE=tabnet

uvicorn app:app --host 0.0.0.0 --port 8000
```

Cek server aktif dengan membuka `http://localhost:8000/health` di browser — harus muncul
`{"status":"ok","model_type":"fcnn"}`.

Cari IP LAN komputermu (mis. `192.168.1.10`) dengan `ipconfig` (Windows) atau `ifconfig`/`ip a` (Mac/Linux).
Pastikan HP dan komputer berada di jaringan WiFi yang sama.

---

## Langkah 3 — Jalankan aplikasi Flutter

1. Buka folder `flutter_app/` di VS Code / Android Studio.
2. Edit `lib/services/api_service.dart`, ganti `baseUrl` sesuai kondisi:
   - Emulator Android bawaan → `http://10.0.2.2:8000` (sudah default)
   - HP fisik / iOS simulator → `http://<IP-LAN-KOMPUTERMU>:8000`
3. Jalankan:

```bash
cd flutter_app
flutter pub get
flutter run
```

4. Isi form data pasien (usia, jenis kelamin, hasil lab: Haematocrit, Haemoglobins, Erythrocyte,
   Leucocyte, Thrombocyte, MCH, MCHC, MCV), lalu tekan **"Prediksi Sekarang"**.
5. Aplikasi akan menampilkan hasil: **Rawat Inap** atau **Rawat Jalan**, beserta tingkat keyakinan
   dan model yang digunakan.

---

## Struktur Proyek

```
patient_app/
├── backend/
│   ├── app.py                # FastAPI server + logic prediksi
│   ├── requirements.txt
│   ├── scaler.pkl            # (kamu tambahkan setelah ekspor)
│   └── model_fcnn.h5 / tabnet_model.zip   # (kamu tambahkan setelah ekspor)
└── flutter_app/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── theme/app_theme.dart
        ├── models/patient_data.dart
        ├── services/api_service.dart
        └── screens/
            ├── home_screen.dart      # form input EHR
            └── result_screen.dart    # tampilan hasil prediksi
```

## Catatan Penting

- Aplikasi ini adalah alat bantu prediksi berbasis machine learning, **bukan** alat diagnosis medis.
  Peringatan ini sudah ditampilkan di layar hasil aplikasi.
- Urutan & jenis fitur pada `backend/app.py` (`build_feature_vector`) sudah disamakan persis dengan
  preprocessing di notebook (Min-Max Scaling untuk 9 kolom numerik + One-Hot Encoding SEX_F/SEX_M).
  Jika kamu mengubah urutan/nama kolom di notebook, sesuaikan juga fungsi tersebut.
