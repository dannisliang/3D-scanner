import processing.video.*;
import processing.serial.*;

//objects
PFont f;
Capture video;
Serial myPort;
PrintWriter output;

//colors
color black=color(0);
color white=color(255);

//variables
int iteration; //iteration
float pixBright;
// float maxBright=70; // brightness() reports highest of RGB, from 0-255 . This needs to be autotuned but I see that 70 works well for now.
int maxBrightPos=0;
int prevMaxBrightPos;
int cntr=1;
int row;
int col;

//scanner parameters
float pics_per_rev = 120;  //number of phases profiling per revolution
float angle_laser_camera = 66*PI/360;  //angle between laser and camera [radian]
float angle_per_step = 2*PI/pics_per_rev;  //angle between 2 profiles [radian]
float vertical_camera_angle = PI/3 ; // vertical angle of camera incident to turntable [radian]
float turntable_center = 250 ;  // This defines the column which the center of the turntable is

//coordinates
float x, y, z;  //cartesian cords., [milimeter]
float ro;  //first of polar coordinate, [milimeter]
float fi; //second of polar coordinate, [radian]
float b; //distance between brightest pixel and middle of photo [pixel]
float pxmmpoz = 5; //pixels per milimeter horizontally 1px=0.2mm
float pxmmpion = 5; //pixels per milimeter vertically 1px=0.2mm

//================= CONFIG ===================

void setup() {
  size(640, 480);
  strokeWeight(1);
  smooth();
  background(0);
 
  //fonts
  f=createFont("Arial",16,true);
   
  //video conf.
  video = new Capture(this, width, height);
  video.start();
 
  //Serial (COM) conf.
  println(Serial.list());
  myPort=new Serial(this, Serial.list()[0], 9600);
//  myPort.write('L');
  
  //output file
  output=createWriter("pointcloud.asc");  //the pointcloud gets outputted to pointcloud.asc
  
}

//============== MAIN PROGRAM =================

void draw() {

  video.read();
  image(video, 0, 0, width, height);
  video.loadPixels();
  delay(2000);
  for (iteration=0;iteration<pics_per_rev;iteration++) {
    video.read();
    image(video, 0, 0, width, height);
    video.loadPixels();
    for (int n=0;n<video.width*video.height;n++){
        video.pixels[n]=video.pixels[n];
        }
    video.updatePixels();
    set(20,20,video);
    String file_name="raw_image-"+nf(iteration+1, 3)+".png";
    video.save(file_name);
    turn_platter();
    
      }
    
  turn_platter();
  line_processor();
  noLoop(); 
}

//============== Line Calculator =================


void line_processor(){
  for (iteration=0; iteration<pics_per_rev; iteration++){
   
    String file_name="raw_image-"+nf(iteration+1, 3)+".png";
    PImage scan=loadImage(file_name);                          //This loads the images we just collected
    String file_name2="line_image-"+nf(iteration+1, 3)+".png";
    PImage line_image=createImage(scan.width, scan.height, RGB);
    scan.loadPixels();
    line_image.loadPixels();
    int currentPos;
    fi=iteration*angle_per_step;
    println(fi);

    for(row=0; row<scan.height; row++){  //starting row analysis
    maxBrightPos=0;
    float maxBright = 70; // have to set this down here, no clue why
      for(col=0; col<scan.width; col++){
        currentPos = row * scan.width + col;
        pixBright=green(scan.pixels[currentPos]);
        if(pixBright>maxBright){
          maxBright=pixBright;
          maxBrightPos=currentPos;
        }
        line_image.pixels[currentPos]=black; //setting all pixels black
      }
     
      line_image.pixels[maxBrightPos]=white; //setting brightest pixel white
     
      b=( ( (maxBrightPos+1-row*scan.width)-turntable_center)/cos(vertical_camera_angle) ) /pxmmpoz;
      ro=(b/sin(angle_laser_camera));
      //output.println(b + ", " + prevMaxBrightPos + ", " + maxBrightPos); //I used this for debugging
     
      x=ro * cos(fi);  //changing polar coords to cartesian
      y=ro * sin(fi);
      z=row ;
     
      if( (ro>=-30) && (ro<=60) ){ //printing coordinates
        output.println(x + "," + y + "," + z);
      }
     
    }//end of row analysis
   
    line_image.updatePixels();
    line_image.save(file_name2);
   
  }
  output.flush();
  output.close();
}



void turn_platter() {  //sending command to turn
  myPort.write('F');
  int finish = 0 ;   // Serves as the delay. Arduino sens period when stepper command is done.
    while (finish != '.' ) {
          finish = myPort.read(); }
  }
  

