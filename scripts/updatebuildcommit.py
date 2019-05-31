import argparse
import os
import json

gitCommitLog = '../commit.log'

class commitInfo:
    def getGitCommitLog(self, product, branch, buildType, buildConfig):
        lastSuccessCommit = lastBuildCommit = ""
        if not os.path.isfile(gitCommitLog):
            with open(gitCommitLog, 'w') as f:
                f.write(json.dumps({}))
        data = json.load(open(gitCommitLog))
        if product in data:
            if branch in data[product]:
                if buildType in data[product][branch]:
					if buildConfig in data[product][branch][buildType]:
						lastSuccessCommit = data[product][branch][buildType][buildConfig]["lastSuccessCommit"]
						lastBuildCommit = data[product][branch][buildType][buildConfig]["lastBuildCommit"]
        return lastSuccessCommit, lastBuildCommit

    def setGitCommitLog(self, product, branch, buildType, buildConfig, lastSuccessCommit, lastBuildCommit):
        if not os.path.isfile(gitCommitLog):
            with open(gitCommitLog, 'w') as f:
                f.write(json.dumps({}))
        data = json.load(open(gitCommitLog))

        if product not in data:
            data[product] = {}
        if branch not in data[product]:
            data[product][branch] = {}
        if buildType not in data[product][branch]:
            data[product][branch][buildType] = {}
        if buildConfig not in data[product][branch][buildType]:
            data[product][branch][buildType][buildConfig] = {}
        data[product][branch][buildType][buildConfig]["lastSuccessCommit"] = lastSuccessCommit
        data[product][branch][buildType][buildConfig]["lastBuildCommit"] = lastBuildCommit
        with open(gitCommitLog, "w") as f:
            f.write(json.dumps(data))


if __name__ == "__main__":
    parser = argparse.ArgumentParser("Command-line installer.")
    parser.add_argument('-g', "--get", action='store_true',
                        help="Get commit info")
    parser.add_argument("-s", "--set", action='store_true',
                        help="Set commit info")
    parser.add_argument("-p", "--product", dest="product", required="True",
                        help="Product")
    parser.add_argument("-b", "--branch", dest="branch", required="True",
                        help="GIT branch")
    parser.add_argument("-t", "--type", dest="type", required="True",
                        help="Build Type (i.e. CI or DI)")
    parser.add_argument("-c", "--config", dest="config", required="True",
                        help="Build Config (i.e. Debug or Release)")
    parser.add_argument("-sc", "--lastSuccessfulCommit", dest="lastSuccessfulCommit", default=None,
                        help="Last successful commit")
    parser.add_argument("-bc", "--lastBuildCommit", dest="lastBuildCommit", default=None,
                        help="Last build commit - Regardless whether build was succeeded or not")

    args = parser.parse_args()
    commitInfoObj = commitInfo()

    if (args.set and (args.lastSuccessfulCommit is None or args.lastBuildCommit is None)):
        print "You must specify 'lastSuccessful' and 'lastBuild' commits."
        sys.exit(1)

    if args.get:
        lastSuccessCommit, lastBuildCommit = commitInfoObj.getGitCommitLog(args.product,args.branch,args.type, args.config)
        print lastSuccessCommit, lastBuildCommit

    if args.set:
        commitInfoObj.setGitCommitLog(args.product,args.branch,args.type, args.config, args.lastSuccessfulCommit, args.lastBuildCommit)
