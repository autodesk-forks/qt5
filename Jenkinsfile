@Library("PSL") _

def buildInfo = Artifactory.newBuildInfo()
    buildInfo.env.capture = true
    buildInfo.env.collect()

//-----------------------------------------------------------------------------
def getWorkspace() {
    def root = pwd()
    def index1 = root.lastIndexOf('\\')
    def index2 = root.lastIndexOf('/')
    def count = (index1 > index2 ? index1 : index2) + 1

    // IMPORTANT: Please change branch name here below else it might mix the previous branch

    root.take(count) + "qt5-3dsmax5122"
}
//-----------------------------------------------------------------------------
node('OSS-Win10-VS2017U6')
//-----------------------------------------------------------------------------
{

    ws(getWorkspace())
    {

        stageDir = pwd() + '\\stage'
        env.WORKSPACE = pwd()

    //---------------------------------------------------------------------
    stage ('Checkout')
    {
        checkout scm
        bat 'git submodule foreach --recursive "git clean -dfx" && git clean -dfx'
        bat 'git clean -dfx'
    }
    //---------------------------------------------------------------------
    stage('Download and Prepare Dependencies') 
    {
        // download packages from artifactory -----------------------------
        artifactDownload = new ors.utils.common_artifactory(steps, env, Artifactory, 'airbuild-svc-user')
        def downloadspec = """{
                "files": [{ "pattern": "team-3dsmax-generic/3dsmax/openssl/1.0.2p/openssl-1.0.2p-win_intel64_v140-2.zip",
                            "target": "deps/openssl/" }
                    ]
                }"""
        buildInfo.append(artifactDownload.download('https://art-bobcat.autodesk.com/artifactory/', downloadspec))
        // unzip artifacts ------------------------------------------------
        dir('deps/openssl') {
            bat '7z x 3dsmax\\openssl\\1.0.2p\\openssl-1.0.2p-win_intel64_v140-2.zip'
        }
    }
    //---------------------------------------------------------------------
    stage ('Configure and Build') {
        // compile, run tests and install ---------------------------------
        env.PYTHON3_HOME="C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python37"
        env.PYTHON2_HOME="C:\\Python27"
        withEnv(["PATH+PYTHON=${env.PYTHON2_HOME}","PATH+BIN=C:\\bin"]) {
            bat 'adsk-build-scripts\\adsk-build-vc141-x64-Qt.bat'
        }
    }
    //---------------------------------------------------------------------
    stage ('Digital-Signing') {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'sign-cred', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
            dir('dist') {
                bat  '..\\adsk-build-scripts\\adsk-sign-sha2.bat ' + PASSWORD
            }
        }
    }
    //---------------------------------------------------------------------
    stage ('Package Artifact & Deploy to Artifactory') {
        bat 'mkdir stage'
        // create the final zip file --------------------------------------
        dir( 'dist' ) {
            bat '7z a ..\\stage\\Qt-5.12.2-3dsmax-%BUILD_NUMBER%-vc141-10.0.17134.0.7z *'
        }
        // deploy package to artifactory ----------------------------------
        artifactUpload = new ors.utils.common_artifactory(steps, env, Artifactory, 'airbuild-svc-user')
        def uploadSpec = """{ "files": [
                    {
                        "pattern": "stage/*.7z",
                        "target": "oss-stg-generic/Qt/5.12.2/3dsmax/",
                        "recursive": "false"
                    }
                ]}"""
        buildInfo.append(artifactUpload.upload('https://art-bobcat.autodesk.com/artifactory/', uploadSpec))
        def server = Artifactory.newServer url: 'https://art-bobcat.autodesk.com/artifactory/', credentialsId: 'airbuild-svc-user'
        server.publishBuildInfo(buildInfo)
    }
    //---------------------------------------------------------------------
    stage ('Cleanup')
    {
        bat 'git submodule foreach --recursive "git clean -dfx" && git clean -dfx'
        bat 'git clean -dfx'
    }
    } // workspace end
}
