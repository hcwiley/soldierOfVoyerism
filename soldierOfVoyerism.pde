//import codeanticode.gsvideo.*;
import processing.video.*;
import oscP5.*;
import netP5.*;
import ddf.minim.*;
import peasy.*;
import java.util.Vector;
import toxi.geom.*;
//Image - Camera - Extrusion stuff
PImage extrude;
int[][] values;
float angle = 0;
boolean record = false;
int lower=0, upper=255;
Capture capture;
Minim minim;
AudioInput player;
//PeasyCamera
float scal = 2.5;
PVector rot = new PVector();
PVector tran = new PVector(-100, -100, 0);
PeasyCam cam;
Vec3D globalOffset, avg, cameraCenter;
float camD;
float camDMax;
float camDMin;
//Touch OSC
OscP5 oscMain;
int volumeAffect;
int mainP5;
OscP5 oscWalker;
int walkerP5;
boolean useAccl = false;
boolean useWalk = false;
boolean useAudio = true;
boolean useLines = false;
//Block stuff
int blockDelta = 5;

void setup() {
  size(1200, 800, P3D);
  println("captures: "+Capture.list()[0]);
  capture = new Capture(this, 320, 240, 24);
//  capture.start();
  extrude = new PImage(320, 240);
  values = new int[extrude.width][extrude.height];
  updateExtrude();
  frameRate(15);
  scale(3.5);

  minim = new Minim(this);
  player = minim.getLineIn(Minim.STEREO, 256);

  /* start oscp5, listening for incoming messages at port 8000 */
  oscMain = new OscP5(this, 8001);
  oscWalker = new OscP5(this, 8002);
  camD = 200;
  camDMax = 500;
  camDMin = 0;
  cam = new PeasyCam(this, camD);
  cam.setDistance(camD);
  cam.setMinimumDistance(camDMin);
  cam.setMaximumDistance(camDMax);
  cameraCenter = new Vec3D();
  avg = new Vec3D();
  globalOffset = new Vec3D(0, 0, 0);
}

void oscEvent(OscMessage theOscMessage) {
  if (mainP5 == 0)
    mainP5 = parseInt(theOscMessage.toString().split(":")[1].split(" ")[0]);
  else if (walkerP5 == 0)
    walkerP5 = parseInt(theOscMessage.toString().split(":")[1].split(" ")[0]);
  String addr = theOscMessage.addrPattern();

  if (addr.equals("/1/blockDelta")) {
    float  val  = theOscMessage.get(0).floatValue();
    blockDelta = (int)map(val, 0, 1, 1, 30);
  }
  else if (addr.equals("/1/useAudio")) {
    useAudio = !useAudio;
  }
  else if (addr.equals("/1/fader3")) {
    float  val  = theOscMessage.get(0).floatValue();
    volumeAffect = (int)map(val, 0, 1, 0, 100);
  }
  else if (addr.equals("/1/toggle1")) {
    useWalk = !useWalk;
    println("useWalk:" + useWalk);
  }
  else if (addr.equals("/1/toggle3")) {
    useLines = !useLines;
    println("useLines:" + useLines);
  }
  else if (addr.equals("/2/useAccl")) {
    useAccl = !useAccl;
    println("useAccl:" + useAccl);
  }
  else if (addr.equals("/2/distance")) {
    float  val  = theOscMessage.get(0).floatValue();
    camD = map(val, 0, 1, camDMin, camDMax);
  }
  else if (addr.equals("/accxyz")) {
    //    if(theOscMessage.get
    int sender = parseInt(theOscMessage.toString().split(":")[1].split(" ")[0]);
    float x = theOscMessage.get(0).floatValue();
    float y = theOscMessage.get(1).floatValue();
    float z = theOscMessage.get(2).floatValue();
    if (sender == mainP5) {
      if (useAccl) {
        if ( abs(x) > .1)
          rot.x += map(x, -10, 10, -1, 1);
        if ( abs(y) > .1)
          rot.z += map(y, -10, 10, -1, 1);
//        if ( abs(z) > .1)
//          rot.y += map(z, -10, 10, -1, 1);
        //      println(rot);
      }
    }
    else if(useWalk){
      if ( abs(y) > 3)
        tran.x += map(y, -10, 10, -100, 100);
      if ( abs(z) > 3)
        tran.z += map(x, -10, 10, -100, 100);
//      println(x+","+y+","+z);
    }
  }
  else if (addr.equals("/2/xy")) {
    float y = theOscMessage.get(0).floatValue();
    float x = theOscMessage.get(1).floatValue();
    tran.x = map(x, 0, 1, -500, 500);
    tran.y = map(y, 0, 1, 500, -500);
  }
  else if (addr.equals("/2/z")) {
    float  val  = theOscMessage.get(0).floatValue();
    tran.z = map(val, 0, 1, -500, 500);
  }
  else {
    //    println(addr);
  }
}

void updateExtrude() {
  // Load the image into a new array
  if (capture.available() == true) {
    capture.read();
    extrude = capture;
    extrude.loadPixels();
    for (int x = 0; x < extrude.width; x++) {
      for (int y = 0; y < extrude.height; y++) {
        color pixel = extrude.get(x, y);
        values[x][y] = int(brightness(pixel));
      }
    }
  }
}

void draw() {
  updateExtrude();
  cam.rotateX(rot.x);
  rot.x = 0;
  cam.rotateY(rot.y);
  rot.y = 0;
  cam.rotateY(rot.z);
  rot.z = 0;
  cam.setDistance(camD);
  translate(tran.x, tran.y, tran.z);
  if (record) {
    println("writing file");
    //    beginRaw(DXF, "points.dxf");
    beginRaw("superCAD.ObjFile", "points.obj");
  }
  background(0);

  // Display the image mass
  int buf = 0;
  for (int x = 0; x < extrude.width; x+=blockDelta) {
    for (int y = 0; y < extrude.height; y+=blockDelta) {
      if (buf < player.bufferSize() - 1 ) {
        buf++;
      }
      else {
        buf = 0;
      }
      //      if (values[x][y] > lower && values[x][y] < upper) {
      //        continue;
      //      }
      //      stroke(values[x][y]);
      //      point(x, y, -values[x][y]);
      int rightChannel = 0;
      if (useAudio)
        rightChannel = (int)map((float)player.right.get(buf)*volumeAffect, -1, 1, 0, 30);
      if(useLines)
        beginShape(LINES);
      else
        beginShape(QUADS);
      drawCube(x, y, -values[x][y], blockDelta, rightChannel, values[x][y]);
      endShape();
    }
  }
  if (record) {
    endRaw();
    record = false;
  }
}

void keyPressed() {
  if (key == 'd') {
    println("pressed d, bout to write");
    record = true;
  }
  if (key=='q')
    lower++;
  if (key=='a')
    lower--;
  if (key=='w')
    upper++;
  if (key=='s')
    upper--;
  if (key==' ') {
    updateExtrude();
  }
  if(key=='=')
    volumeAffect += 5;
  if(key=='-')
    volumeAffect -= 5;
}
void drawCube(float x, float y, float z, float r, int blockSpacing, color col) {
  fill(col);
  // face 1
  stroke(col);
  vertex(x, y, z);
  vertex(x, y - r, z);
  vertex(x - r, y - r, z);
  vertex(x - r, y, z);
  // face 2
  //        fill(color);
  vertex(x - r, y + blockSpacing, z);
  vertex(x - r, y + blockSpacing, z - r);
  vertex(x, y + blockSpacing, z - r);
  vertex(x, y + blockSpacing, z);
  // face 3
  //        fill(color);
  vertex(x - r, y, z - r - blockSpacing);
  vertex(x - r, y - r, z - r - blockSpacing);
  vertex(x, y - r, z - r - blockSpacing);
  vertex(x, y, z - r - blockSpacing);
  // face 4
  //        fill(color);
  vertex(x - r, y - r - blockSpacing, z);
  vertex(x - r, y - r - blockSpacing, z - r);
  vertex(x, y - r - blockSpacing, z - r);
  vertex(x, y - r - blockSpacing, z);
  // face 5
  //        fill(color);
  vertex(x - r - blockSpacing, y, z);
  vertex(x - r - blockSpacing, y, z - r);
  vertex(x - r - blockSpacing, y - r, z - r);
  vertex(x - r - blockSpacing, y - r, z);
  // face 6
  //        fill(color);
  vertex(x + blockSpacing, y, z);
  vertex(x + blockSpacing, y, z - r);
  vertex(x + blockSpacing, y - r, z - r);
  vertex(x + blockSpacing, y - r, z);
  //    endShape();
}
void stop() {
  // always close Minim audio classes when you are done with them
  player.close();
  // always stop Minim before exiting
  minim.stop();
  super.stop();
}

