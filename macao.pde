// MACAO is a simple system for distributed 
// synchronized video playing  
//
// it is configured using data/config.txt
//
// tomas laurenzo 
// tomas@laurenzo.net
//

import codeanticode.syphon.*;
import processing.video.*;
import oscP5.*;
import netP5.*;


SyphonServer syphonServer;
Movie video;

OscP5 osc;
String [] lines;

boolean iAmServer = true;

int portClient1, portClient2; // change this to an array or vector so that we can have an arbitrary amount of cients
String ipClient1, ipClient2;

int FRAME_RATE = 15; // this should be loaded from config.txt too

void setup() {  
  size (1024, 768, P3D); 
  frameRate(FRAME_RATE);

  // we use suyphon to talk to whoever actually projects 
  syphonServer = new SyphonServer(this, "macao"); 

  lines = loadStrings("config.txt");  // load the configuration data

  if (lines[0].equals("server")) iAmServer = true;
  else iAmServer = false;

  
  print ("Macao 00 - 2015. I am ");
  if (iAmServer) println ("server.");
  else println ("client."); 
  println();  println();

  String sPort = lines[1];  // this is the server port. In case we want in the future bidirectional communication. 
                            // as of now it is not used.
  int p = new Integer(sPort).intValue();
  
  
  osc = new OscP5(this, p); // we use OSC to communicate the server with its clients

  if (iAmServer) {  // as said above, it assumes there are two clients.
                    // todo This should be changed to a vector of clients and dynamically loading as many clients as needed
    ipClient1 = lines[3];
    portClient1 = new Integer(lines[4]).intValue();
    ipClient2 = lines[5];
    portClient2 = new Integer(lines[6]).intValue();
  }

  video = new Movie(this, lines[2]);
  video.frameRate(FRAME_RATE);
  video.volume(255);  // volume should be in config.txt too
  video.stop();
}

void draw() {
  if (video.available()) {              // if i'm playing the video, then i get a new frame
    video.read();
  } else {

    if (video.time() == video.duration()) {    // if I got to the end, and am the server, I restart, if not (client), I just stop.
      if (iAmServer) {
        startPlaying();
      } else {
        video.stop();
      }
    }
  }

  image(video, 0, 0); // this is actually useless. It is the "local" playing of the video 
  syphonServer.sendImage(video); // send the video to syphon
}

void startPlaying()  { // this only is run by server
  video.stop();
  video.play();
  // send remote play message
  OscMessage message = new OscMessage("/play");
  NetAddress client1 = new NetAddress(ipClient1, portClient1);
  NetAddress client2 = new NetAddress(ipClient2, portClient2);

  osc.send(message, client1);
  osc.send(message, client2);
}

void oscEvent(OscMessage theOscMessage) {  
  // print out the message
  print("OSC Message received: ");
  String message = theOscMessage.addrPattern();
  println (message);

  if (!iAmServer) {
    //if (message.equals ("play")) {  // we don't check which message it is cause we only have one type of messages,
                                      // but if we had a more sophisticated communication, we'd need to check 
    video.stop();
    video.play();
    //}
  }
}

void keyPressed() {  // the server starts with a keypress.
                    // It could start automatically, or via a osc message, or midi, or mouse, or whatever
  if (iAmServer) {
    startPlaying();
  }
}

