import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

import controlP5.*;
import codeanticode.syphon.*;

//Things to get
 /*
 https://processing.org/ --> To run this sketch
 http://syphon.v002.info/recorder/ --> Syphon Recorder
 http://code.compartmental.net/tools/minim/ --> Minim library
 https://github.com/Syphon/Processing --> Syphon library
 https://github.com/sojamo/controlp5 --> For interface
 */
 
ControlP5 cp5;
SyphonServer server;   //this outputs to syphon -- http://syphon.v002.info/
Minim minim;
AudioInput in;
PGraphics out;
Visualiser visuals;

float gain, fade, startZ;


int hRez, delay;
float alphafade, initialAlpha, strk;

Slider2D xypad;

void settings(){       //Has to be used for syphon in processing -- https://processing.org/reference/settings_.html
  
  size(500, 500, P2D); //size of main canvas (the control window);
  PJOGL.profile = 1;   //Needed for syphon to work.
  
}

void setup(){
  cp5 = new ControlP5(this);
  server = new SyphonServer(this, "Syphon Output"); //outputs as 'Syphon Output'. Look for this in syphon recorder or whatever else you use.
  out = createGraphics(1280,720,P3D);
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 512);
  visuals = new Visualiser();
  gain = 500;
  p5setup();
}

void draw(){
  background(20);
  out.beginDraw();
    out.background(0, fade);
    //out.translate(out.width/2, out.height/2);
    out.noStroke();
    visuals.run();;
  out.endDraw();
  image(out,0,0,width, (width/16)*9);
  server.sendImage(out);
}


float speed;

class Visualiser{
  ArrayList<Row> rows;
  int numbars;
  float margin;
  Visualiser(){
    delay = 60;
    numbars = 10;
    margin = 5;
    rows = new ArrayList<Row>();
  }
  
  void create(){
    if(frameCount % delay == 0){
      rows.add(new Row(out.width, startZ));
    }
  }
  
  void update(){
    for (int i = 0; i < rows.size(); i++){
      rows.get(i).run();
      if((rows.get(i).alpha <= 0 || 
          rows.get(i).z < -10000) && 
          rows.size() > 0){
        rows.remove(rows.get(i));
      }
    }
  }
  
  void run(){
    
    create();
    update();
  }
}











class Row{
  float[] gains;
  float w,pieceW,z;
  float alpha;
  float afade;
  float brght;
  Row(float w, float z){
    brght = initialAlpha;
    this.w = w*2;
    gains = new float[hRez];
    init();
    pieceW = w/gains.length;
    this.z = z;
    alpha = 255;
    afade = alphafade;
  }
  float volume(int freq){
    return (in.mix.get(freq)-0.5) * gain;
  }
  void run(){
    create();
    update();
  }
  
  void create(){
    out.beginShape();
    for(int i = gains.length-1; i > 0; i--){
      out.pushMatrix(); out.pushStyle();
        out.translate(w/4,0);
        out.stroke(brght - (255-alpha));
        out.strokeWeight(strk);
        out.strokeCap(ROUND);
        out.line( -pieceW * i, out.height +( gains[i] * gain), z, -pieceW*(i-1), out.height +( gains[i-1] * gain),z);
        out.line(  pieceW * i, out.height +( gains[i] * gain), z,  pieceW*(i-1), out.height +( gains[i-1] * gain),z);
        
      out.popMatrix(); out.popStyle();
    }
  }
  
  void init(){
    for(int i = 0; i < gains.length; i++){
      int buf = (int)Math.floor(in.bufferSize() / gains.length) * i;
      gains[i] = in.mix.get(buf);
    }
  }
  
  void update(){
    z-= speed;
    alpha -= alphafade;
  }
}
  








void p5setup(){ 
  cp5.addSlider("hRez")
    .setPosition(10, height*0.6)
    .setSize(100, 10)
    .setRange(in.bufferSize()/10,10)
    .setValue(50)
    ;
  
  cp5.addSlider("gain")
    .setPosition(10, height*0.6+30)
    .setSize(100, 10)
    .setRange(0,1000)
    .setValue(1000)
    ;
    
  cp5.addSlider("fade")
    .setPosition(10, height*0.6 + 60)
    .setSize(100, 10)
    .setRange(0,255)
    .setValue(255)
    ;
    
  cp5.addSlider("alphafade")
    .setPosition(10, height*0.6 + 90)
    .setSize(100, 10)
    .setRange(0,2)
    .setValue(1)
    ;
    
  cp5.addSlider("speed")
    .setPosition(10, height*0.6 + 120)
    .setSize(100, 10)
    .setRange(1,10)
    .setValue(2)
    ;
    
    
    
  cp5.addSlider("delay")
    .setPosition(200, height*0.6)
    .setSize(100, 10)
    .setRange(20,240)
    .setValue(60)
    ;
    
  cp5.addSlider("initialAlpha")
    .setPosition(200, height*0.6 + 30)
    .setSize(100, 10)
    .setRange(0,255)
    .setValue(0)
    ;
    
  cp5.addSlider("strk")
    .setPosition(200, height*0.6 + 60)
    .setSize(100, 10)
    .setRange(0,10)
    .setValue(0)
    ;
    
  cp5.addSlider("startZ")
    .setPosition(200, height*0.6 + 90)
    .setSize(100, 10)
    .setRange(-50,50)
    .setValue(0)
    ;
}