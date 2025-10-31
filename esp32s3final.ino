#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <WiFiManager.h> 
#include <Wire.h>
#include "MAX30105.h"
#include "heartRate.h"
#include <Adafruit_MLX90614.h>
#include <WebServer.h>
#include "secrets.h"


// ── Firebase (from your UID sketch) ───────────────────────────────────
#define API_KEY         "*********"
#define DATABASE_URL    "*********"

FirebaseData   fbdo;
FirebaseAuth   auth;
FirebaseConfig config;

// ── HTTP server for UID ─────────────────────────────────────────────────────
WebServer      server(80);
String         userUID = "";

// ── MAX30105 (heart/spO₂) globals ────────────────────────────────────────────
MAX30105       particleSensor;
const byte     RATE_SIZE = 4;
byte           rates[RATE_SIZE];
byte           rateSpot   = 0;
long           lastBeat   = 0;
float          beatsPerMinute;
int            beatAvg;
float          spo2        = 0;
#define BUFFER_SIZE 100
uint32_t       irBuffer[BUFFER_SIZE];
uint32_t       redBuffer[BUFFER_SIZE];
int            bufferIndex = 0;

// ── MLX90614 (temperature) globals ──────────────────────────────────────────
Adafruit_MLX90614 mlx;
float            bodyTemp = 0;

// ── Shared timing / state ───────────────────────────────────────────────────
unsigned long sendDataPrevMillis = 0;
bool          signupOK            = false;

// ── Handle incoming UID from Flutter ────────────────────────────────────────
void handleUID() {
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "No UID provided");
    return;
  }
  if (userUID == "") {
    userUID = server.arg("plain");
    Serial.println("✅ UID received: " + userUID);
    server.send(200, "text/plain", "UID stored");
  } else {
    server.send(200, "text/plain", "UID already set");
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  // 1) → Connect Wi-Fi
    WiFiManager wm;
    bool res;
    res = wm.autoConnect("ESP32S3","healthcare"); // password protected ap
    if(!res) {
        Serial.println("Failed to connect");
        // ESP.restart();
    } 
    else {
  Serial.println("\nConnected! IP=" + WiFi.localIP().toString());
}
  //  Start HTTP server for UID
  server.on("/setUID", HTTP_POST, handleUID);
  server.begin();

  // Firebase 
  config.api_key            = API_KEY;
  config.database_url       = DATABASE_URL;
  auth.user.email          = "";
  auth.user.password       = "";
  config.token_status_callback = tokenStatusCallback;
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase signUp OK");
    signupOK = true;
  } else {
    Serial.printf("Firebase signUp FAILED: %s\n", config.signer.signupError.message.c_str());
  }
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Firebase.RTDB.setString(&fbdo, "/Sensor/device_ip", WiFi.localIP().toString());

  // ──────────────────────────────────────────────────────────────────────────
  //  Sensor I²C wiring on SDA=GPIO5, SCL=GPIO6
  //     We Start at 100 kHz for MLX90614
  Wire.begin(5, 6);
  if (!mlx.begin()) {
    Serial.println("MLX90614 not found");
    while (1);
  }

  //  and then Boost to 400 kHz for MAX30105
  Wire.setClock(400000);
  Wire.beginTransmission(0x57);
  Wire.write(0x09);
  Wire.write(0x40);
  Wire.endTransmission();
  delay(500);

  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30105 not found");
    while (1);
  }
  particleSensor.setup();
  particleSensor.setPulseAmplitudeRed(0x0A);
  particleSensor.setPulseAmplitudeGreen(0);
  Serial.println("Place your finger on the MAX30105 sensor");
}

void loop() {
  // Always accept incoming UID posts
  server.handleClient();

  // Doesnt start sending data until UID is set
  if (userUID == "") {
    Serial.println(" Waiting for UID from Flutter...");
    delay(1000);
    return;
  }

  //   Read MAX30105 (at 400 kHz) 
  Wire.setClock(400000);
  long irValue  = particleSensor.getIR();
  long redValue = particleSensor.getRed();
  irBuffer[bufferIndex]  = irValue;
  redBuffer[bufferIndex] = redValue;
  bufferIndex++;

  if (bufferIndex >= BUFFER_SIZE) {
    // compute AC/DC and SpO₂ exactly as in your sensor sketch
    float irAC = 0, redAC = 0, irDC = 0, redDC = 0;
    for (int i = 0; i < BUFFER_SIZE; i++) {
      irDC  += irBuffer[i];
      redDC += redBuffer[i];
    }
    irDC  /= BUFFER_SIZE;
    redDC /= BUFFER_SIZE;
    for (int i = 0; i < BUFFER_SIZE; i++) {
      irAC  += pow(irBuffer[i]  - irDC,  2);
      redAC += pow(redBuffer[i] - redDC, 2);
    }
    irAC  = sqrt(irAC  / BUFFER_SIZE);
    redAC = sqrt(redAC / BUFFER_SIZE);
    float ratio = (redAC / redDC) / (irAC / irDC);
    spo2 = constrain(110 - 25 * ratio, 70, 100);
    bufferIndex = 0;
  }

  // Beat detection
  if (checkForBeat(redValue)) {
    long delta = millis() - lastBeat;
    lastBeat   = millis();
    beatsPerMinute = 60 / (delta / 1000.0);
    if (beatsPerMinute > 20 && beatsPerMinute < 255) {
      rates[rateSpot++] = (byte)beatsPerMinute;
      rateSpot %= RATE_SIZE;
      beatAvg = 0;
      for (byte i = 0; i < RATE_SIZE; i++) beatAvg += rates[i];
      beatAvg /= RATE_SIZE;
    }
  }

  //  Read MLX90614 temperature (at 100 kHz) 
  Wire.setClock(100000);
  bodyTemp = mlx.readObjectTempC();

  //  Debug print 
  Serial.print("BPM=");   Serial.print(beatsPerMinute);
  Serial.print(", Avg="); Serial.print(beatAvg);
  Serial.print(", SpO₂=");Serial.print(spo2);
  Serial.print(", T=");   Serial.println(bodyTemp);

  //  Push to RTDB under dynamic path 
  if (Firebase.ready() && signupOK &&
      (millis() - sendDataPrevMillis > 5000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();
    String basePath = "/Sensor/" + userUID + "/";
    Firebase.RTDB.setFloat(&fbdo, basePath + "heart_rate_bpm", beatsPerMinute);
    Firebase.RTDB.setInt  (&fbdo, basePath + "avg_bpm",      beatAvg);
    Firebase.RTDB.setFloat(&fbdo, basePath + "spo2",          spo2);
    Firebase.RTDB.setFloat(&fbdo, basePath + "temperature_c", bodyTemp);
  }
}
