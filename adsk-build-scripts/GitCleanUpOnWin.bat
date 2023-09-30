@rem #################################################
@rem @file GitCleanUpOnWin.bat
@rem @brief Clean up all untracked files in the git clone directory
@rem @details Clean up git untracked files in the git clone directory
@rem     1.Clean up all untracked files in the main directory.
@rem     2.Clean up all untracked fiels in the submodules directory.
@rem @attention 
@rem     1.If we want to rebuild Qt again, we really need to clean up the cache files produced by last building.
@rem     2.If this bat file is tracked by git then everything is OK.
@rem     3.If this bat file is not tracked by git then this bat will be deleted too, so you should put this bat outof the git directory.
@rem @author Huimin Wen(Jess)
@rem @date 12/16/2021
@rem @eaxmple
@rem     1.This bat file is tracked by git, you should just execute the below command:
@rem        GitCleanUpOnWin.bat ../
@rem     2.This bat file is not tracked by git.
@rem        1).Please put this bat file to the parent folder of qt git directory,  which looks like below structure:
@rem                    QT_PARENT_FOLDER--------qt
@rem      	                                                  |----GitCleanUpOnWin.bat
@rem        2).Execute the below command:
@rem                    GitCleanUpOnWin.bat qt
@rem #################################################

@echo off
@rem Set destination path needed to be clean up
if "%1" neq "" (
	set DST_PATH=%1
	echo Git Clean Up Path:%DST_PATH%
) else (
	@rem set DST_PATH=qt5
	echo Usage: GitCleanUpOnWin.bat DST_PATH
	goto :eof
)

@rem Set options for this bat
set CUR_BAT_PATH=%~dp0

@echo on
@rem Clean up
cd %DST_PATH%
git clean -xfd
git submodule foreach --recursive git clean -xfd
git reset --hard
git submodule foreach --recursive git reset --hard
git submodule update --init --recursive

cd %CUR_BAT_PATH%

