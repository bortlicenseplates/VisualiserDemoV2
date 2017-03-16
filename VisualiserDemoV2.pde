

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
    
    out.pushMatrix();//constrain transforms to this push/pop                        
    out.pushStyle(); //constrain styles to this push/pop
    out.fill(0, fade);  //black background with float fade as alpha channel
    out.noStroke(); //no border on bg rect
    out.rect(0,0,out.width,out.height); //background() doesn't accept alpha channel so we draw a rectagle;
    out.popStyle();
    out.popMatrix();
    
    
    out.translate(out.width/2,out.height/2);//centre canvas is now 0,0
    out.pushMatrix();//contrain transforms
    out.blendMode(SCREEN); //black is transparant
    
    out.image(threeD,-out.width/2,-out.height/2); //draw pgraphics threeD
    
    out.rotate(PI);                               //rotate canvas 180 degrees or pi radians.
                                                  //rotate(degrees(180)); does the same thing
                                                  //everything drawn so far is now flipped on x and y
    
    out.image(threeD,-out.width/2,-out.height/2); //draw same pgraphics threeD as before.
                                                  //because everything previous has been rotated
                                                  //we can draw this right way up and use default width and height
                                              
    out.popMatrix();
  out.endDraw();              //End of out's draw loop
  
  
  image(out,0,0,width, (width/16)*9);    //preview image of out in main window. handy if you want to see stuff before using syphon for live stuff
  server.sendImage(out);                 //sends out to syphon
}

void threedee(){ //separate canvase for 3d things because of background z position being 0.
                 // if we were to draw our 3d stuff on the same canvas we couldn't
                 // use a rect() funcion because our objects would just pass straight through it
                 // and be hidden by it. we can't use background either because it has no alpha channel.
  threeD.beginDraw(); 
  threeD.background(0); //this is only for this PGraphics. We still need a background
                        //but our motion blur is coming from PGraphics out and the SCREEN blendmode
  
  visuals.run(); //single function for all functions in visuals. easer on my brain;
  threeD.endDraw();
}


//Visualiser class
class Visualiser{
  float delayCount;
  ArrayList<Row> rows;  //the list of all those audio-reactive lines. Arraylist of Row classes called rows.
                        //If you don't know what an ArrayList is look it up. They're very handy.
                        
          
  Visualiser(){
    delayCount = 0;  //initialise counter
    rows = new ArrayList<Row>(); //constructing rows as an ArrayList of Row classes
  }
  
  void create(){
    if(millis() - delayCount >= del){                 //delay for constructing new Row in rows
      rows.add(new Row(threeD.width, startZ));  //constructs new row and passes in arguments
      delayCount = millis(); //set delay to current milisecond.
    }
  }
  
  void update(){ //removes dead bars.
    for (int i = 0; i < rows.size(); i++){
      rows.get(i).run();
      if((rows.get(i).alpha <= 0 || // "||" means OR
          rows.get(i).z < -10000) && // "&&" means AND
          rows.size() > 0){ //make sure there's something to remove, just in case.
        rows.remove(rows.get(i)); //remove the bar at i.
      }
    }
  }
  
  void run(){ //put all functions youwish to run in draw() in here and just call this instead.
    create();
    update();
  }
}











class Row{
  float[] gains; //array of volumes
  
  float w,pieceW,z;
  float alpha;
  float afade;
  Row(float w, float z){
    alpha = initialAlpha; // set the initial alpha to the value if inital alpha slider.
    
    this.w = w*2;//make the width double the inputted value
    
   
    
    initGains(); // function to initialise gains array
    
    pieceW = w/gains.length; //set the length of each line in the row
    this.z = z; //set initial z position
    afade = alphafade; //set fadespeed to slider value
  }
  
  void initGains(){
    gains = new float[hRez]; //set length of array to amount of bands being used
    for(int i = 0; i < gains.length; i++){
      int buf = (int)Math.floor(in.bufferSize() / gains.length) * i; //only use values at i * buffer / hRez
      gains[i] = in.mix.get(buf); //set value at i to buf;
    }
  }
  
  
  
  float volume(int freq){
    return in.mix.get(freq) * gain; //returns value at position "freq" of buffer
                                    //and multiplies it by gain slider value
  }
  
  void run(){ //everything in one function
    create();
    update();
  }
  
  void create(){
    for(int i = 0; i < gains.length-1; i++){
      threeD.pushMatrix(); threeD.pushStyle();//contain transforms and styles
        threeD.translate(w/4,0);//translate to centre
        threeD.stroke(alpha); //set stroke color to alpha
        threeD.strokeWeight(strk); //set strokeWeight to slider value
        
        // Lines are drawn from one point on the buffer to the next point on the buffer
        // using pieceW * i and get their height from gains[i]. Their z position is gotten from
        // float z, which is changed in update();
        
        //everything is drawn from the centre outwards.
        
        threeD.line( pieceW * i, threeD.height +( gains[i] * gain), z, pieceW*(i+1), threeD.height +( gains[i+1] * gain),z); //draw line from centre to left
        threeD.line(-pieceW * i, threeD.height +( gains[i] * gain), z,-pieceW*(i+1), threeD.height +( gains[i+1] * gain),z); //draw line from centre to right
      threeD.popMatrix(); threeD.popStyle();
    }
  }
  

  
  void update(){
    z-= speed; //z = z - slider value
    alpha -= alphafade; // alpha = alpha - slider value
  }
}
  








void p5setup(){ //this is called in setup() and initialises all my ui elements.
                //I could declare them all in setup() but this looks messy and ugly
                //so I use a function instead.
  
  /*
    These variable initialisations are failsafes.
    cp5s setValue() works 99% of the time, but there's always that chance it'll decide
    it hates you and wants your life to be miserable.
    I include them in p5setup() to keep setup() clean
  */
  hRez = 100;
  gain = 1000;
  fade = 255;
  alphafade = 1;
  speed = 2;
  del = 500;
  initialAlpha = 0;
  strk = 0;
  startZ = 0;
  
  //these are all sliders in controlP5. It has man other ui elements to choose from
  cp5.addSlider("hRez")
    .setPosition(10, height*0.6)
    .setSize(100, 10)
    .setRange(in.bufferSize()/10,10) //min and max values
    .setValue(50) //initial value
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