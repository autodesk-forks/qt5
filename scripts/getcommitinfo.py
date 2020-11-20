import argparse
import os
import subprocess
import re
import shlex
import json
import ast

from subprocess import Popen, PIPE

GIT_COMMIT_FIELDS = ['id', 'author_name', 'author_email', 'date', 'message']
GIT_LOG_FULL_FORMAT = ['%H', '%an', '%ae', '%ad', '%B']

class GITLog:
    def __init__(self, gitSource):
        self.gitSource = gitSource

    def removeMatch(self, matchList):
        for match in matchList:
            if os.path.isdir(match):
                print "Delete Dir: %s" % match
                shutil.rmtree(match, onerror=remove_readonly)
            else:
                print "Delete File: %s" % match
                fileAtt = os.stat(match)[0]
                if (not fileAtt & stat.S_IWRITE):
                    # File is read-only, so make it writeable
                    os.chmod(match, stat.S_IWRITE)
                os.remove(match)


    def getCommitInfo(self, lastSuccessfulCommit, lastBuildCommit, gitCommit):

        GIT_COMMIT_LEN = None
        GIT_SUBJECT_LEN = None

        GIT_LOG_FORMAT = '%x1f'.join(GIT_LOG_FULL_FORMAT) + '%x1e'

        if lastSuccessfulCommit == gitCommit:
            p = Popen('git log --format="%s" %s -n 1 --date=format:"%%Y-%%m-%%d-%%H-%%M-%%S"' % (GIT_LOG_FORMAT, lastSuccessfulCommit), cwd = self.gitSource, shell=True, stdout=PIPE)
        else:
            p = Popen('git log --format=%s %s..%s --date=format:"%%Y-%%m-%%d-%%H-%%M-%%S"' % (GIT_LOG_FORMAT, lastSuccessfulCommit, gitCommit), cwd = self.gitSource, shell=True, stdout=PIPE)

        (log, _) = p.communicate()
        log = log.strip('\n\x1e').split("\x1e")
        log = [row.strip().split("\x1f") for row in log]
        log = [dict(zip(GIT_COMMIT_FIELDS, row)) for row in log]
        buffer = ""

        json_data = {}
        data = []

        for p in log:
            tmp_dict = {}
            tmp_dict['Commit'] = p["id"]
            tmp_dict['Author'] = p["author_name"]
            tmp_dict['Date'] = p["date"]
            #Remove newline, apostrophe...
            desc = p["message"]          
            desc = desc.replace("\r","")
            desc = desc.replace("\n","")
            desc = desc.replace("'","\\'")
            desc = desc.replace('"','\\"')            
            tmp_dict['Message'] = desc
            #Get all files affected by this commit
            c = Popen('git show --pretty="" --name-only %s' % p["id"], cwd = self.gitSource, shell=True, stdout=PIPE)
            (change, _) = c.communicate()
            buffer += "Changes:\n%s\n" % change
            mychange = change.split()
            tmp_dict['Changes'] = [item for item in mychange]
            data.append(tmp_dict)

        json_data["data"] = data
        json_data["CleanDirective"] = self.getCleanDirectiveString(lastBuildCommit, gitCommit)
        json_string = json.dumps(json_data)
        return json_string


    def getCleanDirectiveString(self, lastBuildCommit, gitCommit):

        GIT_LOG_FORMAT = '%x1f'.join(GIT_LOG_FULL_FORMAT) + '%x1e'
        if lastBuildCommit == gitCommit:
            p = Popen('git log --format="%s" %s -n 1' % (GIT_LOG_FORMAT, lastBuildCommit), cwd = self.gitSource, shell=True, stdout=PIPE)
        else:
            p = Popen('git log --format="%s" %s..%s' % (GIT_LOG_FORMAT, lastBuildCommit, gitCommit), cwd = self.gitSource, shell=True, stdout=PIPE)
        (log, _) = p.communicate()
        log = log.strip('\n\x1e').split("\x1e")
        log = [row.strip().split("\x1f") for row in log]
        log = [dict(zip(GIT_COMMIT_FIELDS, row)) for row in log]
        if not log:
            return 1
        cleanList=[]
        for p in log:
            message = p["message"]
            cleanString = ' '.join(re.findall ( '<CLEAN>(.*?)</CLEAN>', message, re.DOTALL))
            cleanList = cleanList + shlex.split(cleanString)
            uniqueCleanList = list(set(cleanList))
        uniqueCleanList.sort()
        return ' '.join(uniqueCleanList)

if __name__ == '__main__':

    parser = argparse.ArgumentParser("Command-line installer.")

    parser.add_argument("-s", "--gitSource", dest="gitSource", required=True,
                        help="Git source location (i.e. /local/S/Maya_2019_DI/src)")

    parser.add_argument("-sc", "--lastSuccessfulCommit", dest="lastSuccessfulCommit", default=None,
                        help="Last successful commit")

    parser.add_argument("-bc", "--lastBuildCommit", dest="lastBuildCommit", default=None,
                        help="Last build commit")

    parser.add_argument("-gc", "--gitCommit", dest="gitCommit", default=None,
                        help="New git commit")


    args = parser.parse_args()

    GITLogObj = GITLog(os.path.normpath(args.gitSource))

    if (args.lastSuccessfulCommit is None or args.lastBuildCommit is None or args.gitCommit is None):
        print "You must specify 'lastSuccessful', 'lastBuild' and 'new' GIT commit hash."
        sys.exit(1)

    commitInfo = GITLogObj.getCommitInfo(args.lastSuccessfulCommit, args.lastBuildCommit, args.gitCommit)
    if "" == commitInfo:
        print "Error getting Commit Info"
        sys.exit(1)
    else:
        print commitInfo
