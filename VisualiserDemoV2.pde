

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
PGraphics threeD; // seperate PGraphics for 3D to allow background trails;
PGraphics out;    // main output PGraphics;
Visualiser visuals;

float gain, fade, startZ, speed, del;


int hRez;
float alphafade, initialAlpha, strk;

void settings(){       //Has to be used for syphon in processing -- https://processing.org/reference/settings_.html
  
  size(500, 500, P2D); //size of main canvas (the control window);
  PJOGL.profile = 1;   //Needed for syphon to work.
  
}

void setup(){
  cp5 = new ControlP5(this);
  server = new SyphonServer(this, "Syphon Output"); //outputs as 'Syphon Output'. Look for this in syphon recorder or whatever else you use.
  threeD = createGraphics(1280,720,P3D);
  out = createGraphics(1280,720,P2D); //Size of output and renderer
  minim = new Minim(this);                          //Minim constructor
  in = minim.getLineIn();          //line in options (Stereo, buffersize is 512)
  visuals = new Visualiser();                       //Construct visualiser                         
  p5setup();                                        //UI element setup function. Check bottom of page

}

void draw(){
  //stuff prefixed with "out" is going to syphon and the preview window. 
  //everything else has no prefix
  background(20);
  threedee();
  out.beginDraw();            //since out is it's own PGraphics it needs its own draw loop.
                              //For longer loops or multiple PGraphics I usually 
                              //do something like this to keep thing tidy:
                               /*
                                  void draw(){
                                    [code]
                                    ...
                                    outDraw();
                                    ...
                                    [more code]
                                  }
                                  void outDraw(){
                                    out.beginDraw();
                                    .....
                                    your code goes here
                                    .....
                                    out.endDraw();
                                  }
                               */
                               
                               
  //Blend modes are a key part of processing and digital art.\\
 //Learn to use them and your life will be inifinitely easier.\\
                          
    out.blendMode(BLEND); // default blendmode
    out.pushMatrix();                           
    out.pushStyle();
    
    
    out.fill(0, fade);  //black background with float fade as alpha channel
    out.rect(0,0,out.width,out.height);
    out.noStroke();
    out.popStyle();
    out.popMatrix();
    out.translate(out.width/2,out.height/2);
    out.pushMatrix();
    out.blendMode(SCREEN); //black is transparant
    out.image(threeD,-out.width/2,-out.height/2);
    out.rotate(PI);
    out.image(threeD,-out.width/2,-out.height/2);
    out.popMatrix();
  out.endDraw();              //End of out's draw loop
  image(out,0,0,width, (width/16)*9);    //preview image of out in main window. handy if you want to see stuff before using syphon for live stuff
  server.sendImage(out);                 //sends out to syphon
}

void threedee(){
  threeD.beginDraw();
  threeD.background(0);
  visuals.run(); //single function for all functions in visuals. easer on my brain;
  threeD.endDraw();
}


//Visualiser class
class Visualiser{
  float delayCount, cDelay;
  ArrayList<Row> rows;  //the list of all those audio-reactive lines. Arraylist of Row classes called rows.
                        //If you don't know what an ArrayList is look it up. They're very handy.
                        
  int numbars;          //number of bars
          
  Visualiser(){
    delayCount = 0;
    numbars = 10;
    rows = new ArrayList<Row>(); //constructing rows as an ArrayList of Row classes
    cDelay = del;
  }
  
  void create(){
    if(millis() - delayCount >= del){                 //delay for constructing new Row in rows
      rows.add(new Row(threeD.width, startZ));  //constructs new row and passes in arguments
      delayCount = millis();
      //println("delay: " + delay);
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
    threeD.beginShape();
    for(int i = gains.length-1; i > 0; i--){
      threeD.pushMatrix(); threeD.pushStyle();
        threeD.translate(w/4,0);
        threeD.stroke(brght - (255-alpha));
        threeD.strokeWeight(strk);
        threeD.strokeCap(ROUND);
        threeD.line( -pieceW * i, threeD.height +( gains[i] * gain), z, -pieceW*(i-1), threeD.height +( gains[i-1] * gain),z);
        threeD.line(  pieceW * i, threeD.height +( gains[i] * gain), z,  pieceW*(i-1), threeD.height +( gains[i-1] * gain),z);
        
      threeD.popMatrix(); threeD.popStyle();
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
  
  /*
    These variable initialisations are failsafes.
    cp5s setValue() doesn't initialise variables, it just sets the default value on the ui element;
    I include them in my p5Setup function to keep everything clean;
  */
  hRez = 50;
  gain = 1000;
  fade = 255;
  alphafade = 1;
  speed = 2;
  del = 500;
  initialAlpha = 0;
  strk = 0;
  startZ = 0;
  
  
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
    .setRange(0,5)
    .setValue(1)
    ;
    
  cp5.addSlider("speed")
    .setPosition(10, height*0.6 + 120)
    .setSize(100, 10)
    .setRange(1,10)
    .setValue(2)
    ;
    
    
    
  cp5.addSlider("del")
    .setLabel("DELAY")
    .setPosition(200, height*0.6)
    .setSize(100, 10)
    .setRange(10,4000)
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