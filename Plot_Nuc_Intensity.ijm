// Done by RLB @ Imagerie-Gif 2018
// romain.lebars@i2bc.paris-saclay.fr
// Optimized for ImageJ v 1.52h

// This macro will compare the distribution of a fluorescent signal between two stacks.
// You first have to select a region around each object you want to measure
// One channel used as a reference will allow to find the plane with the maximal intensity.
// At this plane the macro will draw the feret diameter of the object and mesure a plot profile along this selection on both channels.
// If multiples lines have been choosen, the feret diameter will be rotated and other profiles will be generated.
// For each object, Profiles, Overlays (of channels and lines) and a Montage will be generated.

// How to do  ?
// First open your data as two independant image stacks and if not the case calibrate them.
// Run the macro and folow the instructions.
// The measurments are automatically saved in the image folder as .txt files.


run("ROI Manager...");

setBatchMode(true);

FileNameOK = 0;

ClearTotal();

var maxloc=0;

	// List Open Images
	ImagesList = newArray(nImages());

	if (nImages!=2) {exit("Please open your images as two distinct stacks (one per channel) !");}
	
	for (i=1; i<=nImages(); i++)
		{
		selectImage(i);
		ImagesList [i-1] = getTitle();
  		} 

	LutList = newArray("Red", "Green","Blue","Cyan","Magenta","Yellow");

	while (FileNameOK == 0)
		{
		// Do Image Choice
		Dialog.create("Macro Set Up");
		Dialog.setInsets(10, 130, 15);
		
		Dialog.addString("Specify a file name :", ImagesList[0], 25);
		Dialog.addMessage("");
		Dialog.addMessage("Select the two stacks to use in this analysis");
		Dialog.addChoice("Channel1", ImagesList, ImagesList[0]);
		Dialog.addToSameRow();
		Dialog.addString("     Rename it ?", "No, keep original name!", 25);
		Dialog.addChoice("Apply a Look Up Table for Channel1", LutList, LutList[5]);
		Dialog.addMessage("");
		Dialog.addChoice("Channel2", ImagesList, ImagesList[1]);
		Dialog.addToSameRow();
		Dialog.addString("     Rename it ?", "No, keep original name!", 25);
		Dialog.addChoice("Apply a Look Up Table for Channel2", LutList, LutList[2]);
		Dialog.addMessage("");
		Dialog.show(); 

		// Get image names and change them if needed

		FileName = Dialog.getString();

		Img1OriName=Dialog.getChoice();
		LUT1 = Dialog.getChoice();
		
		Img2OriName=Dialog.getChoice();
		LUT2 = Dialog.getChoice();

		OutDir = getDirectory("image");
	
		Img1Name = Dialog.getString();
		Img2Name = Dialog.getString();
	
		if (File.exists(OutDir+FileName+"_"+"Nuc_1"+".txt"))
			{
			FileNameOK = getBoolean("Such a file name has already been given for a previous experiment \n If you want to overwrite those files press 'Yes'! \n To give a new file name press 'No'! ");			
			}
		else{FileNameOK = 1;}
		}

	if (Img1Name=="No, keep original name!")
		{
		Img1Name = Img1OriName;
		}
	else
		{
		selectWindow(Img1OriName);
		rename(Img1Name);
		}
	if (Img2Name=="No, keep original name!")
		{
		Img2Name = Img2OriName;
		}
	else
		{
		selectWindow(Img2OriName);
		rename(Img2Name);
		}

	AnalyzedChannels = newArray(2);
	AnalyzedChannels[0] = Img1Name;
	AnalyzedChannels[1] = Img2Name;

	// Create an overlay of both channels

	selectWindow(Img1Name);
	run(LUT1);
	selectWindow(Img2Name);
	run(LUT2);
	
	// Set analysis parameters 
	Dialog.create("Set analysis parameters");
	Dialog.setInsets(0, 10, 50);
	Dialog.addRadioButtonGroup("1.  Perform maximal intensity plane detection on wich channel ?", AnalyzedChannels, 2, 1, AnalyzedChannels[1]);
	Dialog.setInsets(20, 10, 25);
	Dialog.addNumber("2.  Specify the width of the profile (in pixels)                          ", 5);
	Dialog.setInsets(0, 10, 0);
	Dialog.addNumber("3.  Specify the number of lines to draw on each nucleus    ", 4);
	Dialog.setInsets(0, 20, 20);
	Dialog.addMessage("eg : 4 lines will generate 4 profiles rotated of 45 degrees (180/4).");
	Dialog.show(); 

	RefChannel = Dialog.getRadioButton();
	Width = Dialog.getNumber();
	NbLines = Dialog.getNumber();

	selectWindow(RefChannel);
	OutDir = getDirectory("image");
	
	// Generate a projetion for objects selection
	setTool("rectangle");
	selectWindow(RefChannel);
	run("Select None");
	roiManager("reset");
	run("Z Project...", "projection=[Max Intensity]");
	rename("Z_projection");
	run("Spectrum");
	setBatchMode("show");
	
	// Rename the ROIs and save the ROI_set
	NbNuc = 0;
	roiManager("show all with labels");
	while (NbNuc == 0)
		{
		waitForUser("Draw Selection", "Draw a selection around all the objects you want to analyze! \n \n Press 't' to add multiple regions to the ROI Manager. \n Press 'OK' when you are ready to run the analysis ! ");
		NbNuc = roiManager("count");
		}
		
	for (n=1; n<=NbNuc ; n++)
		{
		roiManager("Select", n-1);
		roiManager("Rename", "Nuc_"+n);
		}
		
	RoiPath = OutDir+FileName+"_ROI.zip";
	roiManager("Deselect");
	roiManager("Save", RoiPath);
	close("Z_projection");

	// For each nucleus...
	for (r=0; r<NbNuc; r++)
		{
		roiManager("reset");
		roiManager("open", RoiPath);

		// Find max intensity plane on the Reference Channel
		selectImage(RefChannel);
		roiManager("Select", r);
		run("Duplicate...", "duplicate");
		rename("Max");
		findMaxIntensityPlane();
		close("Max");

		// Extract max intensity plane on image1
		selectImage(Img1Name);
		setSlice(maxloc);
		roiManager("Select", r);
		RoiName = Roi.getName;
		run("Duplicate...", " ");
		run("Enhance Contrast", "saturated=0");
		rename(Img1Name+"_"+RoiName);

		// Extract max intensity plane on image2
		selectImage(Img2Name);
		setSlice(maxloc);
		roiManager("Select", r);
		run("Duplicate...", " ");
		run("Enhance Contrast", "saturated=0");
		rename(Img2Name+"_"+RoiName);

		// Generate Overlay
		run("Merge Channels...", "c1=["+Img1Name+"_"+RoiName+"] c2=["+Img2Name+"_"+RoiName+"] create keep");
		rename("Merge");
		run("RGB Color");
		rename("Overlay");
		run("Select All");
		setBackgroundColor(0, 0, 0);
		run("Clear", "slice");
		run("Select None");

		// Generate a binary mask on the Reference Channel
		selectImage(RefChannel);
		setSlice(maxloc);
		roiManager("Select", r);
		run("Duplicate...", " ");
		run("Enhance Contrast", "saturated=0");
		rename("Mask");

		run("Gaussian Blur...", "sigma=1");
		setAutoThreshold("Otsu dark");
		run("Convert to Mask");
		run("Fill Holes");

		run("Set Measurements...", "  redirect=None decimal=3");
		run("Analyze Particles...", "size=10-Infinity show=Nothing clear add");
	
		selectWindow(Img1Name+"_"+RoiName);
		roiManager("Select", 0);

		// Draw the feret diameter of the object detected on the mask
		drawFeretsDiameter();

		ROIline = roiManager("count");
		ROIline = ROIline - 1; 

		// Set the width of the line for the plot profile
		roiManager("Select", 0);
		run("Line Width...", "line=Width");
		roiManager("Update");

		// Elongate the feret diameter to be sure to include all the object in al the orientations
		roiManager("Select", 0);
		run("Scale... ", "x=1.30 y=1.30 centered");
		roiManager("Update");
		
		run("Clear Results");

		Angle = 0;
		angle = 180/NbLines;

		Table.create("PlotTable");

		// Generate a plot profile and save the values in a table for each line orientation
		for (k=1; k<=NbLines ; k++)
			{
			selectWindow(Img1Name+"_"+RoiName);
			roiManager("Select", ROIline);
			
			run("Plot Profile");
			Plot.getValues (x,y);
			run("Close");
			
			if (Angle == 0 ) {Table.setColumn("Distance", x);}
			Table.setColumn(Img1Name+"_"+Angle, y);
			
			selectWindow(Img2Name+"_"+RoiName);
			roiManager("Select", ROIline);
			
			run("Plot Profile");
			Plot.getValues (x,y);
			run("Close");
			
			Table.setColumn(Img2Name+"_"+Angle, y);

			selectWindow("Overlay");
			roiManager("Select", ROIline);

			if (Angle == 0 ){setForegroundColor(255, 0, 0);}
			else {setForegroundColor(255, 255, 255);}
			
			run("Fill", "slice");
			
			roiManager("Select", ROIline);
			run("Rotate...", "  angle=angle");
			roiManager("Update");
			Angle = Angle + angle;
	 		}
	 		
		SavePath = OutDir+File.separator+FileName+"_"+RoiName+".txt";
		Table.save(SavePath);

		selectWindow("Merge");
		run("Add Image...", "image=Overlay x=0 y=0 opacity=50");

		
		// Generate a montage

		selectWindow(Img1Name+"_"+RoiName);
		run("Grays");
		run("RGB Color");
		rename("Ch1Gray");

		selectWindow(Img2Name+"_"+RoiName);
		run("Grays");
		run("RGB Color");
		rename("Ch2Gray");

		selectWindow("Merge");
		run("RGB Color");
		rename("Ch3Merge");
		run("Remove Overlay");

		run("Concatenate...", "  title=4Montage image1=Ch1Gray image2=Ch2Gray image3=Ch3Merge");

		run("Scale Bar...", "width=2 height=4 font=14 color=White background=None location=[Lower Right] hide label");
		setSlice(3);
		run("Scale Bar...", "width=2 height=4 font=14 color=White background=None location=[Lower Right] bold");
		run("Make Montage...", "columns=3 rows=1 scale=1 border=2");
		rename("Montage");

		run("Select None");
		saveAs("Tiff", OutDir+File.separator+FileName+"_Montage_"+RoiName+".tif");
		run("Close");

		selectWindow("Merge");
		run("Select None");
		saveAs("Tiff", OutDir+File.separator+FileName+"_Overlay_"+RoiName+".tif");
		run("Close");
		
		//Close images to clean the workspace
  		if (isOpen("PlotTable"))
  			{
    		selectWindow("PlotTable");
       		run("Close");
  			}
  			
   		if (isOpen(Img1Name+"_"+RoiName)) 
   			{
    		selectWindow(Img1Name+"_"+RoiName);
       		run("Close");
   			}
  		if (isOpen(Img2Name+"_"+RoiName))
  			{
       		selectWindow(Img2Name+"_"+RoiName);
       		run("Close");
   			}
   		if (isOpen("Max"))
   			{
			selectWindow("Max");
			run("Close");
   			}
   		if (isOpen("Mask"))
   			{
			selectWindow("Mask");
			run("Close");
			}
		if (isOpen("4Montage"))
   			{
			selectWindow("4Montage");
			run("Close");
			}

   		if (isOpen("Overlay"))
   			{
			selectWindow("Overlay");
			run("Close");
			}

		}
		
   	if (isOpen("Results"))
   		{
    	selectWindow("Results");
    	run("Close");
   		} 

selectWindow(Img1Name);
rename(Img1OriName);
run("Select None");

selectWindow(Img2Name);
rename(Img2OriName);
run("Select None");

roiManager("reset");

showMessage("Job Done!", NbNuc+" objects analyzed with "+NbLines+" plots for each !  \n \n  All has been saved in the image folder.");

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function findMaxIntensityPlane()
	{
	S=nSlices;
	MeanFluoSlice=newArray(nSlices);
	run("Set Measurements...", "mean redirect=None decimal=3");
	
	//Measure the mean intensity on every slide of the stack
	for (i=0; i<S; i++)
		{
		setSlice(i+1);
		run("Measure");
		a=getResult("Mean",i);
		MeanFluoSlice[i]=a;
		}

	//Find the maximal mean intensity plane
	Sorted = Array.rankPositions(MeanFluoSlice);
	
	maxloc=Sorted[S-1];
	maxloc = maxloc+1;
	}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Part of "Draw Feret Diameter" macro from https://imagej.nih.gov/ij/macros/

function drawFeretsDiameter()
	{
    requires("1.29n");
    roiManager("reset");
    //run("Line Width...", "line=5");
    diameter = 0.0;
    getSelectionCoordinates(xCoordinates, yCoordinates);
    n = xCoordinates.length;
    for (i=0; i<n; i++)
    	{
        for (j=i; j<n; j++)
        	{
            dx = xCoordinates[i] - xCoordinates[j];
            dy = yCoordinates[i] - yCoordinates[j];
            d = sqrt(dx*dx + dy*dy);
            if (d>diameter)
            	{
                diameter = d;
                i1 = i;
                i2 = j;
				}
        	}
    	}
	setForegroundColor(255,127,255);
	makeLine(xCoordinates[i1], yCoordinates[i1],xCoordinates[i2],yCoordinates[i2]);
	roiManager("Add");
	}
	
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function ClearTotal()
{
	//run("Close All");
	run("Clear Results");
	roiManager("reset");
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
