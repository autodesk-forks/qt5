import groovy.json.*
@Library("PSL") _

properties([
  disableConcurrentBuilds(),
  parameters([
	string(defaultValue: "", description: 'Commit', name: 'COMMIT'),
  ])
])

def currentStage = ""
changeSetContent = ""
gitCommitUser = ""
gitCommitShort = ""
artifactName = ""
artifactProps = ""

workspaceRoot = [:]
QtPackage = [:]
QtexamplesPackage = [:]
QtWebengineDebugInfoPackage = [:]
artifacts = [:]
results = [:]
hostName = [:]

downloadDir = 'artifactory'
buildType = "DI"    // Only build DI package - Should have another pipeline for CI that triggers on new changes and DI on schedule.  DI build should build on last successful CI
config = "Release"  //We always build Release for this package.  Set build parameter to select Debug/Release in case we need to support both
gitCommit = ""

def now = new Date()
buildTime = String.format('%tY-%<tm-%<td-%<tH-%<tM', now)
buildID = buildTime.replace("-", "")
product = "qt"
gitBranch = env.BRANCH_NAME  //Actual branch name in GIT repo
branch = getQTVersion(gitBranch)
qtVersion = "${branch}" //Sub-folder name in zip/tar files
artifactoryTarget = "oss-stg-generic/Qt/${branch}/Maya/${buildTime}/"
artifactoryRoot = "https://art-bobcat.autodesk.com/artifactory/"

default_Recipients = ["Bang.Nguyen@autodesk.com"]
DEVTeam_Recipients = ["marc-andre.brodeur@autodesk.com"]
ENGOPSTeam_Recipients = ["Bang.Nguyen@autodesk.com", "vishal.dalal@autodesk.com"]
QTTeam_Recipients = ["Daniela.Stajic@autodesk.com", "Wayne.Arnold@autodesk.com", "Richard.Langlois@autodesk.com", "william.smith@autodesk.com"]


buildStages = [
	 "Initialize":[name:'Initialize', emailTO: (ENGOPSTeam_Recipients + default_Recipients).join(", ")],
	 "Setup":[name:'Setup', emailTO: (ENGOPSTeam_Recipients + default_Recipients).join(", ")],
     "Sync":[name:'Sync', emailTO: (ENGOPSTeam_Recipients + default_Recipients).join(", ")],
	 "Build":[name:'Build', emailTO: (DEVTeam_Recipients + default_Recipients).join(", ")],
	 "Package":[name:'Package', emailTO: (ENGOPSTeam_Recipients + default_Recipients).join(", ")],
	 "Publish": [name:'Publish', emailTO: (ENGOPSTeam_Recipients + default_Recipients).join(", ")],
	 "Finalize":[name:'Finalize', emailTO: (ENGOPSTeam_Recipients + default_Recipients).join(", ")],
]

buildConfigs = [
	"qt_local": "local", "qt_Lnx": "CentOS 7.3", "qt_Mac": "Mojave 10.14", "qt_Win": "Windows 10"
]

//-----------------------------------------------------------------------------
def getQTVersion(gitBranch) {
    println "gitBranch: ${gitBranch}\n"
	def found = (gitBranch =~ /.*adsk-contrib-maya-v{0,1}(.*)$/)
    if (found.matches()) {
        def version = found[0]
		println "version: ${version[1]}\n"
		return version[1]
    } else {
        return "Preflight"
    }
}

//-----------------------------------------------------------------------------
def checkOS(){
    if (isUnix()) {
        def uname = sh script: 'uname', returnStdout: true
        if (uname.startsWith("Darwin")) {
            return "Mac"
        }
        else {
            return "Linux"
        }
    }
    else {
        return "Windows"
    }
}

//-----------------------------------------------------------------------------
def getHostName() {
	def hostName = ""
	if (isUnix()) {
		hostName = sh (
			script: "hostname",
			returnStdout: true
		).trim()
	}
	else {
		hostName = bat (
			script: "@hostname",
			returnStdout: true
		).trim()
	}
    return hostName
}

//-----------------------------------------------------------------------------
def notifyBuild(buildStatus, String gitBranch) {
	// build status of null means successful
	buildStatus =  buildStatus ?: 'SUCCESSFUL'

	// Default values
	def subject = "[${product}_${qtVersion}] - ${buildStatus}: Job - '${gitBranch} [${env.BUILD_NUMBER}]'"
	def emailTO
	def color

	if (buildStatus == "FAILURE") {
		color = "#ff0000;"
	} else if (buildStatus == "SUCCESSFUL") {
		color = "#008000;"
	} else {
		color = "#ffae42;"
	}

	println "Build Result: ${buildStatus}\n"
	if (buildStatus == "SUCCESSFUL") {
		emailTO = QTTeam_Recipients.join(", ")
	}
	else if (buildStatus == "ABORTED" || buildStatus == "UNSTABLE") {
		emailTO = default_Recipients.join(", ")
	}
	else {
		def failedStage = getFailedStage(results)
		emailTO = buildStages[failedStage].emailTO
	}

	//emailTO = "bang.nguyen@autodesk.com"
	emailTO = "marc-andre.brodeur@autodesk.com"

	def buildLocation = buildStatus == "SUCCESSFUL" ? getBuildLocation() : ""
	def buildResult = getBuildResult(results, buildConfigs)
	def details = """
     <html>
		<body><table cellpadding="10">
            <tr><td>Outcome</td><td><span style=\"color: ${color}\"><strong>${buildStatus}</strong></span></td></tr>
            <tr><td>Build URL</td><td><a href="${env.BUILD_URL}">${gitBranch} [${env.BUILD_NUMBER}]</a></td></tr>
            <tr valign="top"><td>Commit(s)</td><td><span style="white-space: pre-line">${changeSetContent}</span></td></tr>
			<tr><td>Results</td><td><table col align="left" cellspacing="6">${buildResult}</table></td></tr>
			<tr>${buildLocation}</tr>
        </table></body>
	 </html>"""

 emailext(
      mimeType: 'text/html',
      subject: subject,
      from: 'engops.team.tesla@autodesk.com',
      body: details,
	  to: emailTO,
      recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']]
    )
}

//-----------------------------------------------------------------------------
def getChangeSetString(String commitInfo) {

	def changes = ""
	def count = 0
    def outputString = ""
	def commit = ""
	def message = ""

	def jsonSlurper = new JsonSlurper()
	def object = jsonSlurper.parseText(commitInfo)

	count = object.data.size()
	commitCleanString = object.CleanDirective
	object.data.each {
		commit = it.Commit.take(8)
		message = it.Message
		if (message.length() > 60) {
			message = message.take(60) + "..."
		}
		changes += "&emsp;<span style='color:#6fb9dc;'>${commit}</span> by ${it.Author} - <span style='color:#feba29;'>${message}</span><br>"
		//This is for affected files
		//it.Changes.each {
		//	println it
		//}
	}

	if (count == 0) {
		outputString = "There are no change in this build."
	}
	else {
		outputString = "Total: ${count}<br>"
		outputString += changes
	}
	return outputString
}

//-----------------------------------------------------------------------------
def GetArtifacts(String workDir, String buildConfig)
{
	def artifactDownload = new ors.utils.common_artifactory(steps, env, Artifactory, 'svc-p-mayaoss')

	dir(workDir) {
		for (artifact in artifacts[buildConfig]) {
			def downloadspec = """{
				"files": [
					{
						"pattern": "${artifact}",
						"target": "${downloadDir}/"
					}
				]
			}"""

			print "Download Spec: ${downloadspec}"
			artifactDownload.download('https://art-bobcat.autodesk.com/artifactory/', downloadspec)

			index = artifact.indexOf('/')
			print "index: ${index}"
			def downloadFile = downloadDir + artifact.substring(index)
			print "downloadFile: ${downloadFile}"
			print "${downloadFile} --- ${downloadDir}"

			if (isUnix()) {
				runOSCommand("mkdir -p ${downloadDir}")
				runOSCommand("tar zxvf ${downloadFile} -C ${downloadDir}")
			}
			else {
				runOSCommand("7z e ${downloadFile} -y -spf -o${downloadDir}")
			}
		}
	}
}

//-----------------------------------------------------------------------------
def getBuildLocation() {

	def outputString = ""
	outputString = "<td>Artifacts</td><td>"
	buildConfigs.each {
		if (it.value != "local") {
			outputString += "${artifactoryRoot}${artifactoryTarget}${QtPackage[it.key]}<br>"
			if (it.value.contains("Win")) {
				outputString += "${artifactoryRoot}${artifactoryTarget}${QtexamplesPackage[it.key]}<br>"
				//outputString += "${artifactoryRoot}${artifactoryTarget}${QtWebengineDebugInfoPackage[it.key]}<br>"
			}
		}
	}
	outputString += "</td>"
	return outputString
}

//-----------------------------------------------------------------------------
def getBuildResult(Map results, Map buildConfigs) {
	def buildResult = ""
	//Stages Name
	results.eachWithIndex { configs, stages, i ->
		if (i == 0) {
			buildResult += '<tr><th></th>'
			stages.each {
				buildResult += '<th>' + it.key + '</th>'
			}
			buildResult += '</tr>'
		}
	}
	//Stage outcome for each build config
	results.each { configs, stages ->
		buildResult += '<tr align="center"><td><b>' + buildConfigs[configs] + "</b><br>(${hostName[configs]})" + '</td>'
		stages.each {
			if (it.value == "") {
				buildResult += "<td></td>"
			}
			else {
				//println "Status: ${it.value}"
				if (it.value == "Error") {
					buildResult += '<td><span style="color:#ff0000;">' + "\u2717" + '</span></td>'
				}
				else if (it.value == "Warning") {
					buildResult += '<td><span style="color:#ffae42;">' + "\u26A0" + '</span></td>'
				}
				else if (it.value == "Timeout") {
					buildResult += '<td><span style="color:#ff0000;">' + "\u29B2" + '</span></td>'
				}
				else if (it.value == "Aborted") {
					buildResult += '<td><span style="color:#ff0000;">' + "\u2014" + '</span></td>'
				}
				else if (it.value == "Skip") {
					buildResult += '<td><span style="color:#ff0000;">' + "Skip" + '</span></td>'
				}
				else { //Pass
					buildResult += '<td><span style="color:#00ff00;">' + "\u2713" + '</span></td>'
				}
			}
		}
		buildResult += '</tr>'
	}
    return buildResult
}

//-----------------------------------------------------------------------------
def getFailedStage(Map results) {

    def failedStage = ""
	results.each { configs, stages ->
		stages.each {
			if (it.value == "Error" || it.value == "Timeout") {
				failedStage = it.key
			}
		}
	}
    return failedStage
}
//-----------------------------------------------------------------------------

def errorHandler(Exception e, String buildConfig="", String stage="") {

	if (e instanceof org.jenkinsci.plugins.workflow.steps.FlowInterruptedException || e instanceof java.lang.InterruptedException) {
		println "errorHandler: FlowInterruptedException ${e}"
		def actions = currentBuild.getRawBuild().getActions(jenkins.model.InterruptedBuildAction)
		println ("Actions = ${actions}")
		if (!actions.isEmpty()) {
			print "User Abort"
			currentBuild.result = "ABORTED"
			if (buildConfig != "" && stage != "") {
				results[buildConfig][stage] = "Aborted"
				throw e
			}
		} else {
			print "Project Timeout!"
			currentBuild.result = "FAILURE"
			if (buildConfig != "" && stage != "") {
				results[buildConfig][stage] = "Timeout"
				throw e
			}
		}
	} else if (e instanceof hudson.AbortException) {
		println "errorHandler: AbortException ${e}"
		def actions = currentBuild.getRawBuild().getActions(jenkins.model.InterruptedBuildAction)
		println ("Actions = ${actions}")
		// this ambiguous condition means during a shell step, user probably aborted
		if (!actions.isEmpty()) {
			print "AbortException: User Abort"
			currentBuild.result = 'ABORTED'
			if (buildConfig != "" && stage != "") {
				results[buildConfig][stage] = "Aborted"
				throw e
			}
		} else {
			print "AbortException: Error"
			currentBuild.result = 'FAILURE'
			if (buildConfig != "" && stage != "") {
				results[buildConfig][stage] = "Error"
				throw e
			}
		}
	} else {
		if (e.toString().contains("Ignored Errors")) {
			currentBuild.result = 'UNSTABLE'
			if (buildConfig != "" && stage != "") {
				results[buildConfig][stage] = "Warning"
			}
		} else {
			println "errorHandler: Unhandled Error: ${e}"
			currentBuild.result = 'FAILURE'
			if (buildConfig != "" && stage != "") {
				results[buildConfig][stage] = "Error"
				throw e
			}
		}
	}
}

//-----------------------------------------------------------------------------
def getWorkspace(String buildConfig)
{
	def root = pwd()
	def index1 = root.lastIndexOf('\\')
	def index2 = root.lastIndexOf('/')
	def count = (index1 > index2 ? index1 : index2) + 1
	def workDir

	if (buildConfig.toLowerCase().contains('_local')) {
		workDir = root.take(count) + product
	}
	else {
		//workDir = root.take(count) + product + '_' + branch  //Should add buildType and config too i.e. CI/DI/PF Debug/Release
		workDir = root.take(count) + product + '_maya' //Use same workspace for all release branches
	}
	println "workDir: ${workDir}"
	return workDir
}

// Execute native shell command as per OS
//-----------------------------------------------------------------------------
def runOSCommand(String cmd, errorHandler='abort')
{
    try {
        if (isUnix()) {
            sh cmd
        } else {
            bat cmd
        }
    } catch(failure) {
		if (errorHandler.equalsIgnoreCase('ignore')) {
			throw new RuntimeException("Ignored Errors") //Ignore error and will set overall build status to 'UNSTABLE'
		}
		else {
			throw failure
		}
    }
}

//-----------------------------------------------------------------------------
def Initialize(String buildConfig)
{
	def stage = "Initialize"

	try {
		def workDir = getWorkspace(buildConfig)
		def srcDir = "${workDir}/src"
		def scriptDir = "${workDir}/src/scripts"

		dir(srcDir) {
			scmInfo = checkout scm
			gitCommit = params.COMMIT == "" ? scmInfo.GIT_COMMIT : params.COMMIT
			println "${scm.branches} Branch: ${env.BRANCH_NAME}"
			runOSCommand("git checkout ${env.BRANCH_NAME}")
			runOSCommand("git pull")

			gitCommitShort = gitCommit.substring(0,8)
			if (branch == 'Preflight') {
				gitCommitUser = sh (
					script: "git show -s --format='%an' ${gitCommit} | awk '{print \$1\$2}' ",
					returnStdout: true
				).trim()
				println "Commit User: ${gitCommitUser}"
				lastBuildCommit = gitCommit
				lastSuccessfulCommit = gitCommit
				artifactName = String.format("%s-%s-%s", gitCommitUser, buildID, gitCommitShort)
				artifactProps = "RetentionPolicy=7"
			} else {
				//Get lastBuildCommit & lastSuccessfulCommit
				buildInfo = sh (
					script: "python $scriptDir/updatebuildcommit.py -g -p ${product} -b ${branch} -t ${buildType} -c ${config}",
					returnStdout: true
				).trim()
				(lastSuccessfulCommit, lastBuildCommit) = buildInfo.tokenize( ' ' )
				print "Last Successful Commit: ${lastSuccessfulCommit} -- Last Build Commit: ${lastBuildCommit}"

				if (lastSuccessfulCommit == null) {
					lastSuccessfulCommit = gitCommit
				}
				if (lastBuildCommit == null) {
					lastBuildCommit = gitCommit
				}
				artifactName = String.format("%s-%s", buildID, gitCommitShort)
			}

			commitInfo = sh (
				script: "python $scriptDir/getcommitinfo.py -s ${srcDir} -sc ${lastSuccessfulCommit} -bc ${lastBuildCommit} -gc ${gitCommit}",
				returnStdout: true
			).trim()
			print "CommitInfo: ${commitInfo}"
			changeSetContent = getChangeSetString(commitInfo)
		}
		workspaceRoot[buildConfig] = workDir
		hostName[buildConfig] = getHostName()

		results[buildConfig][stage] = "Success"
    } catch (e) {
		errorHandler(e, buildConfig, stage)
    }
}

//-----------------------------------------------------------------------------
def Setup(String buildConfig)
{
	def stage = "Setup"
	env.QTVERSION = "${qtVersion}"

	try {
		def workDir = getWorkspace(buildConfig)
		ws(workDir) {
			//Delete 'build', 'install' and 'art-bobcat-downloads' folders before build
			dir ('build') {
				deleteDir()
			}
			dir ('install') {
				deleteDir()
			}
			dir ('out') {
				deleteDir()
			}
			dir ("${downloadDir}") {
				deleteDir()
			}
		}
		workspaceRoot[buildConfig] = workDir
		hostName[buildConfig] = getHostName()

		if (checkOS() == "Mac") {
			QtPackage[buildConfig] = "${artifactName}-Maya-Qt-Mac.tar.gz"
			QtexamplesPackage[buildConfig] = "${artifactName}-Maya-Qt-examples-Mac.tar.gz"
			QtWebengineDebugInfoPackage[buildConfig] = "${artifactName}-Maya-Qt-webengine-debuginfo-Mac.tar.gz"
			artifacts[buildConfig]  = []
		}
		else if (checkOS() == "Linux") {
			QtPackage[buildConfig] = "${artifactName}-Maya-Qt-Linux.tar.gz"
			QtexamplesPackage[buildConfig] = "${artifactName}-Maya-Qt-examples-Linux.tar.gz"
			QtWebengineDebugInfoPackage[buildConfig] = "${artifactName}-Maya-Qt-webengine-debuginfo-Linux.tar.gz"
			artifacts[buildConfig]  = []
		}
		else {
			QtPackage[buildConfig] = "${artifactName}-Maya-Qt-Windows.zip"
			QtexamplesPackage[buildConfig] = "${artifactName}-Maya-Qt-examples-Windows.zip"
			QtWebengineDebugInfoPackage[buildConfig] = "${artifactName}-Maya-Qt-webengine-debuginfo-Windows.zip"
			artifacts[buildConfig]  = ["team-asrd-pilots/openssl/102h/openssl-1.0.2h-win-vc14.zip"]
		}

		results[buildConfig][stage] = "Success"
    } catch (e) {
		errorHandler(e, buildConfig, stage)
    }
}

//-----------------------------------------------------------------------------
def Sync(String workDir, String buildConfig)
{
  	def stage = "Sync"

	try {
		def srcDir = "${workDir}/src"
		print "--- Sync ---"
		dir(srcDir) {
			def exists = fileExists(".git")
			if (!exists) {
				withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'svc_p_mescm', usernameVariable: 'GITUSER', passwordVariable: 'GITPWD']]) {
					runOSCommand "git clone --branch ${gitBranch} https://${GITUSER}:\"${GITPWD}\"@git.autodesk.com/autodesk-forks/qt5.git . "
				}
			}
			print "Commit: $gitCommit"
			//checkout scm to the commit_id

			checkout([$class: 'GitSCM', branches: [[name: gitCommit ]],
				userRemoteConfigs: scm.userRemoteConfigs])

			// Remove all private files first
			runOSCommand("git submodule foreach --recursive \"git clean -dfx\" && git clean -dfx")
			runOSCommand("perl ./init-repository --force --module-subset=default")
		}

		print "--- Download Packages ---"
		GetArtifacts(workDir, buildConfig)

		results[buildConfig][stage] = "Success"
    } catch (e) {
		errorHandler(e, buildConfig, stage)
    }
}


//-----------------------------------------------------------------------------
def Build(String workDir, String buildConfig)
{
	def stage = "Build"
	def flavor = buildConfig.substring(0, buildConfig.lastIndexOf("_")) //We may need this to invoke different build flavors i.e. Maya/MayaLT/MayaIO
	def buildDir = "${workDir}/build"
	def scriptDir = "${workDir}/src/scripts"

	try {
		//timeout(time: 9, unit: 'HOURS') {
			dir (buildDir) {
				if (checkOS() == "Mac") {
					runOSCommand('xcodebuild -version && xcodebuild -showsdks')
					runOSCommand("""bash $scriptDir/adsk_maya_build_qt_osx.sh ${workDir}""")
				}
				else if (checkOS() == "Linux") {
					runOSCommand("scl enable devtoolset-9 'bash $scriptDir/adsk_maya_build_qt_lnx.sh ${workDir}'")
				}
				else {
					runOSCommand("""$scriptDir\\adsk_maya_build_qt_win.bat ${workDir}""")
				}
			}
		//}
		results[buildConfig][stage] = "Success"
    } catch (e) {
		errorHandler(e, buildConfig, stage)
    }
}

//-----------------------------------------------------------------------------
def Package(String workDir, String buildConfig)
{
  	def stage = "Package"
	try {
		dir(workDir) {
			dir('install') {
				if (isUnix()){
					runOSCommand("""mkdir ../out""")  //Create 'out' folder where zip files will be created.
					runOSCommand("""tar -czf ../out/${QtPackage[buildConfig]} ${product}_${qtVersion}""")
				} else {
					runOSCommand("""7z a -tzip ../out/${QtPackage[buildConfig]} ${product}_${qtVersion} -xr!examples""")
					runOSCommand("""7z a -tzip ../out/${QtexamplesPackage[buildConfig]} ${product}_${qtVersion}/examples -xr!${product}_${qtVersion}/examples/webengine/*.pdb""")
					//runOSCommand("""7z a -tzip ../out/${QtWebengineDebugInfoPackage[buildConfig]} -ir!${product}_${qtVersion}/examples/webengine/*.pdb""")
				}
			}
		}
		results[buildConfig][stage] = "Success"
    } catch (e) {
		errorHandler(e, buildConfig, stage)
    }
}

// Uploading of packages to artifactory
///////////////////////////////////////////////////////////////////////////////////////////////////////

def Publish(String workDir, String buildConfig)
{
  	def stage = "Publish"
	def pattern
	def props
	try {
		dir(workDir) {
			artifactUpload = new ors.utils.common_artifactory(steps, env, Artifactory, 'svc-p-mayaoss')

			if (checkOS() == "Mac") {
				pattern = "out/*.tar.gz"
				props = "commit=${gitCommit};OS=OSX10.14.1;Compiler=xcode10.1"
				if (artifactProps != "") {
					props = String.format("%s;%s", props, artifactProps)
				}
			}
			else if (checkOS() == "Linux") {
				pattern = "out/*.tar.gz"
				props = "commit=${gitCommit};OS=Rhel7.6;Compiler=gcc9.3.1"
				if (artifactProps != "") {
					props = String.format("%s;%s", props, artifactProps)
				}
			}
			else {
				pattern = "out/*.zip"
				props = "commit=${gitCommit};OS=Windows10;Compiler=v142"
				if (artifactProps != "") {
					props = String.format("%s;%s", props, artifactProps)
				}
			}
			def uploadSpec = """{
				"files": [
					{
						"pattern": "${pattern}",
						"target": "${artifactoryTarget}",
						"recursive": "false",
						"props": "${props}"
					}
				]
			}"""

			artifactUpload.upload(artifactoryRoot, uploadSpec)
		}
		results[buildConfig][stage] = "Success"
    } catch (e) {
		errorHandler(e, buildConfig, stage)
    }
}

//-----------------------------------------------------------------------------
def Finalize(String buildConfig)
{
	def stage = "Finalize"

	try {
		if (branch != 'Preflight') {
			def workDir = getWorkspace(buildConfig)
			def srcDir = "${workDir}/src"
			def scriptDir = "${workDir}/src/scripts"

			dir(srcDir) {
				if (currentBuild.result == "FAILURE") {
					runOSCommand("python $scriptDir/updatebuildcommit.py -s -p ${product} -b ${branch} -t ${buildType} -c ${config} -sc ${lastSuccessfulCommit} -bc ${gitCommit}")
				} else {
					runOSCommand("python $scriptDir/updatebuildcommit.py -s -p ${product} -b ${branch} -t ${buildType} -c ${config} -sc ${gitCommit} -bc ${gitCommit}")
				}
			}
		}
		results[buildConfig][stage] = "Success"
    } catch (e) {
		errorHandler(e, buildConfig, stage)
    }
}

// Calling of parallel steps
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------

def generateSteps = {qt_lnx, qt_mac, qt_win ->
    return [ "qt_Lnx" : { node("OSS-Maya-CentOS76_02") { qt_lnx() }},
             "qt_Mac": { node("OSS-Maya-OSX10.14.1-Xcode10.1") { qt_mac() }},
             "qt_Win" : { node("OSS-Maya_2022_Win10-vs2019_01") { qt_win() }}
           ]
}

//Initialize result matrix based on buildConfigs & stages
buildStages.each { stageKey, stageVal ->
	def stage = stageVal.name
	buildConfigs.each {
		if(results.containsKey(it.key))
		{
			results.get(it.key).putAll([(stage):''])
		}
		else
		{
			results.put(it.key, [(stage):''])
		}
	}
}

try {
    //timeout(time: 10, unit: 'HOURS') {
        node('qt_local'){
			stage (buildStages['Initialize'].name)
			{
				Initialize('qt_local')
			}
        }

		stage (buildStages['Setup'].name)
		{
			parallel generateSteps(
				{
					Setup('qt_Lnx')
				},
				{
					Setup('qt_Mac')
				},
				{
					Setup('qt_Win')
				}
			)
		}

		stage (buildStages['Sync'].name)
		{
			parallel generateSteps(
				{
					Sync(workspaceRoot['qt_Lnx'], 'qt_Lnx')
				},
				{
					Sync(workspaceRoot['qt_Mac'], 'qt_Mac')
				},
				{
					Sync(workspaceRoot['qt_Win'], 'qt_Win')
				}
			)
		}

		stage (buildStages['Build'].name)
		{
			parallel generateSteps(
				{
					Build(workspaceRoot['qt_Lnx'], 'qt_Lnx')
				},
				{
					Build(workspaceRoot['qt_Mac'], 'qt_Mac')
				},
				{
					Build(workspaceRoot['qt_Win'], 'qt_Win')
				}
			)
		}

		stage (buildStages['Package'].name)
		{
			parallel generateSteps(
				{
					Package(workspaceRoot['qt_Lnx'], 'qt_Lnx')
				},
				{
					Package(workspaceRoot['qt_Mac'], 'qt_Mac')
				},
				{
					Package(workspaceRoot['qt_Win'], 'qt_Win')
				}
			)
		}

		stage (buildStages['Publish'].name)
		{
			parallel generateSteps(
				{
					Publish(workspaceRoot['qt_Lnx'], 'qt_Lnx')
				},
				{
					Publish(workspaceRoot['qt_Mac'], 'qt_Mac')
				},
				{
					Publish(workspaceRoot['qt_Win'], 'qt_Win')
				}
			)
		}
        node('qt_local'){
			stage (buildStages['Finalize'].name)
			{
				Finalize('qt_local')
			}
		}
	//}
} catch (e) {
	errorHandler(e)
} finally {

	//def buildResult = getBuildResult(results, buildConfigs)
	//println "Build Result:\n${buildResult}"
	//results.each {k, v -> println "KeyResult: ${k}, KeyValue: ${v}" }
	notifyBuild(currentBuild.result, gitBranch)
}
