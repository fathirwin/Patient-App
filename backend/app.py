"""
Backend API untuk model Klasifikasi Perawatan Pasien (FCNN / TabNet).
Menerima data EHR pasien dari aplikasi Flutter dan mengembalikan prediksi:
  0 -> "in"  (Rawat Inap)
  1 -> "out" (Rawat Jalan)

CARA PAKAI
----------
1. Jalankan notebook DeepLearning_FCNN_TabNet_EHR.ipynb sampai selesai.
2. Tambahkan sel ekspor di akhir notebook (lihat README.md bagian "Ekspor Model")
   untuk menyimpan:
     - scaler.pkl           (MinMaxScaler yang sudah di-fit)
     - model_fcnn.h5        (jika FCNN adalah model terbaik), ATAU
     - tabnet_model.zip      (jika TabNet adalah model terbaik)
3. Salin file-file tersebut ke folder backend/ ini (sejajar dengan app.py).
4. Set MODEL_TYPE di bawah ("fcnn" atau "tabnet") sesuai model terbaikmu.
5. pip install -r requirements.txt
6. uvicorn app:app --host 0.0.0.0 --port 8000
7. Di aplikasi Flutter, arahkan BASE_URL ke http://<IP-KOMPUTERMU>:8000
   (gunakan IP LAN, bukan 'localhost', supaya HP fisik/emulator bisa akses)
"""

import os
import joblib
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# ── KONFIGURASI ──────────────────────────────────────────────────────────
MODEL_TYPE = os.environ.get("MODEL_TYPE", "fcnn")  # "fcnn" atau "tabnet"
MODEL_DIR = os.path.dirname(os.path.abspath(__file__))

NUMERIC_COLS = [
    "HAEMATOCRIT", "HAEMOGLOBINS", "ERYTHROCYTE", "LEUCOCYTE",
    "THROMBOCYTE", "MCH", "MCHC", "MCV", "AGE",
]
LABEL_MAP = {0: "in", 1: "out"}
LABEL_TEXT = {"in": "Rawat Inap", "out": "Rawat Jalan"}

app = FastAPI(title="Prediksi Perawatan Pasien API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class PatientInput(BaseModel):
    age: float = Field(..., ge=0, le=120, description="Usia pasien (tahun)")
    sex: str = Field(..., pattern="^(M|F)$", description="'M' atau 'F'")
    haematocrit: float
    haemoglobins: float
    erythrocyte: float
    leucocyte: float
    thrombocyte: float
    mch: float
    mchc: float
    mcv: float


class PredictionOutput(BaseModel):
    label: str
    label_text: str
    confidence: float
    model_used: str


# ── LOAD ARTIFACTS ───────────────────────────────────────────────────────
scaler = None
fcnn_model = None
tabnet_model = None


def load_artifacts():
    global scaler, fcnn_model, tabnet_model

    scaler_path = os.path.join(MODEL_DIR, "scaler.pkl")
    if not os.path.exists(scaler_path):
        raise RuntimeError(
            f"scaler.pkl tidak ditemukan di {MODEL_DIR}. "
            "Ekspor dulu dari notebook (lihat README.md)."
        )
    scaler = joblib.load(scaler_path)

    if MODEL_TYPE == "fcnn":
        import tensorflow as tf
        model_path = os.path.join(MODEL_DIR, "model_fcnn.h5")
        if not os.path.exists(model_path):
            raise RuntimeError(f"model_fcnn.h5 tidak ditemukan di {MODEL_DIR}.")
        fcnn_model = tf.keras.models.load_model(model_path)

    elif MODEL_TYPE == "tabnet":
        from pytorch_tabnet.tab_model import TabNetClassifier
        model_path = os.path.join(MODEL_DIR, "tabnet_model.zip")
        if not os.path.exists(model_path):
            raise RuntimeError(f"tabnet_model.zip tidak ditemukan di {MODEL_DIR}.")
        tabnet_model = TabNetClassifier()
        tabnet_model.load_model(model_path)

    else:
        raise RuntimeError("MODEL_TYPE harus 'fcnn' atau 'tabnet'")


@app.on_event("startup")
def _startup():
    load_artifacts()


def build_feature_vector(data: PatientInput) -> np.ndarray:
    """Susun fitur PERSIS sesuai urutan training:
    [HAEMATOCRIT, HAEMOGLOBINS, ERYTHROCYTE, LEUCOCYTE, THROMBOCYTE,
     MCH, MCHC, MCV, AGE, SEX_F, SEX_M]
    """
    numeric_values = np.array([[
        data.haematocrit, data.haemoglobins, data.erythrocyte,
        data.leucocyte, data.thrombocyte, data.mch, data.mchc,
        data.mcv, data.age,
    ]], dtype=float)

    numeric_scaled = scaler.transform(numeric_values)

    sex_f = 1.0 if data.sex.upper() == "F" else 0.0
    sex_m = 1.0 if data.sex.upper() == "M" else 0.0

    features = np.concatenate([numeric_scaled, [[sex_f, sex_m]]], axis=1)
    return features.astype(np.float32)


@app.get("/health")
def health():
    return {"status": "ok", "model_type": MODEL_TYPE}


@app.post("/predict", response_model=PredictionOutput)
def predict(data: PatientInput):
    try:
        features = build_feature_vector(data)

        if MODEL_TYPE == "fcnn":
            prob_out = float(fcnn_model.predict(features, verbose=0)[0][0])
            label_idx = 1 if prob_out > 0.5 else 0
            confidence = prob_out if label_idx == 1 else 1 - prob_out
        else:
            probs = tabnet_model.predict_proba(features)[0]
            label_idx = int(np.argmax(probs))
            confidence = float(probs[label_idx])

        label = LABEL_MAP[label_idx]
        return PredictionOutput(
            label=label,
            label_text=LABEL_TEXT[label],
            confidence=round(confidence * 100, 2),
            model_used=MODEL_TYPE.upper(),
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
