
static final int MOBD_THRESH = 250;
static final int REFRACT_PERIOD = 30;

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
  int beatLoc[];
  int numBeats = 0;
  boolean showMOBD;
  
   float PEAKI = 0,
        SPKI = 400,
        NPKI = 0;
  
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
    
    beatLoc = new int[400]; //shouldn't get anywhere close to 400 beats
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

   
   MOBDx[currX] = yData[currX] - yData[(currX-1+yData.length)% yData.length];
   MOBDx[currX] *= MOBDx[currX];
   

  //moving average
   int n = 20;
   MOBDz[currX] = 0;
   for(int j = n; j > 0; j--){
       MOBDz[currX] += MOBDx[(currX-j+yData.length) % yData.length]; 
    }
    MOBDz[currX]=MOBDz[currX]/n;
   
   
   //find the peak and threasholds based off the past 200 samples
   SPKI = 400;
   for(int i = 0; i < 200; i++){
     PEAKI = 0;
    for(int j = n; j >= 0; j--){
        if(MOBDz[(currX-i+yData.length) % yData.length] > PEAKI)
          PEAKI = MOBDz[(currX-i+yData.length) % yData.length];
    }
     //PEAKI /= n;
     
    if(PEAKI > THRESH1){
       SPKI = 0.125*PEAKI + 0.875*SPKI;
    }
    //else if(PEAKI > THRESH2){
    //  SPKI = 0.25*PEAKI + 0.75*SPKI;
    //}
     else
       NPKI = 0.125*PEAKI + 0.875*NPKI;
      
   }
   
   //System.out.print(THRESH1 + " ");
   //System.out.println(PEAKI);
         
     THRESH1 = NPKI + 0.5*(SPKI-NPKI);
     THRESH2 = 0.75*THRESH1;
     
   float t1=0,
       t2=0;
       
   numBeats = 0;
   boolean QRSFound;
   
   for(int i = 0; i < beatLoc.length;i++)
     beatLoc[i]=0;
   int c = 0;
   int refract = 0;
   
   //Detection algorithm (based off Pan Thompkins)
    for(int i = 0; i < yData.length;i+= 100){
      QRSFound = false;
      for(int j =0; j < 100; j++){
        t2 = t1;
        t1 = MOBDz[(i+j+yData.length) % yData.length];
        if(t2 < THRESH1 && t1 > THRESH1 && refract == 0){
          numBeats++;
          beatLoc[c++] = i+j;
          QRSFound = true;
          refract = REFRACT_PERIOD; //There can't be two heart beats very close to eachother, so we make a refract period.
        }
        refract = refract ==0? refract: refract -1;
      }
      if(!QRSFound){
       for(int j =0; j < 100; j++){
         t2 = t1;
         t1 = MOBDz[(i+j+yData.length) % yData.length];
         if(t2 < THRESH2 && t1 > THRESH2 && refract == 0){
           numBeats++;
           beatLoc[c++] = i+j;
           QRSFound = true;
           refract = REFRACT_PERIOD;
         }
         refract = refract ==0? refract: refract -1;
       }
      }
   }
   
   for (int i = 0; i < beatLoc.length; i++){
     
   }
     
   
  }
  
  void draw(){
    //Show some of the lines
    //line(x,y,x+xLength,y);
    //line(x,y-THRESH1,x+xLength,y-THRESH1);
    //line(x,y-THRESH2,x+xLength,y-THRESH2);
    
    //line(x+currX-100, 0,x+currX-100, height);
    fill(0, 102, 153, 20);
    for(int i = 0; i < beatLoc.length;i++){
      if(beatLoc[i]==0) continue;
      rect(x+beatLoc[i]-8,y,16,-yLength+100);
    }
    
    //if(!showMOBD){    
    //  for(int i=0; i< yData.length-1; ++i){
    //    line(x+(xLength/yData.length)*i,y - map(yData[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(yData[i+1],yMin,yMax,0,yLength));
    //  }
    //}else{
    //  for(int i=0; i< yData.length-1; ++i){
    //    line(x+(xLength/yData.length)*i,y - map(MOBDz[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(MOBDz[i+1],yMin,yMax,0,yLength));
    //  }
    //}
    
    if(!showMOBD){    
     for(int i=0; i< yData.length-1; ++i){
       line(x+(xLength/yData.length)*i,y - map(yData[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(yData[i+1],yMin,yMax,0,yLength));
     }
    }else{
     for(int i=0; i< yData.length-1; ++i){
       line(x+(xLength/yData.length)*i,y - MOBDz[i], x+(xLength/yData.length)*(i+1),y - MOBDz[i+1]);
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