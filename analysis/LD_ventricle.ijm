// script to a) extract perimeter from blue channel and b) analyze particles w/i region in green channel

#@ File (label = "Blue input directory", style = "directory") inputBluePath
// inputBluePath = "G:/My Drive/Tsai Images/2024-07-12 LD imaging set CFLC/pre240816/blue_channel/"
#@ File (label = "Green input directory", style = "directory") inputGreenPath
// "G:/My Drive/Tsai Images/2024-07-12 LD imaging set CFLC/pre240816/green_channel/"
#@ File (label = "Output directory", style = "directory") outputPath
// "C:/Users/jaked/Documents/Tsai2024/TsaiLipidomics/data/2024-07-12/pre240816/"

processFolder();

function processFolder() {
	
	blueFiles = getFileList(inputBluePath);
	blueFiles = Array.sort(blueFiles);
	greenFiles = getFileList(inputGreenPath);
	greenFiles = Array.sort(greenFiles);
	
	// create output files
	f = File.open(outputPath + File.separator + "ventricle2.csv");
	print(f, "Image,Ventricle Border Area,Ventricle Perimeter,Corrected Perimeter,Z Stack");
	File.close(f);
	
	g = File.open(outputPath + File.separator + "LD2.csv");
	print(g, "Image,n,Avg Vol,Avg SA,Integrated Intensity Density");
	File.close(g);
		
	for (i = 0; i < blueFiles.length; i++) {
		image = blueFiles[i].substring(0, blueFiles[i].length()-6);
		ventricle(image);
		run("Clear Results");
		LD(image);
		waitForUser("Press OK to continue with next image");
		run("Clear Results");
		roiManager("reset");
		close("*");
	}
}



function ventricle(image) {

	open(inputBluePath + File.separator + image + "_B.czi");
	zStack = nSlices;
	
	// take a z projection and pre-process
	run("Z Project...", "projection=[Average Intensity]");
	selectImage(image + "_B.czi");
	close();
	selectImage("AVG_" + image + "_B.czi");
	run("Gaussian Blur...", "sigma=5 stack");
	run("Enhance Contrast", "saturated=0.35");
	
	waitForUser("Ready to process?");
	
	// prompt the user to draw splines to complete the perimeter
	n = getNumber("How many open edges are there?", 0);
	
	for (i = 0; i < n; i++) {
		// draw bezier curves
		run("Line Width...", "line=20");
		setTool("Bezier Curve Tool");
		waitForUser("Curve " + i+1 + ": Draw the curve, click anywhere on the yellow line, and then press OK");
		
		// get ROI
		roiManager("Add");
		
		// apply to all layers
		run("Flatten");
		
		// close last intermediate image
		if (i==0) {
			selectImage("AVG_" + image + "_B.czi");
		} else {
			selectImage("AVG_" + image + "_B-" + i + ".czi");
		}
		close();
	}
	
	
	// calculate total length of bezier curves (will be subtracted from perimeter later)
	bezierLength = 0;
	if (n != 0) {
		run("Set Scale...", "distance=1.6028 known=1 unit=micron");
		roiManager("Measure");
		for (i=0; i < n; i++) {
			bezierLength = bezierLength + getResult("Length", i);
		}
		close("Results");
	}
	
	// run morphological segmentation
	run("16-bit");
	run("Morphological Segmentation");
	wait(1000); // wait for gui to open
	call("inra.ijpb.plugins.MorphologicalSegmentation.segment", "tolerance=12.0", "calculateDams=true", "connectivity=4");
	wait(6000); // wait for segmentation to run
	call("inra.ijpb.plugins.MorphologicalSegmentation.createResultImage");


	// selected segmented image
	if (isOpen("AVG_" + image + "_B-overlaid-basins.czi")) {
		selectImage("AVG_" + image + "_B-overlaid-basins.czi");
	} if (isOpen("AVG_" + image + "_B-1-overlaid-basins.czi")) {
		selectImage("AVG_" + image + "_B-1-overlaid-basins.czi");
	} if (isOpen("AVG_" + image + "_B-2-overlaid-basins.czi")) {
		selectImage("AVG_" + image + "_B-2-overlaid-basins.czi");
	}

	
	// extract the ventricle interior
	run("Keep Largest Label");
	run("Fill Holes (Binary/Gray)");
	
	// save mask of interior of ventricle (w/ a dilation to include LDs on the border)
	//setOption("BlackBackground", true);
	//run("Convert to Mask");
	run("Create Selection");
	roiManager("add");
	
	// select mask ROI and rename to identify
	lastIndex = roiManager("count") - 1;
	roiManager("Select", lastIndex);
	roiManager("Rename", image + "_mask");
	
	// measure inner area and perimeter of ventricle
	run("Set Scale...", "distance=1.6028 known=1 unit=micron");
	run("Analyze Regions", "area perimeter");
	inner_area = getResult("Area", 0);
	perim = getResult("Perimeter", 0);
	
	// measure outer area of ventricle
	vv3 = true;
	if (vv3) {
		run("Enlarge...", "enlarge=25");
	} else {
		run("Enlarge...", "enlarge=40");
	}
	run("Set Measurements...", "area redirect=None decimal=3");
	run("Measure");
	outer_area = getResult("Area", 0);
	
	border_area = outer_area - inner_area;
	print("outer: " + outer_area + ", inner: " + inner_area);
	corrected_perim = perim - bezierLength;
	
	// write csv with data
	newLine = image + "," + border_area + "," + perim + "," + corrected_perim + "," + zStack;
	ventricleFile = outputPath + File.separator + "ventricle2.csv";
	File.append(newLine, ventricleFile);
	
}


function LD(image) {
	
	open(inputGreenPath + File.separator + image + "_G.czi");
	
	run("Set Scale...", "distance=1.6028 known=1 unit=micron");
	
	// apply mask from blue channel
	numRois = roiManager("count");
	for (i=0; i < numRois; i++) {
		roiManager("Select", i);
		if (Roi.getName() == image + "_mask") {
			break;
		}
	}
	
	// make band around perimeter
	run("Make Band...", 25); // 25 microns for vV3

	run("Clear Outside", "stack");
	
	// calculate measure of flourescence
	run("Set Measurements...", "integrated redirect=None decimal=3");
	intDen = 0;
	for (i = 1; i <= nSlices; i++) {
	    setSlice(i);
	    run("Measure");
	    intDen += getResult("IntDen", i-1);
	}
	
	// manually convert to binary using threshold
	waitForUser("Set manual threshold (Ctrl+Shift+T)");
	
	// TODO: 1 pixel^3 = (1.6028 microns)^3 = 4.12 > min vol -- should this be lower?
	run("Particle Analyser", "surface_area enclosed_volume min=0.268 max=268.08 surface_resampling=2 surface=Gradient split=0.000 volume_resampling=2");

	// write to csv
	saveAs("Results", outputPath + File.separator + image + "_LD.csv");
	n = nResults;
	run("Summarize");
	avgVol = getResult("Vol. (microns³)", n);
	avgSA = getResult("SA (microns²)", n);
	
	newLine = image + "," + n + "," + avgVol + "," + avgSA + "," + intDen;
	LDFile = outputPath + File.separator + "LD2.csv";
	File.append(newLine, LDFile);
	
}




