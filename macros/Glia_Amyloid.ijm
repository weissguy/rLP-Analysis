// analyze glia and amyloid IID in hippocampus region (manually selected) -- TODO: train a simple neural net to identify hippocampus region

#@ File (label = "Input directory", style = "directory") inputPath
#@ File (label = "Output directory", style = "directory") outputPath

files = getFileList(inputPath);
files = Array.sort(files);


// create output file
dataFile = outputPath + File.separator + "data.csv";
f = File.open(dataFile);
print(f, "Image,Area,D54D2,Iba1");
File.close(f);


for (i = 0; i < files.length; i++) {
	filename = files[i].substring(0, files[i].length() - 4);
	processImage(filename);
	run("Clear Results");
	close("*");
}


function processImage(filename) {
	
	run("Set Measurements...", "area integrated redirect=None decimal=3");

	// select ROI using DAPI stain
	open(inputPath + File.separator + "DAPI" + File.separator + filename + "_DAPI.tif");
	waitForUser("Select the hippocampus region");
	run("Measure");
	area = getResult("Area", 0);
	
	
	// get amyloid IID in ROI
	open(inputPath + File.separator + "D54D2" + File.separator + filename + "_D54D2.tif");
	run("Restore Selection");
	run("Measure");
	d54d2 = getResult("IntDen", 1);
	

	// get Iba1 IID in ROI
	open(inputPath + File.separator + "Iba1" + File.separator + filename + "_Iba1.tif");
	run("Restore Selection");
	run("Measure");
	iba1 = getResult("IntDen", 2);
	
	
	// write csv with data
	newLine = filename + "," + area + "," + d54d2 + "," + iba1;
	print(newLine);
	File.append(newLine, dataFile);

}






