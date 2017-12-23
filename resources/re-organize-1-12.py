import os
import shutil

def main() :
	for i in range(1,13):
		patientNum = "patient-1_" + str(i)
		globalPath = "/Users/#ENTER_USER#/Desktop/Medical_Imaging/converted/"
		patientDirPath = globalPath + patientNum
		patientPic = patientNum + ".jpg"
		if not os.path.exists(patientDirPath):
			os.makedirs( patientDirPath )
		for f in os.listdir(globalPath) :
			if f.endswith( patientPic ) :
				patientCurPath = globalPath  + f
				shutil.move(patientCurPath, patientDirPath )
		f = os.listdir(patientDirPath)
		for file in os.listdir( patientDirPath ):
			Classes = ["healthy", "emphysema", "fibrosis", "ground_glass", "micronodules" ]
			for classes in Classes:
				classDirPath = patientDirPath + '/' + classes
				if not os.path.exists( classDirPath ):
					os.makedirs( classDirPath )
				if file.startswith( classes ):
					filePath = patientDirPath + '/' + file
					classPath = classDirPath + '/' + file
					shutil.move( filePath, classDirPath )

		if os.listdir( patientDirPath ) == []:
			os.remove(patientDirPath)

main()
