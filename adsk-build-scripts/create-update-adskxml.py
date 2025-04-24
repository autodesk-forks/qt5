#!/usr/bin/env python3
###################################################################
#@file create-update-adskxml.py
#@brief create and update the adsk.xml
#@author Huimin Wen
#@ref https://git.autodesk.com/autodesk-forks/zlib/blob/adsk-contrib/gec/1.2.12/adsk-build-scripts/sign.py (Marcelina Viana)
#@ref https://git.autodesk.com/autodesk-forks/boost/blob/lih/gec-boost-1.78.0/adsk-build-scripts/generate_adsk.py (Hongna Li)
#@ref https://git.autodesk.com/modeling-components/ApplicationComponentBestPractices/blob/master/package/adsk_xml.md
#@email Huimin.Wen@autodesk.com
#@date 5/18/2022
#
#@Usage Help 
#    1.You just need to change the following global variables( at line 37).
#       adsk_xml_file = "adsk.xml"
#       vendor_version="1.2.12"
#       package_version="1.1212.0"
#       vendor_name="https://www.zlib.net/"
#       release_notes="https://www.zlib.net/"
#    2.Put this script file on your git repo.
#    3.Call this script in your build script.
#       For Windows platform, you should add the following statement to your build script:
#              python create-update-adskxml.py
#       For Linux and macOS platforms, you should add the following statement to your build script:
#              python3 create-update-adskxml.py
#    4.After the execution of this script, you will see the adsk.xml.
###################################################################
import os
import platform
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request
from urllib.error import HTTPError
from pathlib import Path
from sys import platform
import json
import hashlib
from xml.dom import minidom


###################################################################
#Global variable
adsk_xml_file = "adsk.xml"
package_version="1.1212.1"
vendor_version="1.2.12"
vendor_name="https://www.zlib.net/"
release_notes="https://www.zlib.net/"
#git_remote_http_url = "https://git.autodesk.com/autodesk-forks/zlib"
###################################################################


###################################################################
#@fn get_git_remote_url
#@brief get the git remote origin url
###################################################################
def get_git_remote_url():

    #git remote get-url --push origin
    git_remote_url = subprocess.check_output(['git', 'remote', 'get-url', '--push', 'origin']).decode('ascii') .strip()
    #print(f'git_remote_url: {git_remote_url}');
    #print('git_remote_url: ' + str(git_remote_url) )

    return git_remote_url


###################################################################
#@fn rreplace
#@brief string reverse replace 
###################################################################
def rreplace(s, old, new):
    try:
        place = s.rindex(old)
        return ''.join((s[:place],new,s[place+len(old):]))
    except ValueError:
        return s

###################################################################
#@fn get_git_remote_http_url
#@brief get the git remote origin http url
###################################################################
def get_git_remote_http_url():
    print(sys._getframe().f_code.co_name, f"() Begin...")

    #"git@git.autodesk.com:autodesk-forks/zlib.git" transfer to "https://git.autodesk.com/autodesk-forks/zlib"
    git_remote_url = get_git_remote_url()
    #print("1");

	#string.startswith(str, beg=0,end=len(string))
    if git_remote_url.startswith("git@") or git_remote_url.endswith(".git"):		
        #print("2");
        git_remote_http_url = git_remote_url
        #print("3");

        #string.replace(oldvalue, newvalue, count)
        git_remote_http_url = git_remote_http_url.replace("git@", "https://");
        #print("4");
        git_remote_http_url = git_remote_http_url.replace("git.autodesk.com:", "git.autodesk.com/");
        #print("5");
        git_remote_http_url = rreplace(git_remote_http_url, ".git", "");
        #print(f"6:{git_remote_http_url}");
    else:
        git_remote_http_url = git_remote_url

    print(sys._getframe().f_code.co_name, f"() End...")
    return git_remote_http_url


###################################################################
#@fn get_git_last_commit_id
#@brief get the last git commit id
###################################################################
def get_git_last_commit_id():

    last_commit_id = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode('ascii') .strip()
    #print(f'last_commit_id: {last_commit_id}');
    #print('last_commit_id: ' + str(last_commit_id) )

    return last_commit_id


###################################################################
#@fn get_git_last_commit_url
#@brief get the last git commit url
###################################################################
def get_git_last_commit_url():
    print(sys._getframe().f_code.co_name, f"() Begin...")

    last_commit_url = get_git_remote_http_url() + "/commit/" + get_git_last_commit_id()

    print(sys._getframe().f_code.co_name, f"() End...")
    return last_commit_url

###################################################################
#@fn get_git_current_branch
#@brief get the current branch name 
###################################################################
def get_git_current_branch():

    #git branch --show-current
    current_branch_name = subprocess.check_output(['git', 'branch', '--show-current']).decode('ascii') .strip()
    #print(f'current_branch_name: {current_branch_name}');
    #print('current_branch_name: ' + str(current_branch_name) )

    return current_branch_name


###################################################################
#@fn get_xml_attrbute_value
#@brief get the attribute value of element in xml file(xml_path)
###################################################################
def get_xml_attrbute_value(xml_path, elementTagName, elementAttributeName):
    print(sys._getframe().f_code.co_name, f"( {xml_path} ) Begin...")
    doc = minidom.parse(xml_path) 
    #print(str(doc.nodeName))
    #print( doc.firstChild.tagName )

    root_node = doc.documentElement
    #print(root_node.nodeName)
    #print(root_node.nodeType)
    #print(root_node.childNodes)
    #print(node.parentNode)

    git_node = root_node.getElementsByTagName(elementTagName)[0]
    if git_node.tagName !=  "":
        #print(git_node.tagName)
        elementAttributeValue = git_node.getAttribute(elementAttributeName)

    print(sys._getframe().f_code.co_name, f"( {xml_path} )  End...")
    return elementAttributeValue


###################################################################
#@fn update_xml
#@brief update attribute value of element in xml file(xml_path)
###################################################################
def update_xml_file(xml_path):
    print(sys._getframe().f_code.co_name, f"( {xml_path} ) Begin...")
    current_commit_url_in_xml = get_xml_attrbute_value(xml_path, "git", "commit");
    print(f'current_commit_id_in_xml: {current_commit_url_in_xml}');

    last_commit_id = get_git_last_commit_id();
    print(f'last_commit_id: {last_commit_id}');

    last_commit_url = get_git_last_commit_url();
    print(f'last_commit_url: {last_commit_url}');

    if current_commit_url_in_xml != last_commit_url:
        git_remote_url = get_git_remote_url();
        print(f'git_remote_url: {git_remote_url}');

        git_remote_http_url = get_git_remote_http_url();
        print(f'git_remote_http_url: {git_remote_http_url}');

        current_branch_name = get_git_current_branch();
        print(f'current_branch_name: {current_branch_name}');
	    
        #########################################################################################
		#<?xml version="1.0" encoding="utf-8"?>
		#<metadata>
		#	<bom>
		#		<!-- <vendor version='vendorVersion' name='vendorName'/> -->
		#		<vendor version='1.2.12' name='https://www.zlib.net/'/>
		#
		#		<!-- <git commit='<url>'/> (optional) url attribute points to a git commit. -->
		#		<git commit='https://git.autodesk.com/autodesk-forks/zlib/commit/2042ea28dff1d3aab2847f36fd701042b866ee50'/>
		#
		#		<!-- customize items -->
		#		<adsk version='1.1212.0'/>
		#		<releasenotes url='https://www.zlib.net/'/>
		#		<git1 remote='git@git.autodesk.com:autodesk-forks/zlib.git' branch='adsk-contrib/gec/1.2.12'/>
		#	</bom>
		#</metadata>
        #########################################################################################
        update_xml_element(adsk_xml_file, "git", "commit", git_remote_http_url + "/commit/" + last_commit_id);
        update_xml_element(adsk_xml_file, "vendor", "version", vendor_version);
        update_xml_element(adsk_xml_file, "vendor", "name", vendor_name);

        update_xml_element(adsk_xml_file, "adsk", "version", package_version);
        update_xml_element(adsk_xml_file, "releasenotes", "url", release_notes);
        update_xml_element(adsk_xml_file, "git1", "remote", git_remote_url);
        update_xml_element(adsk_xml_file, "git1", "branch", current_branch_name);

        #update_xml_element(adsk_xml_file, "version", "vendor",  vendor_version);
        #update_xml_element(adsk_xml_file, "version", "adsk",  package_version);
        #update_xml_element(adsk_xml_file, "git1", "remote", git_remote_url);
        #update_xml_element(adsk_xml_file, "git2", "branch", current_branch_name);
        #update_xml_element(adsk_xml_file, "git3", "commit_id", last_commit_id);
        #update_xml_element(adsk_xml_file, "git4", "commit_url", git_remote_http_url + "/commit/" + last_commit_id);
        #update_xml_element(adsk_xml_file, "git5", "commit", git_remote_http_url + "/commit/" + last_commit_id);
        #update_xml_element(adsk_xml_file, "git6", "source", git_remote_http_url + "/commits/" + current_branch_name);
        #update_xml_element(adsk_xml_file, "artifactory", "path", "oss-***-nuget/zlib/" + vendor_version + "/gec/" + package_version);
        #update_xml_element(adsk_xml_file, "releasenotes", "url", release_notes);

    print(sys._getframe().f_code.co_name, " End...")


###################################################################
#@fn update_xml_element
#@brief update attribute value of element in xml file(xml_path)
###################################################################
def update_xml_element(xml_path, elementTagName, elementAttributeName, elementAttributeValue):
    print(sys._getframe().f_code.co_name, f"( {xml_path}, {elementTagName}, ... ) Begin...")
    doc = minidom.parse(xml_path) 
    root_node = doc.documentElement
    git_node = root_node.getElementsByTagName(elementTagName)[0]
    if git_node.tagName !=  "":
        print(git_node.tagName)
        git_node.setAttribute(elementAttributeName, elementAttributeValue)
    
    #git_node_data = git_node.childNodes[0].data
    #git_node_data = git_node.data
    #print(git_node_data)    
    # node.getAttribute('price')

    # writing the changes in "file" object to 
    # the xml_path file
    with open( xml_path, "wb" ) as fs:   
        fs.write( doc.toxml(encoding="utf-8") )
        fs.close() 

    print(sys._getframe().f_code.co_name, f"( {xml_path}, {elementTagName}, ... ) End...")


###################################################################
#@fn create_xml_file
#@brief create xml file(xml_path)
###################################################################
def create_xml_file(xml_path):
    print(sys._getframe().f_code.co_name, f"( {xml_path} ) Begin...")
    #print(f"{sys._getframe().f_code.co_name}( {xml_path} ) Begin...")

    last_commit_id = get_git_last_commit_id();
    print(f'last_commit_id: {last_commit_id}');

    git_remote_url = get_git_remote_url();
    print(f'git_remote_url: {git_remote_url}');

    git_remote_http_url = get_git_remote_http_url();
    print(f'git_remote_http_url: {git_remote_http_url}');

    current_branch_name = get_git_current_branch();
    print(f'current_branch_name: {current_branch_name}');

    import textwrap
    xml_string = textwrap.dedent(rf"""		<?xml version="1.0" encoding="utf-8"?>
		<metadata>
			<bom>
				<!-- <vendor version="vendorVersion" name="vendorName"/> -->
				<vendor version="{vendor_version}" name="{vendor_name}"/>

				<!-- <git commit='<url>'/> (optional) url attribute points to a git commit. -->
				<git commit="{git_remote_http_url}/commit/{last_commit_id}"/>
				
				<!-- customize items -->
				<adsk version="{package_version}"/>
				<releasenotes url="{release_notes}"/>
				<git1 remote="{git_remote_url}" branch="{current_branch_name}"/>
			</bom>
		</metadata>""")

    # writing the changes in "file" object to 
    # the xml_path file
    with open( xml_path, "wb") as fs:
        fs.write( xml_string.encode('utf-8'))
        fs.close()     

    print(sys._getframe().f_code.co_name, " End...")


###################################################################
#@fn main
#@brief main function
###################################################################
def main():
    exit_code = 0
    args = parse_arguments()

    try:
        if not os.path.exists(adsk_xml_file):
            print("create_xml_file")
            create_xml_file(adsk_xml_file)
        else:
            #print("update_xml_file")
            update_xml_file(adsk_xml_file)       
        
    except HTTPError as e:
        exit_code = 1
    
    except subprocess.CalledProcessError as e:
        exit_code = e.returncode

    finally:    
        print(sys._getframe().f_code.co_name, f'update-adskxml.py has completed. Exit code: {exit_code}')
        exit(exit_code)


###################################################################
#@fn parse_arguments
#@brief parse the command line arguments
###################################################################
def parse_arguments():

#    if len(sys.argv) < 3:
#        print_help()

#    return args
       return ""


###################################################################
#@fn print_help
#@brief print help info
###################################################################
def print_help():
    import textwrap
    help_desc = textwrap.dedent(r"""
        Usage: python update-adskxml.py  [options...]
        
        Options:
                            
        Example:
            l""")
    print(help_desc) 
    sys.exit(0)


###################################################################
#Global statements
###################################################################
if __name__ == "__main__":
    python_version = sys.version_info[0] +  sys.version_info[1] / 10
    if python_version < 3.6:
        raise ValueError('Python 3.6 is required to run update-adskxml.py .')
    main()
