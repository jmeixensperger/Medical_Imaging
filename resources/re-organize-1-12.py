import os 
import shutil

def main() :
    for i in range(1,13):
        patientNum = "patient-1_" + str(i)
        patientDirPath = "/Users/student/Desktop/converted/" + patientNum
        patientPic = patientNum + ".jpg"
        if not os.path.exists(patientDirPath):
            os.makedirs( patientDirPath )
        for f in os.listdir( "/Users/student/Desktop/converted") :
            if f.endswith( patientPic ) :
                patientCurPath = "/Users/student/Desktop/converted/" + f
                shutil.move(patientCurPath, patientDirPath )
        for file in os.listdir( patientDirPath ):
            Classes = ["healthy", "emphysema", "fibrosis", "ground_glass", "micronodules" ]
	        for classes in Classes:
		        classDirPath = patientDirPath + '/' + classes
		        if not os.path.exists( classDirPath ):
                    		os.makedirs( classDirPath )
	    	    	if file.startswith( classes ):
                    		filePath = "/Users/student/Desktop/converted/" + file
                    		classPath = classDirPath + '/' + file
                    		shutil.move( filePath, classDirPath ) 
                
        if os.listdir( patientDirPath ) == []:
            os.remove(patientDirPath)

main()
