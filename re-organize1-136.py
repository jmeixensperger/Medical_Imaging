import os 
import shutil

def main() :

    for i in range(1,137):
        patientNum = "patient" + str(i)
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
	    for class in Classes:
		classDirPath = patientDirPath + '/' + class
		if not os.path.exist( classDirPath )
                    os.makedirs( classDirPath )
	    	if file.startswith( class )
                    shutil.move( file, classDirPath ) 
        if os.listdir( patientDirPath ) == []:
            os.rmdir(patientDirPath)

main()
