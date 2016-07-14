
static final int MOBD_THRESH = 400;
static final int REFRACT_PERIOD = 15;

/*
 * This class displays data in a line graph
 */
class LineGraph{
  int x,y;
  int xLength, yLength;
  float yData[];
  float yMin, yMax;
  int currX; // the next data to be updated
  float MOBDx[];
  float MOBDy[];
  int numBeats = 0;
  boolean showMOBD;
  
  LineGraph(int x,int y, int xLen, int yLen, int size, float yMin, float yMax){
    this.x = x;
    this.y = y;
    xLength = xLen;
    yLength = yLen;
    yData =  new float[size];
    MOBDx = new float[size];
    MOBDy = new float[size];
    this.yMin = yMin;
    this.yMax = yMax;
    showMOBD = false;
  }
  
  void update(float newY){
   if(newY < yMin) newY = yMin;
   else if(newY > yMax) newY = yMax;
   yData[currX] = newY;
   MOBD();
   if(++currX >= yData.length) currX = 0;

  }
  
  void MOBD(){
    
    MOBDx[currX] = yData[currX] - yData[(currX-1+yData.length)% yData.length];
    if(abs(MOBDx[currX]) < 3)
     MOBDx[currX] = 0;
    //MOBDy[currX] = abs(MOBDx[currX]*MOBDx[(currX-1+yData.length)%yData.length]*MOBDx[(currX-2+yData.length)%yData.length]*MOBDx[(currX-3+yData.length)%yData.length]);
    
    //MOBDy[currX]  = map( MOBDy[currX] ,0,MOBD_THRESH,0,height);

    
    MOBDx[currX] = 1/3.0*(MOBDx[currX]+MOBDx[(currX-1+yData.length)%yData.length]+MOBDx[(currX-2+yData.length)%yData.length]);
    
    MOBDy[currX] = abs(MOBDx[currX]*MOBDx[(currX-1+yData.length)%yData.length]*MOBDx[(currX-2+yData.length)%yData.length]);
    
    numBeats = 0;
    int refractCount = 0;
    for (int i =0; i<yData.length;i++){
     refractCount = refractCount >0 ? refractCount -1 :  0;
     if(MOBDy[i]>MOBD_THRESH && refractCount == 0){
       refractCount = REFRACT_PERIOD;
       numBeats++;
     }
    }
    
    /* Tried this algorithm but didn't get it to work yet.
     * from: http://www.nlpr.ia.ac.cn/2009papers/kz/gh15.pdf 
     */
    //for(int i = 0; i < yData.length; i++){
    // int backcheck = i;
    // backcheck++;
    // while(Math.signum(MOBDy[i]) == Math.signum(MOBDy[((backcheck)+yData.length)%yData.length]) && Math.signum(MOBDy[i]) != 0){
    //  //print(backcheck);
    //  MOBDy[i] += MOBDy[((backcheck)+yData.length)%yData.length];
    //  backcheck--;
    // }
     
    //}
    
    
    
  }
  
  void draw(){
    if(!showMOBD){    
      for(int i=0; i< yData.length-1; ++i){
        line(x+(xLength/yData.length)*i,y - map(yData[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(yData[i+1],yMin,yMax,0,yLength));
      }
    }else{
      for(int i=0; i< yData.length-1; ++i){
        line(x+(xLength/yData.length)*i,y - map(MOBDy[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(MOBDy[i+1],yMin,yMax,0,yLength));
      }
    }
    
  }
  
  int getNumBeats(){
    return numBeats;
  }
  
  void toggleMOBD(){
    showMOBD = !showMOBD;
  }
}