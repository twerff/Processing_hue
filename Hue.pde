
// Hue objects
HueHub hub;          // the hub
HueLight[] hueLamps; // light instances

int NUM_HUE_LAMPS = 3;

int getArrayPostionByID( int id )
{
  int pos = 0;
  boolean foundID = false;
  for(int i = 0; i < hueLamps.length; i++)
  {
    if(hueLamps[i].id == id)
    {
      pos = i;
      foundID = true;
      break;
    }
  }
  if (!foundID) { println("\tERROR: Lamp ID not found!!! Using the first available lamp instead..."); }
  return pos;
}

void setupHue() 
{
 // init for hub/lights
  hub = new HueHub();  
  hueLamps = new HueLight[NUM_HUE_LAMPS];
  for (int i = 0; i < NUM_HUE_LAMPS; i++)
  {
    hueLamps[i] = new HueLight(i+1, hub);
    hueLamps[i].turnOn(); // Turn all lamps on
  }
}

void sendRGBToHue( int id, int r,  int g,  int b) 
{
  color rgbCol = color(r,g,b);
  colorMode(HSB, 255);
  int h = int(hue       (rgbCol));
  int s = int(saturation(rgbCol));
  int br= int(brightness(rgbCol));
  sendHSBToHue(id, h, s, br);
  colorMode(RGB, 255);
}

void sendHSBToHue( int id, int h,  int s,  int b) 
{
  try
  {
    int finalHue = int( map( h, 0, 255, 0, 65532 ) );
    int arrayPos = getArrayPostionByID(id);
    hueLamps[arrayPos].setHsb(finalHue, byte(s), byte(b));
  }
  catch(Exception e)
  {
    println(e);
    println("Did you use the correct Hue lamp ID?");
  }
}

void sendCTToHue(int id, int ct)
{
  int finalCT = int( map( ct, 0, 255, 500, 153 ) );
  int arrayPos = getArrayPostionByID(id);
  hueLamps[arrayPos].setCT(finalCT);
//  hueLamps[arrayPos].update();
}

void sendCTParametersToHue(int id, int ct, int bri)
{
  int finalCT = int( map( ct, 0, 255, 500, 153 ) );
  int arrayPos = getArrayPostionByID(id);
  hueLamps[arrayPos].setCTParameters(finalCT, byte(bri));
//  hueLamps[arrayPos].update();
}


void sendHueToHue(int id, int h)
{
  int finalHue = int( map( h, 0, 255, 0, 65532 ) );
  int arrayPos = getArrayPostionByID(id);
  hueLamps[arrayPos].setHue(finalHue);
//  hueLamps[arrayPos].update();
}

void sendBrightnessToHue(int id, int b)
{
  int arrayPos = getArrayPostionByID(id);
  hueLamps[arrayPos].setBrightness(byte(b));
//  hueLamps[arrayPos].update();
}

void sendSaturationToHue(int id, int s)
{
  int arrayPos = getArrayPostionByID(id);
  hueLamps[arrayPos].setSaturation(byte(s));
//  hueLamps[arrayPos].update();
}

class HueHub {
  private static final String KEY = HUE_KEY; // "secret" key/hash
  private static final String IP = HUE_IP; // ip address of the hub
  private static final boolean ONLINE = true; // for debugging purposes, set to true to allow communication

  private DefaultHttpClient httpClient; // http client to send/receive data

  // constructor, init http
  public HueHub() {
    httpClient = new DefaultHttpClient();
  }

  // Query the hub for the name of a light
  public String getLightName(HueLight light) {
    // build string to get the name,   
    return "noname";
  }

  // apply the state for the passed hue light based on the values
  public void applyState(HueLight light) { 
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    try {
      // format url for specific light
      StringBuilder url = new StringBuilder("http://");
      url.append(IP);
      url.append("/api/");
      url.append(KEY);
      url.append("/lights/");
      url.append(light.getID());
      url.append("/state");
      // get the data from the light instance
//      String data = light.getData();
//      String data = light.getXYData();
      String data = light.getLightData();
      StringEntity se = new StringEntity(data, "ISO-8859-1");     
      se.setContentType("application/json");
      HttpPut httpPut = new HttpPut(url.toString());            
      httpPut.addHeader("Accept", "application/json");                  // tell everyone we are talking JSON
      httpPut.addHeader("Content-Type", "application/json");
               
      // debugging
//      println(url);
      println(light.getID() + "->" + data);

      //with post requests you can use setParameters, however this is
      //the only way the put request works with the JSON parameters
      httpPut.setEntity(se);
      println( "executing request: " + httpPut.getRequestLine() );
      println("");

      // sending data to url is only executed when ONLINE = true
      if (ONLINE) { 
        HttpResponse response = httpClient.execute(httpPut);
        HttpEntity entity = response.getEntity();
        
        if (entity != null) {
          // only check for failures, eg [{"success":
          entity.writeTo(baos);
          if (!baos.toString().startsWith("[{\"success\":")) println("error updating"); 
          println(baos.toString());
        }
        // needs to be done to ensure next put can be executed and connection is released
        if (entity != null) entity.consumeContent();
      }
    } 
    catch( Exception e ) { 
      e.printStackTrace();
    }
  }

  // close connections and cleanupp
  public void disconnect() {
    // when HttpClient instance is no longer needed, 
    // shut down the connection manager to ensure
    // deallocation of all system resources
    httpClient.getConnectionManager().shutdown();
  }
}

// Hue class; one instance represents a lamp which is addressed using number
class HueLight {
  private int id; // lamp number/ID as known by the hub, e.g. 1,2,3
  // light variables
  private int hue = 30000; // hue value for the lamp
  private int saturation = 255; // saturation value
  private int brightness = 255; // brightness
  private int ct = 300; // range 153 - 500
  
//  private boolean updateOn = false;
//  private boolean updateBri = false;
//  private boolean updateHue = false;
//  private boolean updateSat = false;
//  private boolean updateXY = false;
//  private boolean updateCt = false;
//  private boolean updateTransition = false;

  static final int ON   = 0;
  static final int BRI  = 1;
  static final int XY   = 2;
  static final int CT   = 3;
  static final int TRANS= 4;

  private boolean[] updates = { false, false, false, false, false }; // on, bri, xy, ct, transition

  private boolean lightOn = false; // is the lamp on or off, true if on?
  private byte transitiontime = 8; // transition time, how fast  state change is executed -> 1 corresponds to 0.1s
  
  // hub variables
  private HueHub hub; // hub to register at
  private String name = "noname"; // set when registering the lamp with the hub
  // graphic settings
  private byte radius = 80; // size of the ellipse drawn on screen
  private int x; // x position on screen
  private int y; // y position on screen
  // control variables
  private float damping = 0.9; // control how fast dim() impacts brightness and lights turn off
  private float flashDuration = 0.2; // in approx. seconds
  

  // constructor, requires light ID and hub
  public HueLight(int lightID, HueHub aHub) {
    id = lightID;
    hub = aHub;
    // check if registered, get name [not implemented]
    name = hub.getLightName(this);
  }

  // set the hue value; if outside bounds set to min/max allowed
  public void setHue(int hueValue) 
  {
    hue = int(hueValue);
    hue = constrain(hueValue, 0, 65532);
    updates[XY] = true;
    this.update();
  }
  
  // set the hue value; if outside bounds set to min/max allowed
  public void setCT(int ctValue) 
  {
    ct = constrain(ctValue, 153, 500);
    updates[CT] = true;
    this.update();
  }
  
  public void setCTParameters(int ctValue, byte bri) 
  {
    ct = constrain(ctValue, 153, 500);
    updates[CT] = true;
    this.setBrightness(bri); // also calls teh udpate;
//    brightness = int(bri);
//    updates[BRI] = true;
//    this.update();
  }
  
  

  // set the brightness value, max 255
  public void setBrightness(byte bri) 
  {
    brightness = int(bri);
    // Because the hue works with minimum brightness at 0; we have to turn it off manually at brightness 0
    println("this.lightOn = " + this.lightOn );
    
    if(brightness == 0)
    {
      println("Turning light OFF for lamp ID " + id);
      this.lightOn = false;
      updates[ON] = true;
      this.update();
    }
    else if (!this.lightOn) // if bri > 0 and we are not on; turn it on as well!
    {
      println("Turning light on for lamp ID " + id);
      this.lightOn = true;
      updates[ON] = true;
      
      brightness = int(bri);
      updates[BRI] = true;
      this.update();
    }
    else
    {
      brightness = int(bri);
      updates[BRI] = true;
      this.update();
    }
  }

  // set the saturation value, max 255
  public void setSaturation(byte sat) 
  {
    saturation = int(sat);
    updates[XY] = true;
    this.update();
  }
  
  // set the HSB
  public void setHsb(int hueValue, byte sat, byte bri) {
    hue = int(hueValue);
    hue = constrain(hueValue, 0, 65532);
    saturation = int(sat);
    updates[XY] = true;
    this.setBrightness(bri); // also calls teh udpate;
  }

  // set the tranistion time; 1 = 0.1sec (not sure if there is a max)
  public void setTransitiontime(byte transTime) 
  {
    transitiontime = transTime;
    updates[TRANS] = true;
    this.update();
  }

  // returns true if the light is on (based on last state change, not a query of the light) 
  public boolean isOn() 
  {
    return this.lightOn;
  }

  /*
   have the changes to the settings applied to the lamp & visualize; this
   calls the hub which handles the actual updates of the lights
   */
  public void update() {
    hub.applyState(this);
    // debugging
    // println("send update " + id);
  }

  // convenience method to turn the light off
  public void turnOff() 
  {
    this.lightOn = false;
    updates[ON] = true;
    this.update();
  }

  // convenience method to turn the light on
  public void turnOn() 
  {
    this.lightOn = true;
    updates[ON] = true;
    this.update(); // apply new state
  }

  // convenience method to turn the light on with some passed settings
  public void turnOn(int hue, int brightness) {
    this.lightOn = true;
    this.hue = hue;
    this.brightness = brightness;
    updates[ON] = true;
    updates[XY] = true;
    updates[BRI] = true;
    this.update(); // apply new state
  }

  /* 
   return data with lamp settings, JSON formatted string, to be send to hub
   sometimes after a while you get an error message that the light is off
   and it won’t change, even when it’s actually on. You can work around 
   this by always turning the light on first. 
   */
//  public String getData() {
//    StringBuilder data = new StringBuilder("{");
//    data.append("\"on\":"); 
//    data.append(lightOn);
//    // only if the light is on we need the rest
//    if (lightOn) {
//      data.append(", \"hue\":");
//      data.append(hue);
//      data.append(", \"bri\":");
//      data.append(brightness);
//      data.append(", \"sat\":");
//      data.append(saturation);
//    }
//    // always send transition time, to control how fast the state is changed
//    data.append(", \"transitiontime\":");
//    data.append(transitiontime);
//    data.append("}");   
//    return data.toString();
//  }

  public String getLightData()
  {
    StringBuilder data = new StringBuilder("{");
   
    // vars used for comma placement
    int totalUpdates = 0;
    int updated = 0;
    
    // Check the total udpates to make
    for (int i = 0; i < updates.length; i++)
    {
      if (updates[i])
      {
        totalUpdates ++;
      }
    }
    
    for (int i = 0; i < updates.length; i++)
    {
      if (updates[i])
      {
         if( i == ON )
         {
           data.append( getOnData() );
         }
         if( i == BRI )
         {
           data.append( getBriData() );
         }
         if( i == XY )
         {
           data.append( getXYData() );
         }
         if( i == CT )
         {
           data.append( getCTData() );
         }
         if( i == TRANS )
         {
           data.append( getTransData() );
         }
         updates[i] = false; // unflag the update    
         updated ++;
         if( updated < totalUpdates )
         {
           data.append(",");
         }
      }
    }
    data.append("}");
    return data.toString();
  }
  
  public String getXYData() 
  {
    colorMode(HSB, 255);
    color hsbCol = color( constrain(map(hue, 0, 65532, 0, 255), 0, 255) ,saturation,brightness);
    colorMode(RGB, 255);
    
    float redVar   = map(red(hsbCol),0,255,0,1);
    float greenVar = map(green(hsbCol),0,255,0,1);
    float blueVar  = map(blue(hsbCol),0,255,0,1);

    float xVar = (0.412453 * redVar)  + (0.35758 * greenVar)  + (0.180423 * blueVar);
    float yVar = (0.212671 * redVar)  + (0.715160 * greenVar) + (0.072169 * blueVar);
    float zVar = (0.019334 * redVar)  + (0.119193 * greenVar) + (0.950227 * blueVar);

    float xColor = 0;
    float yColor = 0;
    
    if (xVar!=0 || yVar!=0 || zVar!=0)
    {
      xColor = xVar / (xVar + yVar + zVar);
      yColor = yVar / (xVar + yVar + zVar);
    }
    
    StringBuilder data = new StringBuilder("");

    data.append("\"xy\":[");
    data.append(xColor);
    data.append(", ");
    data.append(yColor);
    data.append("]");
    
    return data.toString();
  }
  
  public String getBriData() 
  {
    StringBuilder data = new StringBuilder("");
    data.append("\"bri\":");
    data.append(brightness);
    return data.toString();
  }
  
  public String getCTData() 
  {
    StringBuilder data = new StringBuilder("");
    data.append("\"ct\":");
    data.append(ct);
    return data.toString();
  }
  
  public String getOnData()
  {
    StringBuilder data = new StringBuilder("");
    data.append("\"on\":"); 
    data.append(lightOn);
    return data.toString();
  }
  
  public String getTransData() 
  {
    StringBuilder data = new StringBuilder("");
    data.append("\"transitiontime\":");
    data.append(transitiontime);
    return data.toString();
  }

  // get current values
  public int getBrightness() {
    return brightness;
  }

  public int getSaturation() {
    return saturation;
  }

  public int getHue() {
    return hue;
  }

  public int getID() {
    return id;
  }
  
  // set position on screen
  public void setPosition(int x, int y) 
  {
    this.x = x;
    this.y = y;
  }

  public void draw() 
  {

  }
}
