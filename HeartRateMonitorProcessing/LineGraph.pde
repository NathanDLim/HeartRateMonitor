/*
 * This class displays data in a line graph
 */
 
static final long MOBD_THRESH = 10000;
static final int REFRACT_PERIOD = 15;


class LineGraph{
  int x,y; //coordinates of the graph
  int xLength, yLength;
  float[] yData;
  float MOBDx[];
  float MOBDy[];
  float yMin, yMax;
  int numBeats;
  int currX; // the next data to be updated
  boolean rawDisplay; //display raw data or MOBD
  
  
  LineGraph(int x,int y, int xLen, int yLen, int size, float yMin, float yMax){
    this.x = x;
    this.y = y;
    xLength = xLen;
    yLength = yLen;
    yData =  new float[size];
    MOBDx  = new float[size];
    MOBDy  = new float[size];
    this.yMin = yMin;
    this.yMax = yMax;
    
    numBeats = 0;
    currX = 0;
    rawDisplay = true;
  }
  
  //Method of backward difference to identify QRS
  void MOBD(){
    
    MOBDx[currX] = yData[currX] - yData[(currX-1+MOBDy.length)% MOBDy.length];
    MOBDy[currX] = abs(MOBDx[currX]*MOBDx[(currX-1+yData.length)%MOBDy.length]*MOBDx[(currX-2+MOBDy.length)%MOBDy.length]);
    
    MOBDy[currX] = map(MOBDy[currX],0,MOBD_THRESH,0,700);
    
    println(MOBDy[currX]);
    
    numBeats = 0;
    int refractCount = 0;
    for (int i =0; i<yData.length;i++){
      refractCount = refractCount >0 ? refractCount -1 :  0;
      if(MOBDy[i]>400 && refractCount == 0){
        refractCount = REFRACT_PERIOD;
        numBeats++;
      }
    }
  }
  
  void update(float newY){
   if(newY < yMin) newY = yMin;
   else if(newY > yMax) newY = yMax;
   yData[currX] = newY;
   
   MOBD();
   currX++;
   if(currX >= yData.length) currX = 0;
  }
  
  void toggleRawDisplay(){
     rawDisplay = !rawDisplay; 
  }
  
  int getNumBeats(){
    return numBeats;
  }
    
  void draw(){
    stroke(0xff);
    //axes
    line(x,y,x,y-yLength);
    //float xAxis = (yMin<0)? y+map(yMin,y,y+yLength,yMin,yMax):y;
    //line(x,xAxis,x+xLength,xAxis);
    //println(str(y) + " " + str(y+map(yMin,y,y+yLength,yMin,yMax)));
    
    if(rawDisplay){
      for(int i=0; i< yData.length-1; ++i)
        line(x+(xLength/yData.length)*i,y - map(yData[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(yData[i+1],yMin,yMax,0,yLength));
    }else {
      for(int i=0; i< MOBDy.length-1; ++i)
        line(x+(xLength/yData.length)*i,y - map(MOBDy[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(MOBDy[i+1],yMin,yMax,0,yLength));
    }
  }
  
}