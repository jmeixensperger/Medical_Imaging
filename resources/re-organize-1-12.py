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
        if os.listdir( patientDirPath ) == []:
            os.remove(patientDirPath)

main()
