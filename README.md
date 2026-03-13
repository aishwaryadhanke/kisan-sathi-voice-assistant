# 🌾 Kisan Sathi – Voice Assistant for Farmers

Kisan Sathi is a Hindi voice-based assistant that helps farmers access important agricultural information using simple voice commands.

Farmers can ask questions in Hindi and receive useful information such as:

* Weather updates
* Mandi (market) prices
* Nearby agricultural markets

The system combines **speech recognition, natural language processing, and a mobile application** to make agricultural information easily accessible.

---

## 📸 Screenshots

### Home Screen
![Home Screen](images/home_screen.png)

### Voice Input
![Voice Input](images/voice_input.png)

### Weather Result
![Weather Result](images/weather_result.png)

### Nearby Market Search
![Nearby Market](images/nearby_market.png)

### Question History
![Question History](images/question_history.png)

## 🚀 Features

* 🎤 Hindi voice input
* 🌦 Weather information
* 📈 Mandi price information
* 📍 Nearby market detection
* 🧠 NLP-based intent detection
* 📱 Flutter mobile application

---

## 🧰 Tech Stack

### Frontend

Flutter

### Backend

Python
FastAPI

### AI / NLP

Speech Recognition
Transformers (Hugging Face)

### Model

IndicWav2Vec Hindi Speech Recognition (Bharat4AI)

---

## 📂 Project Structure

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
│       └── utility files
│
├── kisan_sathi
│   ├── android
│   ├── assets
│   ├── lib
│   └── pubspec.yaml
│
├── images
│   ├── home_screen.png
│   ├── voice_input.png
│   ├── weather_result.png
│   ├── mandi_price.png
│   ├── nearby_market.png
│   └── question_history.png
│
└── README.md
```

---

## ⚙️ Backend Setup

Clone the repository

```
git clone https://github.com/aishwaryadhanke/kisan-sathi-voice-assistant.git
cd kisan-sathi-voice-assistant
```

Install dependencies

```
pip install fastapi uvicorn transformers torch datasets
```

Run the backend server

```
cd backend/app
uvicorn main:app --reload
```

Backend will start at

```
http://127.0.0.1:8000
```

---

## 📱 Flutter Setup

Go to the Flutter project

```
cd kisan_sathi
```

Install dependencies

```
flutter pub get
```

Run the application

```
flutter run
```

---

## 🔊 Model Setup

This project uses the **IndicWav2Vec Hindi speech recognition model** from Bharat4AI.

The model is **not included in this repository** because it is large.

### Install required libraries

```
pip install transformers torch datasets
```

### Download the model

Run this Python code once:

```python
from transformers import Wav2Vec2Processor, Wav2Vec2ForCTC

processor = Wav2Vec2Processor.from_pretrained("Bharat4AI/indicwav2vec-hindi")
model = Wav2Vec2ForCTC.from_pretrained("Bharat4AI/indicwav2vec-hindi")
```

Model source:
https://huggingface.co/Bharat4AI/indicwav2vec-hindi

### Place model files

Place the downloaded files inside:

```
backend/asr/
```

Example structure:

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

## 🎤 Example Queries

Farmers can ask questions like:

* आज का मौसम कैसा है
* सोयाबीन का मंडी भाव क्या है
* मेरे पास की मंडी कहाँ है

The system detects the user's intent and returns the appropriate information.

---

## 👩‍💻 Author

**Aishwarya Dhanake**
MCA Student
