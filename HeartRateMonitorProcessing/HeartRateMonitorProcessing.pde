
import processing.serial.*;
import static javax.swing.JOptionPane.*;

static final int FPS = 100; //number of samples coming in per second
static final int REPEAT_TIME = 10; //in seconds


Serial myPort;        // The serial port

int xPos = 1;         // horizontal position of the graph
float height_old = 0;
float height_new = 0;
float inByte = 0;

boolean newVal = false;
boolean incomingData = false;
boolean showMOBD = false;

LineGraph graph;

void setup () {
  // set the window size:
  size(1500,400);        
  // set inital background:
  background(0xff);
  frameRate(FPS);
  
  graph = new LineGraph(0,350,REPEAT_TIME*100,400,REPEAT_TIME*100,0, 700);
  
  //Choose the PORT
  String COMlist="",COMx = "";
  try {
    int i = Serial.list().length;
    if (i != 0) {
      if (i >= 2) {
        for (int j = 0; j < i;) {
          COMlist += char(j+'a') + " = " + Serial.list()[j];
          if (++j < i) COMlist += ",  ";
        }
        COMx = showInputDialog("Which COM port is correct? (a,b,..):\n"+COMlist);
        if (COMx == null) exit();
        if (COMx.isEmpty()) exit();
        i = int(COMx.toLowerCase().charAt(0) - 'a') + 1;
      }
      String portName = Serial.list()[i-1];
      myPort = new Serial(this, portName, 9600); 
      myPort.bufferUntil('\n'); 
    }
    else {
      showMessageDialog(frame,"Device is not connected to the PC");
      exit();
    }
  }
  catch (Exception e)
  { //Print the type of error
    showMessageDialog(frame,"COM port is not available (may\nbe in use by another program)");
    println("Error:", e);
    exit();
  }

  changePortStatus(false);
  
}



void draw () {

  background(0xff);
  graph.draw();

  //line(xPos, height_old-100, xPos+1, height_new -100);
  //if (++xPos >= width) {
  //  xPos = 0;
  //  background(0xff);
  //  println(millis());
  //}
  
  ////box with bpm inside
  //stroke(0);
  //fill(0xff);
  //rect(0,0,150,50);
  
  stroke(0);
  //textSize(32);
  //fill(0, 102, 153, 204);
  textSize(32);

  fill(0, 102, 153, 51);

  text(graph.getNumBeats()*60/REPEAT_TIME + " BPM", 10, 35);  // Specify a z-axis value

}

void keyPressed(){
  graph.toggleMOBD();
}


//Start and stop data flow when mouse is released
void mouseReleased() {
  if(incomingData){
      changePortStatus(false);
    }
    else
    {
      changePortStatus(true);
    }
}

void changePortStatus(boolean stat){
    if(!stat){
      myPort.write('0');
      incomingData = false;
      noLoop();
    }
    else
    {
      myPort.write('1');
      incomingData = true;
      loop();
    }
}


void serialEvent (Serial myPort) {
  // get the ASCII string:
  String inString = myPort.readStringUntil('\n');
  
  if (inString != null) {
    // trim off any whitespace:
    inString = trim(inString);
    
    // If leads off detection is true notify with blue line
    if (inString.equals("!")) {
      inByte = 350;  // middle of the ADC range (Flat Line)
    }
    // If the data is good let it through
    else {
      inByte = float(inString); 
     }
     
     //Map and draw the line for new data point
     inByte = map(inByte, 0, 700, 0, height);

     graph.update(inByte);
    
  }
}