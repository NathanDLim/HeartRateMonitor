"""
Author: Nathan Lim

EDITING LOG: 
	May 3 - write incoming data from arduino to text file for matlab interpretation, improved GUI aesthetics, display label for heart rate
	May 4 - use Method of Backward Difference (first order) to find the heart rates, can display MOBD data, 
"""

from Tkinter import *
#import tkMessageBox
#from multiprocessing import Process, freeze_support #test, to check out 
import serial #pySerial, to communicate with Arduino
import serial.tools.list_ports #to list the COM ports
import FileDialog #for pyinstaller
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import numpy as np
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure
matplotlib.use('TkAgg') #for placing matplotlib animation in tkinter


from math import ceil
		
"""
The HeartMonitor Class communicates with the Arduino.
"""
class HeartMonitor:

	"""
	Constructor for the HeartMonitor
	"""
	def __init__(self, to, baudRate):
		#serial port connected to Arduino
		self.ser = None
		#boolean to see if arduino is connected or not
		self.connection = False
		#timeout rate for the serial port
		self.timeout = to
		self.baud = baudRate
		self.transmitting = False
	
	"""
	Destructor. TODO: Should we have one?
	"""
	def __del__(self):
		self.closeSerial()
		
	"""
	Sends stop transmission signal('0') to the arduino to tell it to stop sending data.
	@return True if successfully stopped
	@return False if could not be stopped
	"""
	def stopTrans(self):
		if(self.ser is not None and self.ser.isOpen() is True):
			self.ser.write('0')
			self.transmitting = False
			return True
		self.transmitting = False #we know that something has gone wrong
		return False
	
	"""
	Stops transmission and closes the serial port
	"""
	def closeSerial(self):
		if(self.connection is True):
			self.stopTrans()
			self.ser.close()

	"""
	Try to create a new serial object at a given COM Port. 
	@return True if successfully initialized or already exists
	@return False if failed to initialize
	"""
	def init(self,comPort):
		if(self.ser is not None and self.ser.isOpen() is True):
			return True
		try:
			self.ser = serial.Serial(comPort, self.baud,timeout = self.timeout)
			self.connection = True
			return True
		except:
			self.ser = None
			self.connection = False
			return False

	"""
	Writes start transmission signal('1') to the arduino to start the transmission
	@return True if successfully sent a start signal to arduino
	@return False if could not send start signal
	"""
	def beginTrans(self):
		if(self.ser is not None and self.ser.isOpen() is True):
			self.ser.write("1")
			self.transmitting = True
			return True
		self.transmitting = False
		return False
			
	"""
	reads the serial port and returns the reading TODO: change to only one failed return?
	@return string of data from arduino
	@return None if cannot connect with serial port
	@return "" if serial port timeout
	"""
	def readSerial(self):
		if(self.ser is None or self.connection is False):
			return None;
		if(self.ser.inWaiting() > 0):
			return self.ser.readline()
		return ""

		
'''
The GUI for the heart monitor class.
'''
class HeartMonitorGUI:
	
	def __init__(self):
		#create a heart monitor object
		self.hm = HeartMonitor(1.0,9600)
		
		#set up GUI
		self.top = Tk()
		self.top.wm_title("Heart Rate Monitor GUI")
		self.top.resizable(width=FALSE, height=FALSE)
		#labelString will store the message to the user on the current status
		self.labelString = StringVar()
		self.labelString.set("\t\t          ")
		buttonFrame = Frame(self.top,relief = RIDGE, bd =1,padx = 10,pady=10)
		b = Button(buttonFrame,text = "Initialize",command = self.initButton)
		b.grid(ipadx =5, ipady = 3,row =1, column =0,pady = 5)
		beginTransB = Button(buttonFrame, text ="Begin Reading", command = self.beginButton)
		beginTransB.grid(ipadx =5, ipady = 3,row = 2,column = 0,pady = 5)
		stopTransB = Button(buttonFrame, text ="Stop Reading", command = self.stopButton)
		stopTransB.grid(ipadx =5, ipady = 3,row = 3, column =0,pady = 5)
		quitButton = Button(buttonFrame,text = "Exit", command = self._quit)
		quitButton.grid(ipadx =5, ipady = 3,row  = 4, column =0,pady = 5)
		l = Label(buttonFrame,textvariable = self.labelString)
		l.grid(ipadx =5, ipady = 15,row = 0, column = 0)
		
		buttonFrame.grid(row =3,column =0, rowspan = 10,padx=10)

		heartRateFrame = Frame(self.top ,relief = SUNKEN, bd =1, padx=10,pady=10, width = 100)
		
		
		self.heartRateString = StringVar()
		self.heartRateString.set("BPM")
		self.bpm = True
		hl = Label(heartRateFrame,textvariable = self.heartRateString)
		hl.bind("<Button-1>",self.labelClicked)
		hl.pack(fill=BOTH)
		
		heartRateFrame.grid(row=17,column =0, rowspan = 3, columnspan = 1)
		
		#set up GUI menubar
		menubar = Menu(self.top)
		configMenu = Menu(self.top,tearoff=0)
		ports = list(serial.tools.list_ports.comports())
		#comPortVar will store the COM port that the user has selected from the pull down menu as an integer (ie. '3' for COM3)
		self.comPortVar = IntVar()
		for p in ports:
			#p[0] will return COMX, where X is the com port number, p[0][3] will return X
			configMenu.add_radiobutton(label=p, command = self.comPortRadio,variable = self.comPortVar, value = p[0][3]) 
		menubar.add_cascade(label="COM port",menu = configMenu)
		# display the menu
		self.top.config(menu=menubar)
		
		
		"""
		Old stuff for plot
		"""
		# # plotting stuff
		# horizontalRes = 200
		# self.fig = plt.Figure()
		# xdata = np.arange(horizontalRes)
		# ydata = np.arange(horizontalRes)
		# plt.xlim(0,horizontalRes)
		# plt.ylim(-1,700)

		# # line
		# self.x = np.arange(0, 2*np.pi, 0.01)
		# self.data = np.random.rand(2, 25)
		# ax = self.fig.add_subplot(111)
		# self.l, = ax.plot(self.x, np.sin(self.x))
		
		# # canvas
		# canvas = FigureCanvasTkAgg(self.fig, master = self.top)
		# # canvas.show()
		# canvas.get_tk_widget().pack()
		# # canvas._tkcanvas.pack()
		
		#keeps track of if the arduino is sending information or not
		self.transmitting=False 
		#stores the current x value in the line to be updated (plot)
		self.currX = 0
		#the frequency that the arduino sends data over the serial line
		self.transmitFreq = 40
		#The length of the plot in seconds
		self.repeatedTime = 15
		
		
		#maximum x length of plot
		self.xLength = self.repeatedTime*self.transmitFreq
		
		#set up the x and y data for the plot
		self.x = np.arange(0, self.repeatedTime, 1.0/self.transmitFreq)
		self.y = np.zeros(self.xLength)
		
		"""
		For finding the heart rate
		"""
		#values for the method of backward difference
		self.MOBDX = np.zeros(self.xLength)
		self.MOBDY = np.zeros(self.xLength)
		
		#counts the number of beats in the repeated time
		self.numBeats = 0
		#cannot have two beats within 250 milliseconds
		self.refractPeriod = ceil(0.250*self.transmitFreq)
		self.threshhold = 32000
		
		
		"""
		For the plot
		"""
		#test
		fig = plt.Figure()
		fig.suptitle('Heart Rate Display', fontsize=14, fontweight='bold')
		#puts the plot on the GUI
		canvas = FigureCanvasTkAgg(fig, master=self.top)
		canvas.get_tk_widget().grid(row = 1,rowspan = 20,column = 1)

		self.ax = fig.add_subplot(111)
		self.ax.set_ylim([0,700])
		self.ax.set_xlim([0,self.repeatedTime])
		self.ax.set_xticks([3,6,9,12,15])
		self.ax.get_yaxis().set_visible(False)
		self.ax.set_xlabel('Seconds')
		self.line, = self.ax.plot(self.x, self.y)
		
		#start the animation
		ani = animation.FuncAnimation(fig, self.animate, np.arange(1, 200), interval=25, blit=False)
		
		#start the GUI
		self.top.mainloop()
	
	
	"""
	If the arduino is sending data, the corresponding y value for currX will be updated by the value sent by the arduino.
	If the arduino is not sending data, the data will not be changed.
	@return the line object
	"""
	def animate(self,i):
		#only animates the plot if communicating with arduino
		if self.transmitting is True:
			#reads incoming data from arduino
			inString = self.hm.readSerial()
			
			# inString can be None, "", or "y1 y2"
			if(inString is not "" and inString is not None):
				data = inString.split()
				if(len(data) is 2):
					#do this for both y1 and y2
					for i in range(0,2):
						#I think that this data is upside down from arduino?
						self.y[self.currX] = int(data[i])
						self.MOBD()
						self.currX += 1 
					
					if(self.currX >= self.xLength-2):
						self.currX = 0
						
					#either makes the line according to the incoming data or according to the MOBD
					if(self.bpm is True):
						self.line.set_data(self.x,self.y)
						self.ax.set_ylim([0,700])
						self.file.write(data[0] + "\n" + data[1] + "\n")
					else:
						self.line.set_data(self.x,self.MOBDY)
						self.ax.set_ylim([0,self.threshhold])
						
		return self.line,
	
	"""
	called when a new point is added onto self.y
	"""
	def MOBD(self):
		
		self.MOBDX[self.currX] = self.y[self.currX] - self.y[(self.currX-1+self.xLength)%self.xLength]
		self.MOBDY[self.currX] = abs(self.MOBDX[self.currX]*self.MOBDX[(self.currX-1+self.xLength)%self.xLength]*self.MOBDX[(self.currX-2+self.xLength)%self.xLength])
				
		self.numBeats = 0
		refractCount = 0
		for i in range(0,self.xLength):
			refractCount = refractCount-1 if refractCount >0 else 0
			if(self.MOBDY[i]>self.threshhold and refractCount is 0):
				refractCount = self.refractPeriod
				self.numBeats += 1
		self.dispayFreqChange()
	"""
	called by the radio button for the com ports. This will close whatever port was open before.
	"""
	def comPortRadio(self):
		self.hm.closeSerial()
	
	"""
	called by the begin button. Should tell the heart monitor to begin sending data
	"""
	def beginButton(self):
		self.file = open("output.txt","w")
		if(self.hm.beginTrans() is True):
			self.transmitting = True
			self.labelString.set("Transmission Ongoing ")
		else:
			self.transmitting = False
			self.labelString.set("  Error Beginning Trans. ")
		

	"""
	called by the init button. Calls the heartMonitor init function
	"""
	def initButton(self):
		if(self.hm.init("COM" + str(self.comPortVar.get())) is True): #self.comPortVar is an IntVar, we get the int value and convert it into a string, then add 'COM' infront
			self.labelString.set("  Connected to COM " + str(self.comPortVar.get()) + "  ")
		else:
			self.labelString.set("       Error Connecting     ")

	"""
	called by the stop button. Calls the heartMonitor stop tranmission function
	"""
	def stopButton(self):
		self.file.close()
		if(self.hm.stopTrans() is True):
			self.transmitting = False
			self.labelString.set(" Transmission Stopped ")
		else:
			self.labelString.set("   Error Stopping Trans.  ")
	
	"""
	Called by clicking the heart rate label. changes between BPM and Hz, also between signal and MOBD display
	"""
	def labelClicked(self,event):
		self.bpm = not self.bpm
	
	"""
	updates the heart rate on the label
	"""
	def dispayFreqChange(self):
		if self.bpm is True:
			self.heartRateString.set(str(self.numBeats*(60/self.repeatedTime)) + " BPM")
		else:
			self.heartRateString.set(str(self.numBeats/float(self.repeatedTime)) + "Hz")
		
		
	"""
	destroys the GUI. Without this, the exe will not actually stop when closed.
	"""
	def _quit(self):
		self.top.quit()
		self.top.destroy()
		
		
HeartMonitorGUI()