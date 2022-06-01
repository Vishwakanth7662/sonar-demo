import os

versionLimit = {
	"NODEJS": {
		"dotVersionRange": ["0", "16.99.99"],
		"intVersionRange": ["0", "16"],
		"framework": {
			"REACT": {
				# Only support 0.13–16.x.x
				"dotVersionRange": ["0.13", "17.0"],
				"intVersionRange": ["0", "17"]
			},
			"EXPRESS": {
				# Only support 0–4.17.1
				"dotVersionRange": ["0.4", "4.17.2"],
				"intVersionRange": ["0", "4"]
			},
			"ANGULAR": {
				# Only support 0-1.x, 2.x, 4.x–11.x, there's no angular 3.x in the world
				"dotVersionRange": ["0", "11.0"],
				"intVersionRange": ["0", "11"]
			}
		},
		"referenceLink": "https://help.veracode.com/r/compilation_jscript"
	},
	"JAVA": {
		"dotVersionRange": ["1.4", "1.9"],
		"intVersionRange": ["8", "15"],
		"framework": {
			"SPRINGBOOT": {
				# only support 1.x, 2.x
				"dotVersionRange": ["1.0.0", "2.99.99"],
				"intVersionRange": ["1", "2"]
			}
		},
		"referenceLink": "https://help.veracode.com/r/compilation_java"
	},
	"PYTHON": {
		"dotVersionRange": ["1.9", "4.0"],
		"intVersionRange": ["1", "4"],
		"framework": {
			"FLASK": {
				# Veracode doc shows only support 0.x, but I can send version 1.x, so I will leave it for now
				"dotVersionRange": ["0", "2.0"],
				"intVersionRange": ["0", "2"]
			},
			"DJANGO": {
				# Only support 1.x, 2.x
				"dotVersionRange": ["0", "4.0"],
				"intVersionRange": ["0", "4"]
			}
		}
	},
	"PHP": {
		"dotVersionRange": ["5.2", "7.5"],
		"intVersionRange": ["5", "7"],
		"framework": {
			"CODEIGNIGHTOR": {
				"dotVersionRange": ["0", "4.0.4"],
				"intVersionRange": ["0", "4"]
			}
		}
	}
}

class Detector():
	def __init__(self, language=None, languageVersion=None, framework=None, frameworkVersion=None, pkg_manager=None):
		self.language = language
		self.languageVersion = languageVersion
		self.framework = framework
		self.frameworkVersion = frameworkVersion
		self.pkg_manager = pkg_manager

	def output(self):
		print("The project is using: ", self.language)
		print("languageVersion: ", self.languageVersion)
		print("Framework: ", self.framework)
		print("frameworkVersion: ", self.frameworkVersion)
		print("package manager: ", self.pkg_manager)

	def handleErrorMsg(self, msg, link=None, versionRange=None):
		print("Error: " + msg)
		print("Reference Link: ", link)
		if(versionRange):
			print("Language version support from: {} - {}".format(versionRange[0], versionRange[1]))

	def issueVeracodeShell(self, pkg_manager):
		languageFolderPath = "/veracode/detection/languages/pkgs_scripts/"
		os.system("chmod +x " + languageFolderPath + pkg_manager + "/veracode.sh")
		os.system("bash " + languageFolderPath + pkg_manager + "/veracode.sh")

	def dotVersionCompare(self, v1, v2):
		# This will split both the versions by '.'
		# converts to integer from string
		arr1 = [int(i) for i in v1.split(".")]
		arr2 = [int(i) for i in v2.split(".")]
		n = len(arr1)
		m = len(arr2)

		# compares which list is bigger and fills
		# smaller list with zero (for unequal delimeters)
		if(n > m):
			for i in range(m, n):
				arr2.append(0)
		elif(m > n):
			for i in range(n, m):
				arr1.append(0)

		# returns 1 if version 1 is bigger and -1 if
		# version 2 is bigger and 0 if equal
		for i in range(len(arr1)):
			if(arr1[i] > arr2[i]):
				return 1
			elif(arr2[i] > arr1[i]):
				return 0

	def versionComparison(self, projectVersion, targerVersionList):
		if(projectVersion >= targerVersionList[0] and projectVersion <= targerVersionList[1]):
			return True
		return False


if __name__ == "__main__":
	# Raven MX
	# VERACODE_TYPE_ENV = "NODEJS_10.16.3_EXPRESS_4.15.3_NPM".split("_")
	# VERACODE_TYPE_ENV = "NODEJS_10.16.3_EXPRESS_4.15.3_NPM".split("_")
	# Enterprise
	# VERACODE_TYPE_ENV = "JAVA_1.8_SPRINGBOOT_2.1.7_MAVEN".split("_")
	# FD UI
	# VERACODE_TYPE_ENV = "NODEJS_10_REACT_16.8.3_YARN".split("_")
	# TELESCOPE
	# VERACODE_TYPE_ENV = "PYTHON_3.5_FLASK_1.0.2_PIP".split("_")

	# Activation Event Loader
	# VERACODE_TYPE_ENV = "PYTHON_3.7_PIP".split("_")
	# VERACODE_TYPE_ENV = "NODEJS_14.2_NPM".split("_")

	
	VERACODE_TYPE_ENV = None
	if(os.getenv("CI_PROJECT_NAME") == "distillery"):
		VERACODE_TYPE_ENV = os.getenv("EACH_APP_VERSION").split("_")
	elif(os.getenv("CI_PROJECT_NAME") == "enterprise"):
		VERACODE_TYPE_ENV = os.getenv('VERACODE_TYPE').split("_")
	else:
		VERACODE_TYPE_ENV = os.getenv('VERACODE_TYPE').split("_")



	if(len(VERACODE_TYPE_ENV) == 5):
		language = VERACODE_TYPE_ENV[0]
		languageVersion = VERACODE_TYPE_ENV[1]
		framework = VERACODE_TYPE_ENV[2]
		frameworkVersion = VERACODE_TYPE_ENV[3]
		pkg_manager = VERACODE_TYPE_ENV[4]

		project = Detector(language, languageVersion, framework, frameworkVersion, pkg_manager)

		dotLanguageVersionLimit = versionLimit[project.language]["dotVersionRange"]
		intLanguageVersionLimit = versionLimit[project.language]["intVersionRange"]
		dotFrameworkVersionLimit = versionLimit[project.language]["framework"][project.framework]["dotVersionRange"]
		intFrameworkVersionLimit = versionLimit[project.language]["framework"][project.framework]["intVersionRange"]

	if(len(VERACODE_TYPE_ENV) == 3):
		language = VERACODE_TYPE_ENV[0]
		languageVersion = VERACODE_TYPE_ENV[1]
		pkg_manager = VERACODE_TYPE_ENV[2]

		project = Detector(language, languageVersion, pkg_manager=pkg_manager)

		dotLanguageVersionLimit = versionLimit[project.language]["dotVersionRange"]
		intLanguageVersionLimit = versionLimit[project.language]["intVersionRange"]

	if(project.language in versionLimit.keys()):
		if("." in project.languageVersion):
			if(project.dotVersionCompare(project.languageVersion, dotLanguageVersionLimit[0]) and not project.dotVersionCompare(project.languageVersion, dotLanguageVersionLimit[1])):
				if(project.framework in versionLimit[project.language]["framework"].keys()):
					if("." in project.frameworkVersion):
						if(project.dotVersionCompare(project.frameworkVersion, dotFrameworkVersionLimit[0]) and not project.dotVersionCompare(project.frameworkVersion, dotFrameworkVersionLimit[1])):
							project.issueVeracodeShell(project.pkg_manager)
						else:
							project.handleErrorMsg("Your framework version is not supported!", versionLimit[project.language]["referenceLink"], dotFrameworkVersionLimit)
							exit(1)
					else:
						if(project.versionComparison(project.frameworkVersion, intFrameworkVersionLimit)):
							project.issueVeracodeShell(project.pkg_manager)
						else:
							project.handleErrorMsg("Your framework version is not supported!", versionLimit[project.language]["referenceLink"], intFrameworkVersionLimit)
							exit(1)
				else:
					### No framework in the customer repo
					project.issueVeracodeShell(project.pkg_manager)

			else:
				project.handleErrorMsg("Your language version is not supported!", versionLimit[project.language]["referenceLink"], versionLimit[project.language]["dotVersionRange"])
				exit(1)
		else:
			if(project.dotVersionCompare(project.languageVersion, intLanguageVersionLimit[0]) and not project.dotVersionCompare(project.languageVersion, intLanguageVersionLimit[1])):
				if(project.framework in versionLimit[project.language]["framework"].keys()):

					if("." in project.frameworkVersion):
						if(project.dotVersionCompare(project.frameworkVersion, dotFrameworkVersionLimit[0]) and not project.dotVersionCompare(project.frameworkVersion, dotFrameworkVersionLimit[1])):
							project.issueVeracodeShell(project.pkg_manager)
						else:
							project.handleErrorMsg("Your framework version is not supported!", versionLimit[project.language]["referenceLink"], dotFrameworkVersionLimit)
							exit(1)
					else:
						if(project.versionComparison(project.frameworkVersion, intFrameworkVersionLimit)):
							project.issueVeracodeShell(project.pkg_manager)
						else:
							project.handleErrorMsg("Your framework version is not supported!", versionLimit[project.language]["referenceLink"], intFrameworkVersionLimit)
							exit(1)
				else:
					### No framework in the customer repo
					project.issueVeracodeShell(project.pkg_manager)
			else:
				project.handleErrorMsg("Your language version is not supported!", versionLimit[project.language]["referenceLink"], intLanguageVersionLimit)
				exit(1)
	else:
		print("Your project programming language is not supported!", versionLimit[project.language]["referenceLink"])
		exit(1)

	project.output()