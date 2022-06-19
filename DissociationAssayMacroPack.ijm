var DAMenu = newMenu("Dissociation Assay Menu Tool", newArray("(1) Extractor", "(2) Excluder", "(3) Corrector", "-", "(4) Analyzer", "(5) Restitcher"));

macro "Dissociation Assay Menu Tool - C000T0d14DTad14A"{
	cmd = getArgument();
	
	if(cmd == "(1) Extractor"){
		prim_path = getDirectory("Please select primary directory");
		prim_fileList = getFileList(prim_path);
		
		seriesCountSum = 0;
		FirstFolderCreated = false;
		lifFiles = 0;
		skippedFiles = 0;
		
		for(i=0; i<prim_fileList.length; i++){
			if(substring(prim_fileList[i], prim_fileList[i].length-4, prim_fileList[i].length) == ".lif"){
				File.rename(prim_path+prim_fileList[i], replace(prim_path+prim_fileList[i], " ", "_"));
				prim_fileList = getFileList(prim_path);
				lifFiles++;
				run("Bio-Formats Macro Extensions");
				Ext.setId(prim_path+prim_fileList[i]);
				Ext.getCurrentFile(file);
				Ext.getSeriesCount(seriesCount);
				seriesCountSum += seriesCount;
			}
		}
		
		print("First Sum: "+seriesCountSum);
		
		for(i=0; i<prim_fileList.length; i++){
			FirstFolderCreated = false;
			firstImageTitleArray = newArray(2);
			if(substring(prim_fileList[i], prim_fileList[i].length-4, prim_fileList[i].length) != ".lif"){
				continue;
				skippedFiles++;
			}
			run("Bio-Formats Macro Extensions");
			Ext.setId(prim_path+prim_fileList[i]);
			Ext.getCurrentFile(file);
			Ext.getSeriesCount(seriesCount);
			
			for(j=0; j<prim_fileList.length; j++){
				if(prim_fileList[j] == substring(prim_fileList[i],0,lengthOf(prim_fileList[i])-4)+"/"){
					FirstFolderCreated = true;
					break;
				}
			}
			
			if(!FirstFolderCreated){
				firstImageTitleArray = extractImages(file, seriesCount, FirstFolderCreated, seriesCountSum);
				gridArray = getMostLikelyGrid(seriesCount-1-parseInt(firstImageTitleArray[1]));
			}
			else {
				sec_fileList = getFileList(substring(file,0,lengthOf(file)-4)+"\\");
				firstImageTitleArray[0] = sec_fileList[0];
				firstImageTitleArray[1] = sec_fileList.length;
				gridArray = getMostLikelyGrid(firstImageTitleArray[1]);
			}	
			
			seriesCountSum -= seriesCount;
			
			Grids = gridArray.length;
		
			output_filename = substring(firstImageTitleArray[0], 0, lengthOf(firstImageTitleArray[0])-5);
		
			selectWindow("Log");
			run("Close");
			if(!FirstFolderCreated){
				leicaWidth = firstImageTitleArray[2] + (firstImageTitleArray[2] * 0.2);
				leicaHeight = firstImageTitleArray[3] + (firstImageTitleArray[3] * 0.2);
				for(g=0; g<Grids; g+=2){
					if(abs((leicaWidth / gridArray[g])-1296) < abs((leicaWidth / gridArray[g+1])-1296)){
						showStatus("!Stitching...");
						run("Grid/Collection stitching", "type=[Grid: column-by-column] order=[Down & Left] grid_size_x="+gridArray[g]+" grid_size_y="+gridArray[g+1]+" tile_overlap=20 first_file_index_i=1 directory=["+replace(substring(file,0,lengthOf(file)-4), "\\", "/")+"] file_names=["+output_filename+"{i}.tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
						run("Set Scale...", "distance=1.4667 known=1 pixel=1 unit=Âµm");
						run("Scale...", "x=0.33 y=0.33 interpolation=Bilinear average create title=Stitched");
						saveAs("tiff", substring(file, 0, lengthOf(file)-4)+"-fusedByFiji-"+gridArray[g]+"x"+gridArray[g+1]+".tif");
						close();
						close();
					}
					else{
						showStatus("!Stitching...");
						run("Grid/Collection stitching", "type=[Grid: column-by-column] order=[Down & Left] grid_size_x="+gridArray[g+1]+" grid_size_y="+gridArray[g]+" tile_overlap=20 first_file_index_i=1 directory=["+replace(substring(file,0,lengthOf(file)-4), "\\", "/")+"] file_names=["+output_filename+"{i}.tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
						run("Set Scale...", "distance=1.4667 known=1 pixel=1 unit=Âµm");
						run("Scale...", "x=0.33 y=0.33 interpolation=Bilinear average create title=Stitched");
						saveAs("tiff", substring(file, 0, lengthOf(file)-4)+"-fusedByFiji-"+gridArray[g+1]+"x"+gridArray[g]+".tif");
						close();
						close();
					}
				}
			}
		}
		
		function extractImages(file, seriesCount, FirstFolderCreated, seriesCountSum){
			skippedImages = 0;
			firstImageTitleAndTArray = newArray(2);
			firstImageTitle = "";
			t2 = 0;
			meanArray = newArray();
			
			for (s=1; s<=seriesCount; s++) {
				if(t2>0 && s>1){
					imagesLeft = seriesCountSum - (s-1);
					print("Images Left: "+imagesLeft);
					
					lastLoop = (t2-t1)/1000;
					print("Last Loop: "+lastLoop);
					if(lastLoop>0){
						appendArray = newArray(1);
						appendArray[0] = lastLoop;
						
						meanArray = Array.concat(meanArray, appendArray);
						
						if(meanArray.length > 100){
							meanArray = Array.deleteIndex(meanArray, 0);
						}
						Array.show(meanArray);
						
						avgTimeSum = 0;
						for(avg = 0; avg<meanArray.length; avg++){
							avgTimeSum+=meanArray[avg];
						}
						averageTime = avgTimeSum/meanArray.length;
						print("Average Time: "+averageTime);
						timeLeft = round(averageTime*imagesLeft);
						print("Time left: "+timeLeft+" seconds\n");
						
						clock = convertSeconds(timeLeft);
						if(clock[0]<10){
							hours = "0"+toString(clock[0]);
						}
						else 
							hours = toString(clock[0]);
						if(clock[1]<10){
							minutes = "0"+toString(clock[1]);
						}
						else 
							minutes = toString(clock[1]);
						if(clock[2]<10){
							seconds = "0"+toString(clock[2]);
						}
						else 
							seconds = toString(clock[2]);
						showStatus("!Est. time left: "+hours+":"+minutes+":"+seconds+" (Extracting Image "+s+"/"+seriesCount+" of file "+(i+1-skippedFiles)+"/"+lifFiles+")");
					}
				}
				
				getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
				t1 = minute*60000+second*1000+msec;
				dontSave = false;
				t = s-skippedImages;
				run("Bio-Formats Importer", "open="+file+" autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+s);
				print("Original Title: "+getTitle());
				temp_string = replace(getTitle(),"/", "-");
				rename(substring(temp_string, 0, temp_string.length-4)+"-"+t+".tif");
				rename(replace(getTitle(), " ", "_"));
				
				if(s < seriesCount && matches(getTitle(), ".*(Merging).*")){
					dontSave = true;
					skippedImages++;
				}
		
				parts = split(getTitle(), "-");
				
				for(p = 0; p<parts.length; p++){
					if(matches(parts[p], ".*(TileScan).*")){
						parts = Array.deleteIndex(parts, p);
						p=0;
					}
				}
				
				newTitle = "";
		
				for(p = 0; p<parts.length; p++){
					if(p < parts.length-1)
						newTitle+=parts[p]+"-";
					else 
						newTitle+=parts[p];
				}
				
				rename(newTitle);
				print("Renamed to: "+newTitle);
				
				if(s==1){
					firstImageTitle += getTitle();
					print("First file name: "+firstImageTitle);
				}
				
				if(!FirstFolderCreated){
					File.makeDirectory(substring(file,0,lengthOf(file)-4)+"\\");
					FirstFolderCreated=true;
				}
				
				run("8-bit");
				
				out_path = substring(file,0,lengthOf(file)-4)+"\\"+getTitle();
				
				if(s == seriesCount && !dontSave){
					out_path = substring(file, 0, lengthOf(file)-4)+"-fusedByLeica.tif";
					getDimensions(leicaWidth, leicaHeight, channels, slices, frames);
					run("Scale...", "x=0.5 y=0.5 interpolation=Bilinear average create");
					saveAs("jpeg", out_path);
				}
				else if(!dontSave)
					saveAs("tiff", out_path);
					
				run("Close All");
				
				getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
				t2 = minute*60000+second*1000+msec;
			}
			
			firstImageTitleAndTArray[0] = firstImageTitle;
			firstImageTitleAndTArray[1] = toString(skippedImages);
			firstImageTitleAndTArray[2] = leicaWidth;
			firstImageTitleAndTArray[3] = leicaHeight;
			return firstImageTitleAndTArray;
		}
		
		function getMostLikelyGrid(seriesCount){
			Counter = 0;
			Mult = newArray(1600);
			for(i=1;i<=40;i++){
				for(j=1;j<=40;j++){
					Mult[Counter] = i*j;
					Counter++;
				}
			}
			Grids = 0;
			GridColumnArray = newArray(20);
			GridLineArray = newArray(20);
			
			for(i=0;i<=1599;i++){
				if(Mult[i] == seriesCount){
			
					number1 = floor((i)/40)+1;
					number2 = Mult[i]/number1;
					
					//Check if there are more than double the number of columns/lines than the other
					if(number1/number2 > 0.5 && number1/number2 < 2 && number1<number2 || number1 == number2)
					{
						GridColumnArray[Grids] = number1;
						GridLineArray[Grids] = number2;
						Grids++;
					}
				}
			}
			GridColumnArray = Array.slice(GridColumnArray, 0, Grids);
			GridLineArray = Array.slice(GridLineArray, 0, Grids);
			returnArray = newArray(GridColumnArray.length*2);
			
			for(i=0; i<GridColumnArray.length; i++){
				returnArray[2*i] = GridColumnArray[i];
			}
			
			for(i=0; i<GridLineArray.length; i++){
				returnArray[(2*i)+1] = GridLineArray[i];
			}
			Array.print(returnArray);
			return returnArray;
		}
		
		function convertSeconds(runningTime){
			timeArray = newArray(3);
			if(runningTime >= 60){
				Minutes = floor(runningTime/60);
				Seconds = runningTime%60;
				
				if(Minutes >= 60){
					Hours = floor(Minutes/60);
					Minutes = Minutes%60;
					timeArray[0] = Hours;
					timeArray[1] = Minutes;
					timeArray[2] = Seconds;
				}
				else
				{
					timeArray[0] = 0;
					timeArray[1] = Minutes;
					timeArray[2] = Seconds;
				}
			}
			else{
				timeArray[0] = 0;
				timeArray[1] = 0;
				timeArray[2] = runningTime;
			}
			
			return timeArray;
		}
	}
	
	if(cmd == "(2) Excluder"){
		surr_folder = getDir("Please choose primary folder");
		surr_FileList = getFileList(surr_folder);
		
		for(j=0; j<surr_FileList.length; j++){
			skip = false;
			if(matches(surr_FileList[j], ".*(.tif)|.*(.jpg)|.*(.txt)")){
				continue;
			}
			
			tile_folder = surr_FileList[j];
			tile_FileList = getFileList(surr_folder+tile_folder);
			
			for(i=0; i<tile_FileList.length; i++){
				File.rename(surr_folder+tile_folder+tile_FileList[i], replace(surr_folder+tile_folder+tile_FileList[i], " ", "_"));
			}
			
			firstFileName = replace(tile_FileList[0], "-1.tif", "-{i}.tif");
			
			for(s=0; s<surr_FileList.length; s++){
				if(matches(surr_FileList[s], replace(tile_folder, "/", "")+"(-fusedByFiji-).*")){
					fiji_fuse = split(surr_FileList[s], "-");
					xy = split(fiji_fuse[fiji_fuse.length-1], "x");
					
					xElements = parseInt(xy[0]);
					yElements = parseInt(replace(xy[1], ".tif", ""));
					break;
				}
				else if(s == surr_FileList.length-1){
					showMessage("No pre-stitched image containing dimensions was found. Continuing with next image.");
					skip = true;
				}
			}
			 
			if(skip)
				continue;
				 
			run("Grid/Collection stitching", "type=[Grid: column-by-column] order=[Down & Left] grid_size_x="+xElements+" grid_size_y="+yElements+" tile_overlap=0 first_file_index_i=1 directory="+surr_folder+tile_folder+" file_names="+firstFileName+" output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
			File.delete(surr_folder+tile_folder+"TileConfiguration.txt");
			
			run("Scale...", "x=0.33 y=0.33 interpolation=Bilinear average create");
			selectImage(1);
			close();
			getDimensions(width, height, channels, slices, frames);
			run("RGB Color");
			
			endNow = false;
			excludeArray = newArray();
			appendArray = newArray(1);
			
			setColor(255,0,0);
			setLineWidth(5);
			
			for(x=1; x<=xElements; x++){
				drawLine(x*(width/xElements), 0, x*(width/xElements), height);
			}
			
			for(y=1; y<=yElements; y++){
				drawLine(0, (y*height/yElements), width, (y*height/yElements));
			}
			
			updateDisplay();
			
			run("Duplicate...", " ");
			fontSize = height/50;
			setFont("SansSerif", fontSize, "bold");
			
			for(i=1; i<=xElements*yElements; i++){
				xRect = abs(Math.ceil(i/yElements)-(xElements+1));
				yRect = i%yElements;
				if(yRect == 0)
					yRect = yElements;
				
				drawString(i, (xRect/xElements*width)-(width/xElements), yRect/yElements*height);
			}
		
			saveAs("jpeg", surr_folder+replace(tile_folder, "/", "")+"-tileNumbers.jpg");
			close();
			
			while(!endNow){
				getCursorLoc(x, y, z, modifiers);
				x = abs(x-width);
				
				xRect = Math.ceil(x/width*xElements);
				yRect = Math.ceil(y/height*yElements);
				excludeImage = (xRect-1)*yElements+yRect;
				
				if(modifiers == 18){
					endNow = true;
				}
				if(modifiers == 19){
					excludeArray[0] = "no correction";
					break;
				}
				if(modifiers == 16){
					setLineWidth(15);
					setColor(255, 0, 0);
					xRect = Math.ceil(abs(x-width)/width*xElements);
					fillRect((xRect-1)*width/xElements, (yRect-1)*height/yElements, width/xElements, height/yElements);
					setColor(0,0,0);
					drawLine((xRect-1)*width/xElements, (yRect-1)*height/yElements, ((xRect-1)*width/xElements)+width/xElements, ((yRect-1)*height/yElements)+height/yElements);
					drawLine((xRect-1)*width/xElements, ((yRect-1)*height/yElements)+height/yElements, ((xRect-1)*width/xElements)+width/xElements, (yRect-1)*height/yElements);
					appendArray[0] = excludeImage;
					if(excludeArray.length > 0){
						if(excludeArray[excludeArray.length-1] != appendArray[0]){
							excludeArray = Array.concat(excludeArray, appendArray);
						}
					}
					else{
						excludeArray = Array.concat(excludeArray, appendArray);
					}
				}
				wait(10);
			}
			
			Array.print(excludeArray);
			selectWindow("Log");
			excludeFile = File.open(surr_folder+replace(tile_folder, "/", "")+"_exclude.txt");
	
			for(i=0; i<excludeArray.length; i++){
				print(excludeFile, excludeArray[i]);
			}
	
			File.close(excludeFile);
			run("Close All");
			showStatus("Done! ("+fromCharCode(65417, 9685, 12526, 9685)+")"+fromCharCode(65417)+"*:"+fromCharCode(12539, 12444, 10023));
		}
	}
	
	if(cmd == "(3) Corrector"){
		path = getDirectory("Please select primary folder.");
		prim_folderList = getFileList(path);
		only_foldersList = newArray(prim_folderList.length);
		
		CIRCLE_RADIUS = 600;
		CIRCLE_WIDTH =  400;
		X_OVALITY = 1.1;
		Y_OVALITY = 1.0;
		BLUR = 85;
		
		X_DISTORTION = 0.7;
		Y_DISTORTION = 0.7;
		BIG_X_OFFSET = 100;
		BIG_Y_OFFSET = 80;
		SMALL_X_OFFSET = 40;
		SMALL_Y_OFFSET = 40;
		
		secCircleRadius = CIRCLE_RADIUS+CIRCLE_WIDTH;
		CircleOpen = "";
		
		//Calculate oval height and width with ovality included
		resultingPrimCircleWidth = CIRCLE_RADIUS / sqrt(X_OVALITY);
		resultingPrimCircleHeight = CIRCLE_RADIUS / sqrt(Y_OVALITY);
		resultingSecCircleWidth = (CIRCLE_RADIUS+CIRCLE_WIDTH) / sqrt(X_OVALITY);
		resultingSecCircleHeight = (CIRCLE_RADIUS+CIRCLE_WIDTH) / sqrt(Y_OVALITY);
		
		//Find .txt, .tif, .jpg in primary folder
		appendArray = newArray(1);
		removeArray = newArray();
		for(r=0; r<prim_folderList.length; r++){
			if(matches(prim_folderList[r], ".*(.tif)|.*(.jpg)|.*(.txt)")){
				appendArray[0] = prim_folderList[r];
				removeArray = Array.concat(removeArray, appendArray);
			}
		}
		
		//Remove those entries from iteration array
		for(r2=0; r2<removeArray.length; r2++){
			if(r2==0)
				only_foldersList = Array.deleteValue(prim_folderList, removeArray[r2]);
			else
				only_foldersList = Array.deleteValue(only_foldersList, removeArray[r2]);
		}
		
		for(k=0; k<only_foldersList.length; k++){
			run("Clear Results");
			
			//Try to find exclude txt file matching folder
			for(g=0; g<prim_folderList.length; g++){
				if(prim_folderList[g] == replace(only_foldersList[k],"/","")+"_exclude.txt"){
					excludeFile = File.openAsRawString(path+prim_folderList[g]);
					excludeList = split(excludeFile, "\n");
					break;
				}
				else if(g == prim_folderList.length-1){
					excludeList = newArray();
					showMessage("No exclude.txt file was found. Continuing without.");
				}
			}
			
			if(excludeList.length > 0){
				if(excludeList[0] == "no correction"){
					continue;
				}
			}
			
			sec_path = path+only_foldersList[k];
			sec_fileList = getFileList(sec_path);
		
			arr2 = newArray(sec_fileList.length);
			Two=false;
			Three=false;
			folder1=false;
			folder2=false;
			
			gridArray = newArray(2);
			
			for(s=0; s<prim_folderList.length; s++){
				if(matches(prim_folderList[s], replace(only_foldersList[k], "/", "")+"(-fusedByFiji-).*")){
					fiji_fuse = split(prim_folderList[s], "-");
					xy = split(fiji_fuse[fiji_fuse.length-1], "x");
					
					gridArray[0] = parseInt(xy[0]);
					gridArray[1] = parseInt(replace(xy[1], ".tif", ""));
				}
			}

			sortArrayAlphaNumerically(sec_fileList, Two, Three, arr2);
			
			for(i=0; i<arr2.length;i++){
				//Create corrected folder if there is none
				if(!folder1){
					File.makeDirectory(sec_path+"\\corrected");
					folder1=true;
				}
				skipImage = false;
				
				//Skip if image is part of excludeList and copy original image into corrected folder as a
				//replacement
				for(ex=0; ex<excludeList.length; ex++){
					if((i+1) == excludeList[ex]){
						skipImage = true;
						print("Copying original tile "+arr2[i]);
						File.copy(replace(sec_path, "/", "")+"\\"+arr2[i], replace(sec_path, "/", "")+"\\corrected\\"+arr2[i]); 
						break;
					}
				}
				
				//Jump to next image, if image is skipped
				if(skipImage){
					continue;
				}
				
				probscore_of_previous = 10000;
				best_grid_position = 0;
				run("Close All");
				open(sec_path+arr2[i]);
				
				Spalte = getColumn(i, gridArray[0], gridArray[1]);
				Zeile = getLineCustom(i, gridArray[0], gridArray[1]);	
					
				BigGridXOffset = ((Spalte*(-1))*BIG_X_OFFSET)-(Spalte*X_DISTORTION*Zeile*Zeile);
				BigGridYOffset = (Zeile*BIG_Y_OFFSET)+(Zeile*Y_DISTORTION*Spalte*Spalte);
			
				run("Clear Results");
				run("Set Measurements...", "modal redirect=None decimal=3 limit");
				
				makeOval((5184/2)-resultingSecCircleWidth, (3864/2)-resultingSecCircleHeight, resultingSecCircleWidth*2, resultingSecCircleHeight*2);
				setKeyDown("alt");
				makeOval((5184/2)-resultingPrimCircleWidth, (3864/2)-resultingPrimCircleHeight, resultingPrimCircleWidth*2, resultingPrimCircleHeight*2);
				
				for(j=1;j<=289;j++){
					GridXRow = ((j%17)+1)-9;
					GridYRow =  (Math.ceil((j+1)/17))-9;
					SmallGridXOffset = GridXRow * SMALL_X_OFFSET;
					SmallGridYOffset = GridYRow * SMALL_Y_OFFSET;
				
					getDimensions(width, height, channels, slices, frames);
					Roi.move((width/2)-BigGridXOffset-resultingSecCircleWidth+SmallGridXOffset,(height/2)-BigGridYOffset-(resultingSecCircleHeight)+SmallGridYOffset);
					getStatistics(area, mean, min, max, std);
					probability_score = mean*std;
					showStatus("!Column: "+Spalte+", Row: "+Zeile+", trying "+j+"/289 (Image "+(i+1)+"/"+arr2.length+"), "+probability_score+" ("+probscore_of_previous+")");
					
					if(probability_score < probscore_of_previous){
						best_grid_position = j;
						//print("Best Grid Position: "+best_grid_position);
						probscore_of_previous = probability_score;
					}
					if(j==289){
						GridXRow = ((best_grid_position%17)+1)-9;
						GridYRow =  (Math.ceil((best_grid_position+1)/17))-9;
						print("Best Position: "+best_grid_position);
						SmallGridXOffset = GridXRow*SMALL_X_OFFSET;
						SmallGridYOffset = GridYRow*SMALL_Y_OFFSET;
						makeOval((5184/2)-resultingSecCircleWidth, (3864/2)-resultingSecCircleHeight, resultingSecCircleWidth*2, resultingSecCircleHeight*2);
						setKeyDown("alt");
						makeOval((5184/2)-resultingPrimCircleWidth, (3864/2)-resultingPrimCircleHeight, resultingPrimCircleWidth*2, resultingPrimCircleHeight*2);
						Roi.move((width/2)-BigGridXOffset-resultingSecCircleWidth+SmallGridXOffset,(height/2)-BigGridYOffset-(resultingSecCircleHeight)+SmallGridYOffset);
						run("Measure");
						shadowValue = getResult("Mode", 0);
						run("Clear Results");
						run("Make Inverse");
						run("Measure");
						run("Select None");
						modalValue = getResult("Mode", 0);
						brightness = modalValue - shadowValue+10;
						newImage("Circle", "8-bit black", 1296, 966, 1);
						makeOval((5184/2)-resultingSecCircleWidth, (3864/2)-resultingSecCircleHeight, resultingSecCircleWidth*2, resultingSecCircleHeight*2);
						setKeyDown("alt");
						makeOval((5184/2)-resultingPrimCircleWidth, (3864/2)-resultingPrimCircleHeight, resultingPrimCircleWidth*2, resultingPrimCircleHeight*2);
						Roi.move((width/2)-BigGridXOffset-resultingSecCircleWidth+SmallGridXOffset,(height/2)-BigGridYOffset-(resultingSecCircleHeight)+SmallGridYOffset);
						setColor(255,255,255);
						run("Fill", "slice");
						run("Select None");
						setMinAndMax(0+255-brightness, 255+255-brightness);
						run("Apply LUT");
						run("Gaussian Blur...", "sigma="+BLUR);
						imageCalculator("Add create", arr2[i], "Circle");
						/*run("Clear Results");
						run("Select None");
						
						getHistogram(values, counts, 256);
						Plot.create("Histogram", "Pixel Value", "Count", values, counts);
						Plot.show();
						run("Find Peaks", "min._peak_amplitude=1000 min._peak_distance=10 min._value=[] max._value=[] exclude list");
						selectWindow("Plot Values");
						max1 = Table.get("X1", 0);
						max2 = Table.get("X1", 1);
						max3 = Table.get("X1", 2);
						max4 = Table.get("X1", 3);
						
						peakArray = newArray(max1, max2, max3, max4);
						peakArray = Array.deleteValue(peakArray, NaN);
						Array.print(peakArray);
						
						if(peakArray.length != 0){
							mode = peakArray[0];
						}
						else
							mode = NaN;	
						
						selectWindow(arr2[i]);					
						getMinAndMax(min, max);
					
						if(mode<92 && !isNaN(mode)){
							setMinAndMax(min-(92-mode), max-(92-mode));
							run("Apply LUT");
						}
						else if (!isNaN(mode)){
							setMinAndMax(min+(mode-92), max+(mode-92));
							run("Apply LUT");
						}*/
						//getMinAndMax(min, max);
						//setMinAndMax(min+25, max-25);
						out_path = sec_path+"corrected\\"+arr2[i];
						saveAs("tiff", out_path);
						//saveAs("tiff", path+substring(fileList[i], 0, lengthOf(fileList[i])-4)+"_("+best_grid_position+" "+std_of_previous+" -"+(first_std-std_of_previous)/first_std*100+"%)");
					}
				}
			}
			run("Clear Results");	
			open(sec_path+"Corrected\\"+arr2[0]);
			output_filename = substring(getTitle(), 0, lengthOf(getTitle())-5);
			Grids = gridArray.length;
			
			for(g=0; g<Grids; g+=2){
				showStatus("!Stitching...");
				run("Grid/Collection stitching", "type=[Grid: column-by-column] order=[Down & Left] grid_size_x="+gridArray[g]+" grid_size_y="+gridArray[g+1]+" tile_overlap=20 first_file_index_i=1 directory=["+sec_path+"] file_names=["+output_filename+"{i}.tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
				run("Set Scale...", "distance=1.4667 known=1 pixel=1 unit="+fromCharCode(181)+"m");
				run("Scale...", "x=0.33 y=0.33 interpolation=Bilinear average create title=Stitched");
				saveAs("tiff", path+substring(only_foldersList[k], 0, only_foldersList[k].length-1)+"-correctedByFiji-"+gridArray[g]+"x"+gridArray[g+1]+".tif");
				close();
				close();
				
				/*if(gridArray[g] != gridArray[g+1]){
					run("Grid/Collection stitching", "type=[Grid: column-by-column] order=[Down & Left] grid_size_x="+gridArray[g+1]+" grid_size_y="+gridArray[g]+" tile_overlap=20 first_file_index_i=1 directory=["+sec_path+"] file_names=["+output_filename+"{i}.tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
					run("Set Scale...", "distance=1.4667 known=1 pixel=1 unit=Âµm");
					run("Scale...", "x=0.33 y=0.33 interpolation=Bilinear average create title=Stitched");
					saveAs("tiff",path+substring(prim_folderList[k], 0, prim_folderList[k].length-1)+"-correctedByFiji-"+gridArray[g+1]+"x"+gridArray[g]+".tif");
					close();
					close();
				}*/
			}
		}
		
		run("Close All");
		showStatus("Done! ("+fromCharCode(65417, 9685, 12526, 9685)+")"+fromCharCode(65417)+"*:"+fromCharCode(12539, 12444, 10023));
		
		function sortArrayAlphaNumerically(a, Two, Three, arr2){
			for(b=0;b<a.length;b++){
				str = a[b];
				substr = substring(str, lengthOf(str)-7, lengthOf(str)-4);
			
				for(c=0;c<3;c++){
					if(isNaN(parseInt(substring(substr,c,c+1)))){
						Three = true;
						break;
					}
					if(c==2){
						index = parseInt(substr);
					}
				}
				if(Three){
					substr = substring(str, lengthOf(str)-6, lengthOf(str)-4);
					
					for(d=0;d<2;d++){
						if(isNaN(parseInt(substring(substr,d,d+1)))){
							Two = true;
							break;
							
						}
						if(d==1){
							index = parseInt(substr);
						}
					}
					if(Two){
						substr = substring(str, lengthOf(str)-5, lengthOf(str)-4);
						index = parseInt(substr);
					}
				}
				
				Two=false;
				Three=false;
				arr2[index-1] = str;
			}
		}
		
		function getColumn(i, xGrid, yGrid){
			Column = Math.ceil((i+1)/yGrid);
		
			if(xGrid%2==0 && Spalte<=xGrid/2)
				Column-=Math.ceil(xGrid/2)+1;
			else
				Column-=Math.ceil(xGrid/2);
				
			return Column;
		}
		
		function getLineCustom(i, xGrid, yGrid){
			if((i+1)%yGrid == 0)
				Line = yGrid;
			else
				Line = (i+1)%yGrid;
		
			if(yGrid%2==0 && Line<=yGrid/2)
				Line-=Math.ceil(yGrid/2)+1;
			else
				Line-=Math.ceil(yGrid/2);
		
			return Line;
		}
	}
	
	if(cmd == "(4) Analyzer"){
		run("Clear Results");
		path = getDirectory("image");
		titleArray = split(getTitle(), "-");
		title = titleArray[0];
		run("Set Measurements...", "area perimeter bounding shape feret's limit redirect=None decimal=3");
		run("Duplicate...", "title=Base");
		selectImage(1);
		run("Pseudo flat field correction", "blurring=70 hide");
		getMinAndMax(min, max);
		setMinAndMax(min+15, max-15);
		getDimensions(width, height, channels, slices, frames);
		makeOval((width/2)-(3746/2), (height/2)-(3746/2), 3746, 3746);
		setTool(1);
		waitForUser("Please adjust circle.");
		run("Make Inverse");
		setTool("dropper");
		waitForUser("Please select mean grey by clicking.");
		run("Fill", "slice");
		run("Select None");
		run("Median...", "radius=7");
		rename("Base2");
		run("Duplicate...", "title=Edges");
		run("Find Edges");
		getMinAndMax(min, max);
		setMinAndMax(min, max-100);
		setThreshold(50, 255);
		run("Create Mask");
		imageCalculator("Add create", "Base2","mask");
		setThreshold(0, 94);
		run("Create Mask");
		run("Analyze Particles...", "size=3000-Infinity show=[Count Masks] display clear summarize overlay add");
		selectWindow("Base");
		rename(title);
		run("From ROI Manager");
		run("Labels...", "color=white font=12 show draw bold");
		
		endNow = false;
		counter = 100;
		
		while(!endNow){
			getCursorLoc(x, y, z, modifiers);
			if(modifiers == 18){
				endNow = true;
			}
			else{
				if(Overlay.hidden && counter <= 0){
					Overlay.show();
					counter = 100;
				}
				else if(!Overlay.hidden && counter <= 0){
					Overlay.hide();
					counter = 100;
				}
			}
			counter--;
			wait(10);
		}
		run("Read and Write Excel", replace("file=["+path+title+".xlsx]", "\\", "/"));
		run("Close All");
		exit();
	}
	
	if(cmd == "(5) Restitcher"){
		tile_folder = getDirectory("Please select tile folder.");
		surr_lines = split(tile_folder, "\\");	
		tile_folder+="corrected";
		tile_FileList = getFileList(tile_folder);
		
		surr_folder = "";
		tile_folderName = surr_lines[surr_lines.length-1];
		
		firstFileName = replace(tile_FileList[0], "-1.tif", "-{i}.tif");
		
		for(f=0; f<surr_lines.length-1; f++){
			surr_folder+=surr_lines[f]+"\\";
		}
		
		surr_FileList = getFileList(surr_folder);
		gridArray = newArray(2);
		
		for(s=0; s<surr_FileList.length; s++){
			if(matches(surr_FileList[s], replace(tile_folderName, "/", "")+"(-fusedByFiji-).*")){
				fiji_fuse = split(surr_FileList[s], "-");
				xy = split(fiji_fuse[fiji_fuse.length-1], "x");
				
				gridArray[0] = parseInt(xy[0]);
				gridArray[1] = parseInt(replace(xy[1], ".tif", ""));
			}
		}
		
		showStatus("!Stitching...");
		run("Grid/Collection stitching", "type=[Grid: column-by-column] order=[Down & Left] grid_size_x="+gridArray[0]+" grid_size_y="+gridArray[1]+" tile_overlap=20 first_file_index_i=1 directory=["+tile_folder+"] file_names=["+firstFileName+"] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
		run("Set Scale...", "distance=1.4667 known=1 pixel=1 unit="+fromCharCode(181)+"m");
		run("Scale...", "x=0.33 y=0.33 interpolation=Bilinear average create title=Stitched");
		saveAs("tiff", surr_folder+replace(tile_folderName, "/", "")+"-correctedByFiji-"+gridArray[0]+"x"+gridArray[1]+".tif");
		close();
		close();
	}
}
