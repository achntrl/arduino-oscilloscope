/* * This program will run on the Arduino. It's role is to acquire the signal */

#define CHANNELS 4 // We have 4 channels
int chans[CHANNELS] = {0, 1, 2, 3}; 
int voltage[CHANNELS]={0, 1, 2, 3}; // Container of the analog reading 
int period=20; // Delay between two measures (in ms) 

void setup()
{ 
  Serial.begin(19200); // Initialization of serial communication
  for (int i = 0; i < CHANNELS; ++i) {
    pinMode(chans[i], INPUT); 
  }
}

void loop() 
{
  // Store the reading
  for (int i = 0; i < CHANNELS; ++i) {
    voltage[i] = analogRead(chans[i]);
  }

  // Print the readings on the serial link
  for (int i = 0; i< CHANNELS; ++i){
    Serial.print(voltage[i]);
      Serial.print('\t');
  }
  Serial.print('\n');
  delay(period);
}
