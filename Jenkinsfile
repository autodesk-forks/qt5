 def getWorkspace() {
    def root = pwd()
    def index1 = root.lastIndexOf('\\')
    def index2 = root.lastIndexOf('/')
    def count = (index1 > index2 ? index1 : index2) + 1

    // IMPORTANT: Please change branch name here below else it might mix the previous branch

        root.take(count) + "qt5-3dsmax562"
    }




  node('OSS3P-Win10-VS2015U3') 
  {

   ws(getWorkspace()){ 

      stageDir = pwd() + '\\stage'
      env.WORKSPACE = pwd()

	stage ('Checkout-win') 
	{
            // checkout the sources from github repo
            
	    checkout scm
            
	    // Remove all private files first

	    bat 'git submodule foreach --recursive "git clean -dfx" && git clean -dfx'
            
	    //prepare clean directory containing the 7z file to upload for artifactory

	    _CreateCleanDir(stageDir)
		
	}
	
      stage ('Download_OpenSSL') 
	{
	   // download packages from artifactory 
	   
	   withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'airbuild-svc-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) 
	   {
           
	      def server = Artifactory.newServer url: 'https://art-bobcat.autodesk.com/artifactory/', username: "${USERNAME}", password: "${PASSWORD}"
	   
	      def downloadspec = """{
	          "files": [
		        {
			     "pattern": "team-3dsmax-generic/3dsmax/openssl/1.0.2j/openssl-1.0.2j.zip",
	                     "target": "art-bobcat-downloads/"		             
			}
		   ]
               }"""
           server.download(downloadspec)
	   }
	}
    	
    
	stage ('Build_n_Package_Qt') 
	{
	   // Compile QT
	   bat 'adsk_3dsmax_build_Qt.bat'
	}
    
	stage ('Deploy_To_Artifactory') 
	{
	   
	   // deploy package to artifactory 
	   
	   withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'airbuild-svc-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) 
	   {
           
	      def server = Artifactory.newServer url: 'https://art-bobcat.autodesk.com/artifactory/', username: "${USERNAME}", password: "${PASSWORD}"
	   
	      def uploadSpec = """{
	          "files": [
		        {
	       	            "pattern": "stage/*.7z",
	                    "target": "oss-stg-generic/Qt/5.6.2/3dsmax/",
		            "recursive": "false"
			}
		   ]
               }"""
          server.upload(uploadSpec)
	   }
	}
    }	
}

 def _CreateCleanDir(String DirectoryToClean)
 {
    env.DirectoryToClean = DirectoryToClean

        if ( fileExists(DirectoryToClean) )
	 {
	   retry(3)
           {
	      bat 'rd %DirectoryToClean% /s /q'
	   }
	   retry(3)
	   {
	     bat 'mkdir %DirectoryToClean%'
	   }
	 }
	  else
	 {
	   retry(3)
	   {
	     bat 'mkdir %DirectoryToClean%'
	   }
	 }

  }
