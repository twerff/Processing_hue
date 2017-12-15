/**
 * Hue Workshop Server
 *
 * Created by Serge Offermans (s.a.m.offermans@tue.nl)
 * Intelligent Lighting Institute (ILI), Eindhoven University of Technology
 *
 * Contributions by Remco Magielse and Dzmitry Aliakseyeu
**/

// Include Networking things required for the hue
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.impl.client.DefaultHttpClient;
import java.io.*;
import java.awt.*;
import java.lang.Object.*;
import java.util.Date;

/* EDIT THIS TO MATCH YOUR HUE BRIDGE */
final static String HUE_KEY = "dmD3ZsTttT0U5Y0fXWL-lT23Ys6hInCrSIoAyCe5";
final static String HUE_IP  = "192.168.1.101";

PFont font;

void setup()
{
  //setup stage
  size(800, 600);

  // Set up the hue  
  setupHue();
  
  // Set up a font so you can display some values on screen
  font = loadFont("Aharoni-Bold-24.vlw");
  textFont(font, 24);
  smooth();
  
  //  Draw a colorgrid on the screen if you like  
  colorMode(HSB,width,height,255);
  for(int i = 0; i < width; i++)
  {
    for(int j = 0; j < height; j++)
    {
      stroke(i,j,255);
      point(i,j);
    }
  }
  colorMode(RGB);
}

/**
*  You can do whatever you like, (or dislike) in this code. No questions asked.
**/
void draw()
{
//  background(0);
//  This is the continuous loop

  
}

//sends stage colour to the hue lamps
void mousePressed()
{
  int h = int( map(mouseX, 0, width, 0, 255));
  int s = int( map(mouseY, 100, height, 0, 255));
  // Send hue and saturation to lamp 1, 2, 3 
  sendHSBToHue(1, h, s, 120);
  sendHSBToHue(2, h, s, 120);
  sendHSBToHue(3, h, s, 120);
}

void keyPressed()
{
  if (key == 'a')
  {
    sendHSBToHue(1, 190, 255, 255);
    sendHSBToHue(2, 50, 255, 255);
    sendHSBToHue(3, 230, 255, 255);
  }
  if (key == 'b')
  {
    sendCTToHue(1, 0);
    sendCTToHue(2, 0);
    sendCTToHue(3, 255);
  }
  if (key == 'c')
  {
    sendCTToHue(1, 255);
    sendCTToHue(2, 255);
    sendCTToHue(3, 255);
  }
  if (key == 'd')
  {
    sendHSBToHue(1, 0, 255, 60);
    sendHSBToHue(2, 10, 255, 40);
    sendCTParametersToHue(3, 150, 255);
  }
  if (key == 'f')
  {
    sendHSBToHue(1, 0, 255, 100);
    sendHSBToHue(2, 240, 255, 100);
    sendCTParametersToHue(3, 50, 255);
  }
  if (key == 'o')
  {
    sendBrightnessToHue(1, 0);
    sendBrightnessToHue(2, 0);
    sendBrightnessToHue(3, 0);
  }
}