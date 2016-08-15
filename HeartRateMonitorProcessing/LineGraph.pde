
static final int MOBD_THRESH = 250;
static final int REFRACT_PERIOD = 100;

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
  float MOBDz[];
  int numBeats = 0;
  boolean showMOBD;
  
  float THRESH1 = 0,
        THRESH2 = 0;
  
  LineGraph(int x,int y, int xLen, int yLen, int size, float yMin, float yMax){
    this.x = x;
    this.y = y;
    xLength = xLen;
    yLength = yLen;
    yData = new float[size];
    MOBDx = new float[size];
    MOBDy = new float[size];
    MOBDz = new float[size];
    
    this.yMin = yMin;
    this.yMax = yMax;
    showMOBD = false;
  }
  
  void update(float newY){
   if(newY < yMin) newY = yMin;
   else if(newY > yMax) newY = yMax;
   yData[currX] = newY;
   panThompkins();
   //MOBD();
   if(++currX >= yData.length) currX = 0;

  }
  
  void MOBD(){
    
    MOBDx[currX] = yData[currX] - yData[(currX-1+yData.length)% yData.length];
    if((MOBDx[currX]) < 0){
      MOBDx[currX] = 0;
      
    }
   
    

    
    //MOBDy[currX] = 1/3.0*(MOBDx[currX]+MOBDx[(currX-1+yData.length)%yData.length]+MOBDx[(currX-2+yData.length)%yData.length]);
    
    MOBDy[currX] = abs(MOBDx[currX]*MOBDx[(currX-1+yData.length)%yData.length]*MOBDx[(currX-2+yData.length)%yData.length]);
     //MOBDy[currX] = abs(MOBDx[currX]*MOBDx[(currX-1+yData.length)%yData.length]*MOBDx[(currX-2+yData.length)%yData.length]*MOBDx[(currX-3+yData.length)%yData.length]);
    
    
    numBeats = 0;
    int refractCount = 0;
    for (int i =0; i<yData.length;i++){
     refractCount = refractCount >0 ? refractCount -1 :  0;
     if(MOBDy[i]>MOBD_THRESH && refractCount == 0){
       refractCount = REFRACT_PERIOD;
       numBeats++;
     }
    }
    
    MOBDy[currX]  = map( MOBDy[currX] ,0,MOBD_THRESH,0,height);
    
    /* Tried this algorithm but didn't get it to work nicely.
     * from: http://www.nlpr.ia.ac.cn/2009papers/kz/gh15.pdf 
     */
    //MOBDz = new float[MOBDy.length];
    //for(int i = 0; i < yData.length; i++){
    //int check = i;
    //if(MOBDy[i] > 0){
    
    // for(int j = i; j > i-3; j--){
    // if(MOBDy[(--check+yData.length)%yData.length] > 0)
    //MOBDz[i] += MOBDy[(check+yData.length)%yData.length];
    // }
    
    //}
    //else if(MOBDy[i] < 0){
    
    // for(int j = i; j < i+3; j++){
    // if(MOBDy[(++check+yData.length)%yData.length] < 0){
    // MOBDz[i] += MOBDy[(check+yData.length)%yData.length];
    //}
    // }
    //}
    // }
    
    //numBeats = 0;
    //for(int i = 0; i < yData.length; i++){
    //if(MOBDz[i] > MOBD_THRESH && MOBDz[(i+1+yData.length)%yData.length] < -MOBD_THRESH)
    // numBeats++;
    //}
    
  }
  
  void panThompkins(){
    
   for(int i = 0; i < yData.length; i++){
     MOBDx[i] = yData[i] - yData[(i-1+yData.length)% yData.length];
     MOBDy[i] = MOBDx[i]*MOBDx[i];
   }
   
   int n = 20;
   
   float PEAKI = 0,
         SPKI = 400,
         NPKI = 0;
         
   
   for(int i = 0;i < yData.length; i++){
     MOBDz[i] = MOBDy[i];
     
     for(int j = n; j > 0; j--){
        MOBDz[i] += MOBDy[(i-j+yData.length)% yData.length]; 
        if(MOBDz[i] > PEAKI)
          PEAKI = MOBDz[i];
     }
     PEAKI/=n;
     if(PEAKI > THRESH1)
       SPKI = 0.125*PEAKI + 0.875*SPKI;
     else
       NPKI = 0.125*PEAKI + 0.875*NPKI;
       
     THRESH1 = NPKI + 0.25*(SPKI-NPKI);
     THRESH2 = 0.5*THRESH1;
     
     MOBDz[i] = map(MOBDz[i]/n, 0, 900,0, 700);
     //MOBDx[i] = MOBDz[i] - MOBDz[(i-1+yData.length)% yData.length];
     //MOBDx[i] = map(MOBDx[i]/n, 0, 900,0, 700);
     
   }
   
   
   //for(int i = 0; i < yData.length; i++){
   //  MOBDx[i] = MOBDz[i] - MOBDz[(i-1+yData.length)% yData.length];
   //}
   
   numBeats = 0;
   boolean flag = false;
    for (int i =0; i<yData.length;i++){
     //refractCount = refractCount >0 ? refractCount -1 :  0;
     if(MOBDz[i] > THRESH1 && !flag){
       
       flag = true;
       numBeats++;
     }else if (MOBDz[i] < THRESH2){
       flag = false;
     }
    }
   
  }
  
  void draw(){
    line(x,y,x+xLength,y);
    
    line(x,y-THRESH1,x+xLength,y-THRESH1);
    line(x,y-THRESH2,x+xLength,y-THRESH2);
    if(!showMOBD){    
      for(int i=0; i< yData.length-1; ++i){
        line(x+(xLength/yData.length)*i,y - map(yData[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(yData[i+1],yMin,yMax,0,yLength));
      }
    }else{
      for(int i=0; i< yData.length-1; ++i){
        line(x+(xLength/yData.length)*i,y - map(MOBDz[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(MOBDz[i+1],yMin,yMax,0,yLength));
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