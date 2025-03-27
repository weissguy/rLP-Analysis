// split each czi file into 1) DAPI, 2) D54D2, 3) Iba1 channels
// save into a folder for each image (will be used for QuPath project)

#@ File (label = "Input directory", style = "directory") inputPath

files = getFileList(inputPath);
files = Array.sort(files);

for (i = 0; i < files.length; i++) {
	filename = files[i];
	processImage(filename);
	close("*");
}


function processImage(filename) {

	open(inputPath + File.separator + filename);
	
	mouse_id = getID(filename);
	
	File.makeDirectory(inputPath + File.separator + mouse_id);
	File.makeDirectory(inputPath + File.separator + mouse_id + File.separator + "qupath");
	
	selectImage(filename + " - C=0");
	saveAs("Tiff", outputFile(filename, mouse_id, "DAPI"));
	selectImage(filename + " - C=2");
	saveAs("Tiff", outputFile(filename, mouse_id, "Iba1"));
	selectImage(filename + " - C=3");
	saveAs("Tiff", outputFile(filename, mouse_id, "D54D2"));

}


function outputFile(filename, mouse_id, stain) {
	
	image = filename.substring(0, filename.length()-4);
	
	output = inputPath + File.separator + mouse_id + File.separator + image + "_" + stain;

	return output;
	
}


function getID(filename) {
	
	id_region = filename.substring(33, 43);
	
	for (i = 0; i < 40; i++) {
		if (id_region.indexOf(i) >= 0) {
			return "" + i;
		}
	}
	
}





