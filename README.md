# 🌾 Kisan Sathi – AI Voice Assistant for Farmers

Kisan Sathi is a Hindi voice-based AI assistant designed to help farmers access important agricultural information using simple voice commands.

The system allows farmers to speak their queries in Hindi and receive useful information such as:

* 🌦 Weather updates
* 📈 Mandi (market) prices
* 📍 Nearby agricultural markets

The project combines **speech recognition, natural language processing, and a mobile application** to make agricultural information easily accessible.

---

# 🚀 Features

* 🎤 Hindi voice input from farmers
* 🌦 Real-time weather information
* 📊 Mandi price information
* 📍 Nearby market detection
* 🧠 NLP-based intent detection
* 📱 Mobile interface built with Flutter

---

# 🧰 Tech Stack

### Frontend

* Flutter (Mobile Application)

### Backend

* Python
* FastAPI

### AI / Machine Learning

* Speech Recognition
* NLP Intent Detection
* Hugging Face Transformers

### Model Used

IndicWav2Vec Hindi Speech Recognition Model from **Bharat4AI**

---

# 📂 Project Structure

```
kisan-sathi-voice-assistant
│
├── backend
│   └── app
│       ├── main.py
│       ├── asr_service.py
│       ├── weather_service.py
│       ├── market_price_service.py
│       ├── nearby_market_service.py
│       ├── nlu_intent.py
│       ├── utils_city.py
│       ├── utils_commodity.py
│       └── utils_ollama.py
│
├── kisan_sathi
│   ├── android
│   ├── assets
│   ├── lib
│   │   ├── main.dart
│   │   ├── mandi_bhav_screen.dart
│   │   └── services
│   │       └── api_service.dart
│   │
│   ├── pubspec.yaml
│   └── analysis_options.yaml
│
└── README.md
```

---

# ⚙️ Backend Setup

### 1️⃣ Clone the Repository

```
git clone https://github.com/aishwaryadhanke/kisan-sathi-voice-assistant.git
cd kisan-sathi-voice-assistant
```

### 2️⃣ Install Dependencies

```
pip install fastapi uvicorn transformers torch datasets
```

### 3️⃣ Run the Backend Server

```
cd backend/app
uvicorn main:app --reload
```

The backend server will start at:

```
http://127.0.0.1:8000
```

---

# 📱 Flutter App Setup

### 1️⃣ Go to Flutter Project

```
cd kisan_sathi
```

### 2️⃣ Install Dependencies

```
flutter pub get
```

### 3️⃣ Run the Application

```
flutter run
```

---

# 🔊 Speech Recognition Model Setup

This project uses the **IndicWav2Vec Hindi model from Bharat4AI**.

The model is **not included in the repository** because it is very large.

### Step 1: Install Required Libraries

```
pip install transformers torch datasets
```

### Step 2: Download the Model

Run this Python code once to download the model from Hugging Face.

```python
from transformers import Wav2Vec2Processor, Wav2Vec2ForCTC

processor = Wav2Vec2Processor.from_pretrained("Bharat4AI/indicwav2vec-hindi")
model = Wav2Vec2ForCTC.from_pretrained("Bharat4AI/indicwav2vec-hindi")
```

The model will be downloaded from:

https://huggingface.co/Bharat4AI/indicwav2vec-hindi

### Step 3: Place Model Files

Place the downloaded model files inside:

```
backend/asr/
```

Final structure:

```
backend
│
├── app
│
└── asr
    ├── config.json
    ├── pytorch_model.bin
    ├── vocab.json
    └── tokenizer_config.json
```

---

# 🎤 Example Voice Queries

Farmers can ask questions such as:

* "आज का मौसम कैसा है?"
* "सोयाबीन का मंडी भाव क्या है?"
* "मेरे पास की मंडी कहाँ है?"

The system will detect the **intent** and provide the relevant response.

---

# 📌 Future Improvements

* Support for multiple Indian languages
* Crop advisory system
* Pest detection using computer vision
* Offline voice recognition

---

# 👩‍💻 Author

**Aishwarya Dhanake**

MCA Student
AI • Data Science • Software Development
