// Special thanks to Aaron Sherwood, Michael Shiloh and Joaquín Kunkel 
// for their help with this project

// boid positions and flock 
Flock flock;
float xPos0, xPos1, xPos2;

// optical effects
boolean sharpen0, sharpen1, sharpen2  = false;

int a = -1;
int e = 9;
float sharpen[][] = {
  {a, a, a}, 
  {a, e, a}, 
  {a, a, a}
};

float sobelX[][] = {
  {1, 0, -1}, 
  {2, 0, -2}, 
  {1, 0, -1}
};

float sobelY[][] = {
  {1, 2, 1}, 
  {0, 0, 0}, 
  {-1, -2, -1}
};

float scharrX[][] = {
  {3, 0, -3}, 
  {10, 0, -10}, 
  {3, 0, -3}
};

float scharrY[][] = {
  {3, 10, 3}, 
  {0, 0, 0}, 
  {-3, -10, -3}
};

int w = 100;
float matrix[][] = sharpen;
float pictureAlpha=0;

// Camera
import processing.video.*;
Capture cam;
boolean takePicture = false;

// Audio
import processing.sound.*;
SoundFile file;

void setup() {
  size(1280, 720); //size of the sketch to match the camera size

  //initializing camera
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[0]);
    cam.start();
  }     

  // Create flock
  flock = new Flock();
  for (int i = 0; i < 3; i++) {
    Boid b = new Boid(width/2, height/2);
    flock.addBoid(b);
  }

  // Load audio from the /data folder of the sketch 
  file = new SoundFile(this, "snap.wav");
  textSize(20);
}

void draw() {
  flock.run();
  
  if (cam.available() == true) {
    cam.read();
  }
  
  // so let's set the whole image as the background first
  image(cam, 0, 0);
  processImage(matrix);

  // Takes the picture when the boolean is declared true by pressing space bar
  if (takePicture) {
    String filename = day()+"_"+month()+"_"+year()+"_"+hour()+"_"+minute()+"_"+second();
    save(filename + ".png");
    takePicture=false;
  }

// Instructions!
  text("Use the UP and DOWN arrows to change the size of the effect", 50, 50);
  text("Use the 1, 2, 3 key to change the effect", 50, 80);
  text("Use the R key to reset the effect", 50, 110);
  text("Use the SPACEBAR to snap a pic", 50, 140);

// Map the position of the boids
  xPos0 = map(flock.boids.get(0).position.x, 0, 800, -100, 100);  
  xPos1 = map(flock.boids.get(1).position.x, 0, 800, -5, .5);
  xPos2 = map(flock.boids.get(2).position.x, 0, 800, -20, 20);

// Effects that modify kernel values
  if (sharpen0 == true) {
    sharpen[0][0] += noise(xPos0)*0.01;
    textSize(20);
    text("Mode 1", width - 100, 50);
  }  
  if (sharpen1 == true) {
    sharpen[0][1] += xPos1*0.01;
    textSize(20);
    text("Mode 2", width - 100, 80);
  }  
  if (sharpen2 == true) {
    sharpen[0][2] *= xPos2*0.001;
    println("sharpen02: " + sharpen[0][2]); 
    textSize(20);
    text("Mode 3", width - 100, 110);
  }

  // Camera flash
  pushStyle();
  fill(255, pictureAlpha);
  noStroke();
  pictureAlpha-=5;
  rect(0, 0, width, height);
  popStyle();
}

void processImage(float matrix[][]) {
  // In this example we are only processing a section of the image
  int xstart = constrain(mouseX-w/2, 0, cam.width);
  int ystart = constrain(mouseY-w/2, 0, cam.height);
  int xend = constrain(mouseX + w/2, 0, cam.width);
  int yend = constrain(mouseY + w/2, 0, cam.height-1);
  //println(cam.width+ " "+cam.height);
  int matrixsize = 3;

  loadPixels();
  cam.loadPixels();
  for (int x = xstart; x < xend; x++) {
    for (int y = ystart; y < yend; y++) {
      // Each pixel location (x,y) gets passed into a function called convolution()
      // The convolution() function returns a new color to be displayed.
      color result = convolve(x, y, matrix, matrixsize, cam);
      int loc = (x + y * cam.width);
      pixels[loc] = result;
    }
  }
  updatePixels();
}

color convolve(int x, int y, float matrix[][], int matrixsize, PImage cam) {
  float rtotal = 0.0;
  float gtotal = 0.0;
  float btotal = 0.0;
  int offset = floor(matrixsize / 2);

  // Loop through convolution matrix
  for (int i = 0; i < matrixsize; i++) {
    for (int j = 0; j < matrixsize; j++) {
      // What pixel are we testing
      int xloc = x + i - offset;
      int yloc = y + j - offset;
      int loc = xloc + cam.width * yloc;

      // Make sure we haven't walked off the edge of the pixel array
      // It is often good when looking at neighboring pixels to make sure we have not gone off the edge of the pixel array by accident.
      loc = constrain(loc, 0, cam.pixels.length - 1);
      // Calculate the convolution
      // We sum all the neighboring pixels multiplied by the values in the convolution matrix.
      rtotal += red(cam.pixels[loc]) * matrix[i][j];
      gtotal += green(cam.pixels[loc]) * matrix[i][j];
      btotal += blue(cam.pixels[loc]) * matrix[i][j];
    }
  }


  //*WRAP*
  //Values that exceed the limits are wrapped around 
  //to the opposite limit with a modulo operation. 
  //(256 wraps to 0, 257 wraps to 1, 
  //and -1 wraps to 255, -2 wraps to 254, etc.)

  //rtotal
  if (rtotal > 255) {
    rtotal = rtotal % 255;
  } else if (rtotal < 0) {
    rtotal = (rtotal % 255) + 255;
  }
  //gtotal
  if (gtotal > 255) {
    gtotal = gtotal % 255;
  } else if (gtotal < 0) {
    gtotal = (gtotal % 255) + 255;
  }
  //btotal
  if (btotal > 255) {
    btotal = btotal % 255;
  } else if (btotal < 0) {
    btotal = (btotal % 255) + 255;
  }

  // Return an array with the three color values
  return color(rtotal, gtotal, btotal);
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      w += 100;
    } else if (keyCode == DOWN) {
      w -= 100;
    }
  }
}

void reset() {
  // Resets the three effects back to the original values
  sharpen[0][0] = a;
  sharpen[0][1] = a;
  sharpen[0][2] = a;
  // Considers every case to return them to the original state 
  if (sharpen0 == true) {
    sharpen0 = false;
  }
  if (sharpen1 == true) {
    sharpen1 = false;
  }
  if (sharpen2 == true) {
    sharpen2 = false;
  }
}

void snapPic() {
  file.play();
  takePicture=true;
  pictureAlpha=255;
}


void keyTyped() {
  // Toggle switch so the user can manually choose which effects to use
  if (key == '1') {
    sharpen0 = !sharpen0;
  } else if (key == '2') {
    sharpen1 = !sharpen1;
  } else if (key == '3') {
    sharpen2 = !sharpen2;
  } else if (key == 'r') { // Reset key
    reset();
  } else if (key == ' ') { // Picture
    snapPic();
  }
}