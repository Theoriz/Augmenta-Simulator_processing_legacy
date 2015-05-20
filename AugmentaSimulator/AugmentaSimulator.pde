/**
 *
 *    * Augmenta simulator
 *    Send some generated Augmenta Packet
 *    Use your mouse to send custom packets
 *
 *    Author : David-Alexandre Chanel
 *             Tom Duchêne
 *
 *    Website : http://www.theoriz.com
 *
 */

import netP5.*;
import java.awt.geom.Point2D;
import g4p_controls.*;
import augmentaP5.*;

AugmentaP5 augmenta;
NetAddress sendingAddress;
AugmentaPerson testPerson;
GTextField portInput;
GButton portInputButton;
GSlider slider;

float x, oldX = 0;
float y, oldY = 0;
float t = 0; // time
int age = 0;
int sceneAge = 0;
int direction = 1;
int pid = int(random(1000));
int oscPort = 12000;

Boolean send = true;
Boolean moving = false;
Boolean grid = false;
Boolean draw = true;
Boolean gridHasChanged = false;

// Array of TestPerson points
int unit = 65;
int count;
TestPerson[] persons;

void setup() {
  size(640, 480);
  frameRate(30);

  // Setup the array of TestPerson
  int wideCount = width / unit;
  int highCount = height / unit;
  count = wideCount * highCount;
  persons = new TestPerson[count];

  // Create grid
  int index = 0;
  for (int y = 0; y < highCount; y++) {
    for (int x = 0; x < wideCount; x++) {
      persons[index] = new TestPerson(x*unit, y*unit, unit/2, unit/2, random(0.05, 0.8), unit);
      persons[index].p.oid = index; // set oid

      index++;
    }
  }

  // Osc network com
  augmenta = new AugmentaP5(this, 50000);
  sendingAddress = new NetAddress("192.168.1.21", oscPort);
  RectangleF rect = new RectangleF(0.4f, 0.4f, 0.2f, 0.2f);
  PVector pos = new PVector(0.5f, 0.5f);
  testPerson = new AugmentaPerson(pid, pos, rect);
  testPerson.highest.z = random(0.4, 0.6);

  // Set the UI
  portInput = new GTextField(this, 10, 22, 60, 20);
  portInputButton = new GButton(this, 70, 22, 110, 20, "Change Osc IP:Port");
  portInput.setText(""+oscPort);
  slider = new GSlider(this, 8, 120, 270, 15, 15);
  G4P.registerSketch(this);

  // Init
  y=height/2;
  x=width/2;
}

void draw() {

  background(0);

  if (gridHasChanged && !mousePressed){
     updateGrid();
     gridHasChanged = false;
  }

  if (grid) {
    // Update and draw the TestPersons
    for (int i = 0; i < persons.length; i++) {
      persons[i].update();
      //persons[i].send(augmenta, sendingAddress);
      if (send) {
        fill(255);
      } else {
        fill(128);
      }
      if(draw){
        persons[i].draw();
      }
    }
  } 

  if (!mousePressed)
  {
    // Save the old positions for the main point
    oldX = x;
    oldY = y;
    // Sin animation
    if (moving) {
      x = map(sin(t), -1, 1, width/10, width*9/10);
    }
  }
  // Draw disk
  if (send) {
    fill(255);
  } else {
    fill(128);
  }
  if (draw){
    ellipse(x, y, 20, 20);
    //rect(
    textSize(16);
    text(""+pid, x+20, y-10, 50, 20);
  }
  

  // Increment val
  t= t + direction*TWO_PI/70; // 70 inc
  t = t % TWO_PI;
  age++;

  // Update point
  testPerson.centroid.x = (float)x/width;
  testPerson.centroid.y = (float)y/height;
  testPerson.velocity.x = (x - oldX)/width;
  testPerson.velocity.y = (y - oldY)/height;
  testPerson.boundingRect.x = (float)x/width-0.1;
  testPerson.boundingRect.y = (float)y/height-0.1;
  testPerson.highest.x = testPerson.centroid.x;
  testPerson.highest.y = testPerson.centroid.y;
  // Other values 
  testPerson.age = age;
  testPerson.depth = 0.5f;

  // Send point
  if (send) {
    augmenta.sendSimulation(testPerson, sendingAddress);
    if (grid) {
      for (int i = 0; i < persons.length; i++) {
        persons[i].send(augmenta, sendingAddress);
      }
    }
  }
  // Send scene
  sceneAge++;
  float percentCovered = random(0.1)+0.2f;
  Point2D.Float p = new Point2D.Float(2f+random(0.1), -2f+random(0.1));
  augmenta.sendScene(width, height, 100, sceneAge, percentCovered, persons.length, p, sendingAddress);

  // Text
  textSize(14);
  text("Drag mouse to send custom data to 127.0.0.1:"+oscPort, 10, 16);
  text("Press [s] to toggle data sending", 10, 60);
  text("Press [m] to toggle automatic movement", 10, 75);
  text("Press [d] to toggle the draw on this window", 10, 90);
  text("Press [g] to toggle a grid of "+count+" persons", 10, 105);
}

void mouseDragged() {
  oldX = x;
  oldY = y;
  // Update coords
  x = mouseX;
  y = mouseY;

  // The following code is here just for pure fun and aesthetic !
  // It enables the point to go on in its sinus road where
  // you left it !

  // Clamping
  if (x>width*9/10)
  {
    x=width*9/10;
  }
  if (x<width/10)
  {
    x=width/10;
  }
  // Reverse
  t = asin(map(x, width/10, width*9/10, -1, 1));
  // Don't do it visually
  x = mouseX;
  // Change direction by calculating speed vector
  if (mouseX - pmouseX < 0)
  {
    direction = -1;
  } else {
    direction = 1;
  }
}

void keyPressed() {

  // Stop/Start the movement of the point
  if (key == 'm' || key == 'M') {
    moving=!moving;
  } else if (key == 's' || key == 'S') {
    send=!send;
    if (send) {
      augmenta.sendSimulation(testPerson, sendingAddress, "personEntered");
      // Send personWillLeave for the old grid
      for (int i = 0; i < persons.length; i++) {
        persons[i].send(augmenta, sendingAddress, "personEntered");
      }
    } else {
      augmenta.sendSimulation(testPerson, sendingAddress, "personWillLeave");
      // Send personWillLeave for the old grid
      for (int i = 0; i < persons.length; i++) {
        persons[i].send(augmenta, sendingAddress, "personWillLeave");
      }
    }
    pid = int(random(1000));
    age = 0;
  } else if (key == ENTER || key == RETURN) {
    if (portInput.hasFocus() == true) {
      handlePortInputButton();
    }
  } else if (key == 'g' || key == 'G') {
    grid=!grid;
    if (!grid && send) {
      // Send personWillLeave for the old grid
      for (int i = 0; i < persons.length; i++) {
        persons[i].send(augmenta, sendingAddress, "personWillLeave");
      }
    }
  } else if (key == 'd' || key == 'D') {
    draw=!draw;
  }
}

public void handleButtonEvents(GButton button, GEvent event) { 
  if (button == portInputButton) {
    handlePortInputButton();
  }
}

public void handlePortInputButton() {

  if (Integer.parseInt(portInput.getText()) != oscPort) {
    println("input :"+portInput.getText());
    oscPort = Integer.parseInt(portInput.getText());
    augmenta.unbind();
    augmenta=null;
    augmenta= new AugmentaP5(this, 50000);
    sendingAddress = new NetAddress("127.0.0.1", oscPort);
  }
}

public void handleSliderEvents(GValueControl slider, GEvent event) {
  unit = (int)((1-slider.getValueF())*120)+12;
   // Setup the array of TestPerson
  int wideCount = width / unit;
  int highCount = height / unit;
  count = wideCount * highCount;
  println("count : "+count);
  gridHasChanged = true;
}

public void updateGrid(){
  
  // Send personWillLeave for the old grid
  for (int i = 0; i < persons.length; i++) {
    persons[i].send(augmenta, sendingAddress, "personWillLeave");
  }
  
  int wideCount = width / unit;
  int highCount = height / unit;
  
  persons = new TestPerson[count];

  // Create grid
  int index = 0;
  for (int y = 0; y < highCount; y++) {
    for (int x = 0; x < wideCount; x++) {
      persons[index] = new TestPerson(x*unit, y*unit, unit/2, unit/2, random(0.05, 0.8), unit);
      persons[index].p.oid = index; // set oid
      index++;
    }
  } 
}
