// script to a) extract perimeter from blue channel and b) analyze particles w/i region in green channel

#@ File (label = "Input directory", style = "directory") inputPath
#@ File (label = "Output directory", style = "directory") outputPath



files = getFileList(inputPath);
files = Array.sort(files);

// create output file
f = File.open(outputPath + File.separator + "LD.csv");
print(f, "Image,n,Avg Vol,Avg SA,Integrated Intensity Density,Subiculum Area,Z Stack");
File.close(f);
	
for (i = 0; i < files.length; i++) {
	image = files[i].substring(0, files[i].length());
	LD(image);
	waitForUser("Press OK to continue with next image");
	run("Clear Results");
	roiManager("reset");
	close("*");
}




function LD(image) {
	
	// open image w/ split channels
	open(inputPath + File.separator + image);
	
	waitForUser("Select the green channel");
	
	// note: scale is saved in each file as metadata (1.4425 pixels/micron)
	
	// calculate integrated intensity density TODO move this b4 threshold?
	run("Set Measurements...", "integrated redirect=None decimal=3");
	intDen = 0;
	for (i = 1; i <= nSlices; i++) {
	    setSlice(i);
	    run("Measure");
	    intDen += getResult("IntDen", i-1);
	}
	
	// manually convert to binary using threshold
	waitForUser("Set manual threshold (Ctrl+Shift+T)");
	
	// .2 microns <= radius <= 2 microns
	// 3D analysis uses volume constraint for min, max particle size
	run("Particle Analyser", "surface_area enclosed_volume min=0.0335 max=33.51 surface_resampling=2 surface=Gradient split=0.000 volume_resampling=2");

	// write to csv
	saveAs("Results", outputPath + File.separator + image + "_LD.csv");
	n = nResults;
	run("Summarize");
	avgVol = getResult("Vol. (microns³)", n);
	avgSA = getResult("SA (microns²)", n);
	subArea = getWidth * getHeight;
	zStack = nSlices;
	
	vars = newArray(image, n, avgVol, avgSA, intDen, subArea, zStack);
	newLine = String.join(vars, ",");
	LDFile = outputPath + File.separator + "LD.csv";
	File.append(newLine, LDFile);
	
}




