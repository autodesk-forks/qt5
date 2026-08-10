 /* GEC-OSS Pipeline
  * ================
  * Template Reference: https://git.autodesk.com/EngOps/gec-oss-pipeline-template/
  * Document: https://wiki.autodesk.com/display/ENGOPS/GEC-OSS+Build+Framework
  * Maintainer: EngOps Team Stark <engops.team.stark@autodesk.com>
  */
@Library(["oss-psl@cer", "PSL"]) _

buildPipeline {
    /**********************************************************
     * Required configuration: Build Configuration Definition *
     **********************************************************/
    buildConfigurationMatrix = [
        'windows': [
            0: [
                'qt5.win.debug': [
                    'image_args': '--pull -f adsk-build-scripts/Dockerfile.windows .',
                    'command_args': 'debug'
                ],
                'qt5.win.release': [
                    'image_args': '--pull -f adsk-build-scripts/Dockerfile.windows .',
                    'command_args': 'release'
                ],
            ],
        ],
        'linux': [
            0: [
                'qt5.lnx.ubuntu22.debug': [
                    'image_args': '--pull -f adsk-build-scripts/Dockerfile.linux .',
                    'command_args': 'debug'
                ],
                'qt5.lnx.ubuntu22.release': [
                    'image_args': '--pull -f adsk-build-scripts/Dockerfile.linux .',
                    'command_args': 'release'
                ],
                'qt5.lnx.rocky86.debug': [
                    'image_args': '--pull -f adsk-build-scripts/Dockerfile_rocky86.linux .',
                    'command_args': 'debug'
                ],
                'qt5.lnx.rocky86.release': [
                    'image_args': '--pull -f adsk-build-scripts/Dockerfile_rocky86.linux .',
                    'command_args': 'release'
                ],
            ],
        ],
        'mac': [
            'GEC-QT68-MAC': [
                'qt5.mac': [
                    'build_script': './adsk-build-scripts/BuildQtOnMacOS.sh',
                ],
            ],
        ],
    ]
    
    // Optional configuration: Give a different name for Artifactory & CER Registration. Default: GIT_REPO
    componentName = "Qt"
    
    // Optional configuration: Use a different VMSS specs. 
    // Default: null (i.e. Normal VMSS). 
    // Choices: null (Azure F16s_v2) or "xl" (Azure F32s_v2)
    vmssSpec = "xl"

    // Optional configuration: Overwrite the Artifactory Repo Target (default: oss-stg-<type>/$componentName/$pkgVersion/GEC)
    artifactoryNugetTargetRoot = { -> "oss-stg-nuget/$componentName/${params.pkgVersion}/gec/lgpl" }
    artifactoryGenericTargetRoot = { -> "oss-stg-generic/$componentName/${params.pkgVersion}/gec/lgpl" }
}
