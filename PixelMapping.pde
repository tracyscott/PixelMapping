/**
 * PixelMapping
 * 
 * Allows for interactive pixel wiring for 16 Pixlite outputs.  Once the
 * wiring is done, it can be saved to a file to be loaded by Rave Studio
 * in order to map LXPoint's to ArtNet universes.
 *
 * Loads a text file that contains two numbers separated by a comma (',').
 * Each pair represents the X,Y coordinates of an LXPoint in LX Studio.
 *
 *
 */
import controlP5.*;

float radius = 6f;
ArrayList<LXPoint> points = new ArrayList<LXPoint>();

// The wiring for the current output.  We add points to
// this list in the correct order.  We also draw a line from point to point
// to represent the wiring for each output.

ArrayList<Integer> outputIndices;
int selectedOutputNum = 0;
int[] outputColors = {
  color(255, 0, 0), 
  color(0, 255, 0), 
  color(0, 0, 255), 
  color(255, 127, 127), 
  color(255, 255, 0), 
  color(0, 255, 255), 
  color(127, 255, 127), 
  color(127, 127, 255), 
  color(0, 127, 127), 
  color(127, 0, 127), 
  color(0, 0, 127), 
  color(50, 70, 190), 
  color(255, 0, 0), 
  color(0, 255, 0), 
  color(0, 0, 255), 
  color(255, 255, 0), 
};

class LXPoint {
  public LXPoint(float x, float y, int index) {
    this.x = x;
    this.y = y;
    this.index = index;
    v = new PVector(x, y);
  }
  public PVector v;
  public float x, y;
  public int index;
}

static final int NUM_OUTPUTS = 16;

// An array of Integer lists.  For each output, we have a list of
// point indices in the ordered that they are wired.
ArrayList<Integer>[] outputs = new ArrayList[NUM_OUTPUTS];

/* ControlP5 UI Components
 *
 */
ControlP5 cp5;
CheckBox checkbox;
Button saveButton;
Button loadButton;
Button resetButton;
RadioButton r1;
// Display the current number of pixels for each output.
ArrayList<Textlabel> pixelCounts = new ArrayList<Textlabel>(NUM_OUTPUTS);


// Adds points as you move
boolean addWithMove = false;

// White background for printing a reference.
boolean printMode = false;

// The highlightedPoint is the point under the mouse cursor
int highlightedPoint = -1;
// The selected point is the currently active point.  Pressing *space* causes
// it to be added to the currently selected output.
int selectedPoint = 0;

int width = 900;
int height = 700;
void setup() {
  size(900, 700);
  background(0);
  stroke(255);
  strokeWeight(1);
  noFill();
  frameRate(40);
  loadLxPoints();
  for (int i = 0; i < NUM_OUTPUTS; i++) { 
    outputs[i] = new ArrayList<Integer>();
  } 
  outputIndices = outputs[selectedOutputNum];

  cp5 = new ControlP5(this);
  saveButton = cp5.addButton("save")
    .setPosition(680, 10)
    .setSize(50, 50);
   
  loadButton = cp5.addButton("load")
    .setPosition(740, 10)
    .setSize(50, 50);
    
  resetButton = cp5.addButton("reset")
    .setPosition(800, 10)
    .setSize(50, 50);
    
  checkbox = cp5.addCheckBox("checkBox")
    .setPosition(700, 75)
    .setSize(10, 10)
    .setItemsPerRow(1)
    .setSpacingColumn(30)
    .setSpacingRow(30)
    .addItem("Output 1", 1)
    .addItem("Output 2", 2)
    .addItem("Output 3", 3)
    .addItem("Output 4", 4)
    .addItem("Output 5", 5)
    .addItem("Output 6", 6)
    .addItem("Output 7", 7)
    .addItem("Output 8", 8)
    .addItem("Output 9", 9)
    .addItem("Output 10", 10)
    .addItem("Output 11", 11)
    .addItem("Output 12", 12)
    .addItem("Output 13", 13)
    .addItem("Output 14", 14)
    .addItem("Output 15", 15)
    .addItem("Output 16", 16)
    ;
  int i = 0;
  for (Toggle t : checkbox.getItems()) {
    t.getCaptionLabel().setColor(outputColors[i]);
    t.getCaptionLabel().setFont(createFont("Georgia", 16));
    t.setValue(true);
    i++;
    if (i >= outputColors.length) i = 0;
  }

  r1 = cp5.addRadioButton("radioButton")
    .setPosition(680, 75)
    .setSize(10, 10)
    .setItemsPerRow(1)
    .setSpacingColumn(30)
    .setSpacingRow(30)
    .hideLabels()
    .setColorForeground(color(120))
    .setColorActive(color(255))
    .setColorLabel(color(255))
    .addItem("OutputRadio1", 1)
    .addItem("OutputRadio2", 2)
    .addItem("OutputRadio3", 3)
    .addItem("OutputRadio4", 4)
    .addItem("OutputRadio5", 5)
    .addItem("OutputRadio6", 6)
    .addItem("OutputRadio7", 7)
    .addItem("OutputRadio8", 8)
    .addItem("OutputRadio9", 9)
    .addItem("OutputRadio10", 10)
    .addItem("OutputRadio11", 11)
    .addItem("OutputRadio12", 12)
    .addItem("OutputRadio13", 13)
    .addItem("OutputRadio14", 14)
    .addItem("OutputRadio15", 15)
    .addItem("OutputRadio16", 16)
    .hideLabels()
    ;

  r1.activate(0);
  
  // Now we need to create text labels to store the pixel counts.
  for (int j = 0; j < NUM_OUTPUTS; j++) {
    Textlabel l = cp5.addTextlabel("Count" + j).setText("0").setPosition(820, 70 + j*40);
    l.setFont(createFont("Georgia", 16));
    pixelCounts.add(l);
  }
  loadWiring();
}

/* Loads our LXPoints from a file named lxpoints.csv.  
 * One LXPoint per line in the format of x,y
 * We rely on the ordering of the points in this file to remain constant when
 * we re-import the wiring diagram into LX Studio.
 */
void loadLxPoints() {
  String[] lines;
  int index = 0;
  lines = loadStrings("lxpoints.csv");
  for (index = 0; index < lines.length; index++) {
    String[] pieces = split(lines[index], ',');
    if (pieces.length == 2) {
      float x = float(pieces[0]) * 100f;
      float y = height - ((int)(float(pieces[1]) * 100f));
      points.add(new LXPoint(x, y, index));
    }
  }  
}

void draw() {
  if (!printMode) background(0);
  else background(255);
  update();
  stroke(255);
  strokeWeight(1);
  noFill();
  int i = 0;
  for (LXPoint point : points) {
    if (i == highlightedPoint) {
      stroke(0, 255, 0);
    } else if ( i == selectedPoint) {
      stroke(0, 0, 255);
    } else {
      if (!printMode) stroke(255);
      else stroke(0);
    }
    rect(point.x, point.y, radius, radius);
    i++;
  }
  stroke(255, 0, 0);
  strokeWeight(3);
  for (int outputNum = 0; outputNum < outputs.length; outputNum++) {
    if (!checkbox.getItem(outputNum).getBooleanValue()) continue;
    ArrayList<Integer> curOutputIndices = outputs[outputNum];
    stroke(outputColors[outputNum]);
    if (curOutputIndices.size() > 0) {
      fill(outputColors[outputNum]);
      rect(points.get(curOutputIndices.get(0)).v.x, points.get(curOutputIndices.get(0)).v.y, radius, radius);
      noFill();
    }
    beginShape();
    for (Integer pointIndex : curOutputIndices) {
      PVector point = points.get(pointIndex).v;
      vertex(point.x + radius/2f, point.y + radius/2f);
    }
    endShape();
  }
}

void updatePixelCounts(int outputNum, int amt) {
  Textlabel l = pixelCounts.get(outputNum);
  int curValue = Integer.parseInt(l.getStringValue());
  curValue += amt;
  l.setText("" + curValue);
}

void keyPressed() {
  PVector selectedPt = points.get(selectedPoint).v;
  if (keyCode == 38) { // up
    selectedPoint = findPointAbove(selectedPt);
    if (addWithMove) addSelectedPoint();
  } else if (keyCode == 37) { // left
    selectedPoint = findPointLeft(selectedPt);
    if (addWithMove) addSelectedPoint();
  } else if (keyCode == 39) { // right
    selectedPoint = findPointRight(selectedPt);
    if (addWithMove) addSelectedPoint();
  } else if (keyCode == 40) { // down
    selectedPoint = findPointBelow(selectedPt);
    if (addWithMove) addSelectedPoint();
  } else if (keyCode == 32) { // space
    addSelectedPoint();
  } else if (keyCode == 76) { // l
     // lock adding so we add as we move.
     addWithMove = !addWithMove;
  } else if (keyCode == 8) { // Backspace, remove last point
    if (outputIndices.size() > 0) {
      outputIndices.remove(outputIndices.size() - 1);
      updatePixelCounts(selectedOutputNum, -1);
    }
  } else if (keyCode >= 48 && keyCode <= 57) {
    selectedOutputNum = keyCode - 48;
    outputIndices = outputs[selectedOutputNum];
  } else if (keyCode == 80) {  // p key toggles printMode
    printMode = !printMode;
  }
  System.out.println("selectedPoint=" + selectedPoint);
}

void addSelectedPoint() {
  // Don't allow a point to be added twice.
  for (Integer ptIndex: outputIndices) {
    if (selectedPoint == ptIndex)
      return;
  }
  outputIndices.add(selectedPoint);
  PVector point = points.get(selectedPoint).v;
  System.out.println("Added point " + point.x + "," + point.y);
  updatePixelCounts(selectedOutputNum, 1);  
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(r1)) {
    selectedOutputNum = (int)(theEvent.getValue() - 1);
    outputIndices = outputs[selectedOutputNum];
  }
}

public void reset(int unused) {
  for (int outputNum = 0; outputNum < NUM_OUTPUTS; outputNum++) {
    ArrayList<Integer> indices = outputs[outputNum];
    int numPts = indices.size();
    updatePixelCounts(outputNum, -numPts);
    indices.clear();
  }
}

public void save(int unused) {
  saveWiring();
}

public void saveWiring() {
  PrintWriter fileOut;
  fileOut = createWriter("wiring.txt");
  for (int i = 0; i < NUM_OUTPUTS; i++) {
    ArrayList<Integer> outIndices = outputs[i];
    fileOut.println(":" + i);
    for (Integer lxPointIndex: outIndices) {
      fileOut.println("" + lxPointIndex);
    }
  }
  fileOut.close();
}

public void load(int unused) {
  loadWiring();
}

public void loadWiring() {
  String[] lines = loadStrings("wiring.txt");
  // Clear the existing wiring.
  reset(0);
  for (int index = 0; index < lines.length; index++) {
    String line = lines[index];
    if (line.startsWith(":")) {
      selectedOutputNum = Integer.parseInt(line.replace(":", ""));
      outputIndices = outputs[selectedOutputNum];
    } else {
      int pointIndex = Integer.parseInt(line);
      outputIndices.add(pointIndex);
      updatePixelCounts(selectedOutputNum, 1); 
    }
  }
  selectedOutputNum = 0;
  outputIndices = outputs[selectedOutputNum];
}

int findPointAbove(PVector src) {
  int closestPointIndex = 0;
  float closestDistance = 10000.0f;
  int i = 0;
  for (LXPoint point : points) {
    float dist = point.v.dist(src);
    // Must be about the same X.
    if (dist < closestDistance && abs(point.x - src.x) < 2.0
      && point.y - src.y < 0) {
      closestDistance = dist;
      closestPointIndex = i;
    }
    i++;
  }
  return closestPointIndex;
}

int findPointBelow(PVector src) {
  int closestPointIndex = 0;
  float closestDistance = 10000.0f;
  int i = 0;
  for (LXPoint point : points) {
    float dist = point.v.dist(src);
    // Must be about the same X.
    if (dist < closestDistance && abs(point.x - src.x) < 2.0 
      && point.y - src.y > 0) {
      closestDistance = dist;
      closestPointIndex = i;
    }
    i++;
  }
  return closestPointIndex;
}

int findPointLeft(PVector src) {
  int closestPointIndex = 0;
  float closestDistance = 10000.0f;
  int i = 0;
  for (LXPoint point : points) {
    float dist = point.v.dist(src);
    // Must be about the same X.
    if (dist < closestDistance && abs(point.y - src.y) < 2.0 
      && point.x - src.x < 0) {
      closestDistance = dist;
      closestPointIndex = i;
    }
    i++;
  }
  return closestPointIndex;
}

int findPointRight(PVector src) {
  int closestPointIndex = 0;
  float closestDistance = 10000.0f;
  int i = 0;
  for (LXPoint point : points) {
    float dist = point.v.dist(src);
    // Must be about the same X.
    if (dist < closestDistance && abs(point.y - src.y) < 2.0 
      && point.x - src.x > 0) {
      closestDistance = dist;
      closestPointIndex = i;
    }
    i++;
  }
  return closestPointIndex;
}

void update () {
  int i = 0;
  highlightedPoint = -1;
  for (LXPoint point : points) {
    if (overRect((int)point.x, (int)point.y, (int)radius, (int)radius)) {
      highlightedPoint = i;
    }
    i++;
  }
}

boolean overRect(int x, int y, int width, int height) {
  if (mouseX >= x && mouseX <= x+width &&
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

void mouseClicked() {
  if (highlightedPoint != -1) {
    selectedPoint = highlightedPoint;
  }
}
