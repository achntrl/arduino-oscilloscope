import processing.serial.*;
import controlP5.*;
import java.util.*;


// Constants
final int CHANNELS = 4; // Number of channels on the oscilloscope
final int[] COLORS = {#FFFF00, #FF0000, #00FF00, #00FFFF}; // Colors for each channel
// Menu elements
ControlP5 cp5;
CheckBox channelDisplay;
RadioButton channelTrigger;
Toggle trigger, upOrDown, pause;
Slider triggerValue;
Textlabel textLabelChan1, textLabelChan2, textLabelChan3, textLabelChan4;
// Drawing parameters
int horizontalBorderPx = 10; // Border padding (px)
int verticalBorderPx = 10; // Border padding (px)
int menuSizePx = 240;
int menuPaddingPx = 20;
int verticalAlign; 
int divSize_ms = 1000; // time span of the screen (in ms) 
// Measures containers
Serial serialConnexion;
int[] AdcReadings = {0, 0, 0, 0}; // Store the raw values from the ADC
int[] x = {0, 0, 0, 0};
int[] y = {0, 0, 0, 0};
int[] oldx = {0, 0, 0, 0};
int[] oldy = {0, 0, 0, 0};
int time = 0;
// GUI interactions
float[] isDisplayed = {1, 1, 1, 1};
boolean hasEndedPause = false;

// Ran once by processing at the start of the program
void setup()
{
  size(1560, 820); // Screen size (better if (x - 480) is multiple of 12)
  noStroke();
  verticalAlign= width - menuSizePx + verticalBorderPx + menuPaddingPx;
  // [EDIT] Adapt portName to your computer by changing the index. Portname should be the
  // /dev/cu.* corresponding to your Arduino. If you do ls /dev/cu.* and the arduino is the 
  // 4th in the list put index = 4 - 1 = 3 in Serial.list()[index]
  String portName = Serial.list()[3]; 
  serialConnexion = new Serial(this, portName, 19200);
  println("Connected to "+portName);
  grid();
  menu();
}


// Draw the grid
void grid()
{
  clear();
  background(0); // black background
  smooth(); // smooth drawings

  strokeWeight(1);
  stroke(128, 128, 128); // color of grid (gray)


  double timeNotch, voltageNotch;
  // Vertical lines for the time : 1s/div scale
  timeNotch = (double)(width -  menuSizePx) / 12;
  for (int i = (int)timeNotch; i <= width - menuSizePx; i += (int)timeNotch) {
    line(i + verticalBorderPx, horizontalBorderPx, i + verticalBorderPx, height - horizontalBorderPx);
  }
  // Horizontal lines for the voltage : 0.2V scale
  voltageNotch = ((double)height - ((double)horizontalBorderPx * 2.0)) * 0.2 / 5.0;
  int counter = 0;
  for (int j =(int)voltageNotch; j <= height - horizontalBorderPx; j+= (int)voltageNotch) {
    /* Every volt, we draw a large line */
    if (counter % 5 == 4)
    {
      strokeWeight(3);
    } else
    {
      strokeWeight(1);
    }
    line(1 + verticalBorderPx, height - horizontalBorderPx - j, 
      width - menuSizePx + verticalBorderPx, height - horizontalBorderPx - j);
    counter++;
  }

  // Outter borders
  strokeWeight(3); // width of lines
  stroke(255, 255, 255); // color of the axis (white)
  line(1 + verticalBorderPx, horizontalBorderPx, 
    1 + verticalBorderPx, height - horizontalBorderPx); // Vertical left border
  line(width - menuSizePx + verticalBorderPx, horizontalBorderPx, 
    width - menuSizePx + verticalBorderPx, height - horizontalBorderPx); // Vertical right border
  line(1 + verticalBorderPx, height - horizontalBorderPx, 
    width -  menuSizePx + verticalBorderPx, height - horizontalBorderPx); // Horizontal bottom border
  line(1 + verticalBorderPx, horizontalBorderPx, 
    width -  menuSizePx + verticalBorderPx, horizontalBorderPx); // Horizontal top border
  strokeWeight(2);
}

// Draw the rectangles for the channels legend
void legend()
{
  stroke(COLORS[0]);
  fill(COLORS[0]);
  rect(verticalAlign, 440, 20, 20);

  stroke(COLORS[1]);
  fill(COLORS[1]);
  rect(verticalAlign, 480, 20, 20);

  stroke(COLORS[2]);
  fill(COLORS[2]);
  rect(verticalAlign, 520, 20, 20);

  stroke(COLORS[3]);
  fill(COLORS[3]);
  rect(verticalAlign, 560, 20, 20);
}


// Generate the menu
void menu()
{
  cp5 = new ControlP5(this);

  cp5.addButton("reset")
    .setValue(0)
    .setPosition(verticalAlign, 20)
    .setSize(200, 20)
    ;
  List divs = Arrays.asList("100ms", "200ms", "500ms", "1s"); // Time per div options
  cp5.addScrollableList("timePerDiv")
    .setPosition(verticalAlign, 60)
    .setSize(200, 20+40)
    .setBarHeight(20)
    .setItemHeight(20)
    .addItems(divs)
    .setType(ControlP5.DROPDOWN)
    ;  

  channelDisplay = cp5.addCheckBox("channelDisplay")
    .setPosition(verticalAlign, 140)
    .setSize(20, 20)
    .setItemsPerRow(2)
    .setSpacingColumn(50)
    .setSpacingRow(20)
    .addItem("Chan1", 0)
    .addItem("Chan2", 1)
    .addItem("Chan3", 2)
    .addItem("Chan4", 3)
    .activate(0)
    .activate(1)
    .activate(2)
    .activate(3)
    ;

  trigger = cp5.addToggle("trigger")
    .setPosition(verticalAlign, 220)
    .setSize(100, 20)
    ;

  upOrDown = cp5.addToggle("upOrDown")
    .setPosition(verticalAlign + 120, 220)
    .setSize(80, 20)
    .setMode(ControlP5.SWITCH)
    .setCaptionLabel("Up                           Down")
    ;

  triggerValue = cp5.addSlider("triggerValue")
    .setPosition(verticalAlign, 260)
    .setSize(200, 20)
    .setRange(0, 5)
    .setCaptionLabel("V")
    .setValue(2.5)
    ;

  channelTrigger = cp5.addRadioButton("channelTrigger")
    .setPosition(verticalAlign, 300)
    .setSize(20, 20+40)
    .setBarHeight(20)
    .setItemHeight(20)
    .setItemsPerRow(2)
    .setSpacingColumn(50)
    .setSpacingRow(20)
    .addItem("Chan1T", 0)
    .addItem("Chan2T", 1)
    .addItem("Chan3T", 2)
    .addItem("Chan4T", 3)
    .activate(0);
  ;

  pause = cp5.addToggle("pause")
    .setPosition(verticalAlign, 380)
    .setSize(200, 20)
    .setLabel("                                           PAUSE");
  ;

  textLabelChan1 = cp5.addTextlabel("textLabelChan1")
    .setText("CHAN1")
    .setPosition(verticalAlign + 30, 440 + 6)
    .setColorValue(#FFFFFF)
    ;

  textLabelChan2 = cp5.addTextlabel("textLabelChan2")
    .setText("CHAN2")
    .setPosition(verticalAlign + 30, 480 + 6)
    .setColorValue(#FFFFFF)
    ;

  textLabelChan3 = cp5.addTextlabel("textLabelChan3")
    .setText("CHAN3")
    .setPosition(verticalAlign + 30, 520 + 6)
    .setColorValue(#FFFFFF)
    ;

  textLabelChan4 = cp5.addTextlabel("textLabelChan4")
    .setText("CHAN4")
    .setPosition(verticalAlign + 30, 560 + 6)
    .setColorValue(#FFFFFF)
    ;
}

// Resets the lines (they start again at 0)
void reset(int n)
{
  for (int i = 0; i < CHANNELS; ++i) {
    x[i] = 0;
    oldx[i] = 0;
  }
  grid();
  legend();
  time = millis();
}

// Change the timescale to the value in the dropdown menu
void timePerDiv(int n)
{
  reset(0);
  switch(n) {
  case 0:
    divSize_ms = 100;
    break;
  case 1:
    divSize_ms = 200;
    break;
  case 2:
    divSize_ms = 500;
    break;
  case 3:
    divSize_ms = 1000;
    break;
  default:
    divSize_ms = 1000;
  }
}




// Main drawing loop 
void draw() 
{
  if (hasEndedPause) {
    reset(0);
    hasEndedPause = false;
  }

  for (int i = 0; i < CHANNELS; ++i) {
    // Value actualisation
    oldx[i] = x[i];
    x[i] = ((millis() - time) % (divSize_ms * 12)) * (width -  menuSizePx)/ (divSize_ms * 12); 
    if (oldx[i] > x[i] && trigger.getBooleanValue() == false) { 
      reset(0);
    } 
    oldy[i] = y[i];
    y[i] = int(map(AdcReadings[i], 0, 1023, height - horizontalBorderPx, horizontalBorderPx)); // resize y to fit the grid
  }
  if (trigger.getBooleanValue() == false || checkTrigger()) {
    for (int i = 0; i < CHANNELS; ++i) {
      if (isDisplayed[i] != 0) {
        stroke(COLORS[i]);
        line(oldx[i] + verticalBorderPx, oldy[i], x[i] + verticalBorderPx, y[i]); // draw the line
      }
    }
  }
}


// React to events on the display
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(channelDisplay)) {
    isDisplayed = channelDisplay.getArrayValue();
  }

  if (theEvent.isFrom(pause)) {
    if (pause.getBooleanValue() == true) {
      noLoop();
    }
    if (pause.getBooleanValue() == false) {
      loop();
      hasEndedPause = true;
    }
  }
}

boolean checkTrigger()
{

  int i = (int)channelTrigger.getValue();
  float threshold_f = triggerValue.getValue();
  int threshold = int(map(threshold_f, 0, 5, height - horizontalBorderPx, horizontalBorderPx)); // Mapping the threshold value on the screen
  if (upOrDown.getBooleanValue() == true) { // Up
    if ( oldy[i] >= threshold && y[i] <= threshold) { // Pixels start from the top
      reset(0);
      trigger.toggle();
      return true;
    }
  } else if (upOrDown.getBooleanValue() == false) {
    if ( oldy[i] <= threshold && y[i] >= threshold) {
      reset(0);
      trigger.toggle();
      return true;
    }
  }
  return false;
}

// Read serial
void serialEvent(Serial serialConnexion) 
{ 
  try {
    String stringRead=serialConnexion.readStringUntil('\n'); /* read serial until end of line */

    if (stringRead != null) { 
      String[] channelReadings = split(stringRead, '\t');
      for (int i = 0; i < CHANNELS; ++i) {
        AdcReadings[i] = int(channelReadings[i]);
      }
    }
  }
  catch(RuntimeException e) {
  }
}