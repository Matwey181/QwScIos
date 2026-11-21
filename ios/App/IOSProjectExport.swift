import Foundation
import ZIPFoundation

@MainActor enum IOSProjectExport {
    static func make(_ value:Project,root:URL) throws ->URL {
        var project=value;project.syncPage()
        let temp=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let folder=temp.appendingPathComponent("QwelApp"),resources=folder.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at:resources,withIntermediateDirectories:true)
        let source=SwiftExport.make(project,root:root)
        try source.write(to:folder.appendingPathComponent("Design.swift"),atomically:true,encoding:.utf8)
        let app="""
        import SwiftUI
        @main struct QwelApp: App {
            var body: some Scene {
                WindowGroup {
                    GeometryReader { g in
                        QwelExportedView().frame(width: \(project.w), height: \(project.h))
                            .scaleEffect(min(g.size.width / \(project.w), g.size.height / \(project.h)))
                            .frame(width: g.size.width, height: g.size.height)
                    }
                }
            }
        }
        """
        try app.write(to:folder.appendingPathComponent("QwelApp.swift"),atomically:true,encoding:.utf8)
        let all=project.nodes+project.pages.flatMap(\.nodes)+(project.studio?.states.flatMap(\.nodes) ?? [])
        var fontPaths:[String]=[]
        try writeSource(project,root:root,to:folder.appendingPathComponent("Design.qwel"))
        for (kind,names) in [("assets",Set(all.map(\.asset).filter{!$0.isEmpty})),("fonts",Set(all.map(\.font).filter{!$0.isEmpty}))]{
            let target=resources.appendingPathComponent(kind);try FileManager.default.createDirectory(at:target,withIntermediateDirectories:true)
            for name in names {
                let file=root.appendingPathComponent(kind).appendingPathComponent(name)
                guard FileManager.default.fileExists(atPath:file.path) else{continue}
                try FileManager.default.copyItem(at:file,to:target.appendingPathComponent(name))
                if kind=="fonts"{fontPaths.append("Resources/fonts/"+name)}
            }
        }
        let info:[String:Any]=["CFBundleDevelopmentRegion":"en","CFBundleExecutable":"$(EXECUTABLE_NAME)","CFBundleIdentifier":"$(PRODUCT_BUNDLE_IDENTIFIER)","CFBundleName":project.name,"CFBundlePackageType":"APPL","CFBundleShortVersionString":"1.0","CFBundleVersion":"1","LSRequiresIPhoneOS":true,"UILaunchScreen":[:],"UIAppFonts":fontPaths,"UISupportedInterfaceOrientations":["UIInterfaceOrientationPortrait","UIInterfaceOrientationLandscapeLeft","UIInterfaceOrientationLandscapeRight"]]
        try PropertyListSerialization.data(fromPropertyList:info,format:.xml,options:0).write(to:folder.appendingPathComponent("Info.plist"))
        let xcode=folder.appendingPathComponent("QwelApp.xcodeproj");try FileManager.default.createDirectory(at:xcode,withIntermediateDirectories:true)
        try pbx.write(to:xcode.appendingPathComponent("project.pbxproj"),atomically:true,encoding:.utf8)
        let readme="""
        \(project.name)
        Open QwelApp.xcodeproj in Xcode. Choose your development team in Signing & Capabilities and run on an iPhone or simulator.
        Design.swift contains the visual layout and interaction runtime. Resources contains the original images and fonts. Design.qwel reopens the editable document in Qwel.
        iOS 17 or later. No external packages or project generators required.
        """
        try readme.write(to:folder.appendingPathComponent("README.txt"),atomically:true,encoding:.utf8)
        let output=temp.appendingPathComponent(safeName(project.name)+"-iOS.zip"),zip=try Archive(url:output,accessMode:.create)
        let files=FileManager.default.enumerator(at:folder,includingPropertiesForKeys:[.isRegularFileKey])
        while let file=files?.nextObject() as? URL {
            guard (try file.resourceValues(forKeys:[.isRegularFileKey])).isRegularFile==true else{continue}
            let path="QwelApp/"+String(file.path.dropFirst(folder.path.count+1))
            try zip.addEntry(with:path,fileURL:file,compressionMethod:.deflate)
        }
        return output
    }
    private static func writeSource(_ project:Project,root:URL,to url:URL) throws {
        let zip=try Archive(url:url,accessMode:.create),data=try JSONEncoder().encode(project)
        try zip.addEntry(with:"project.json",type:.file,uncompressedSize:Int64(data.count),compressionMethod:.deflate){offset,size in data.subdata(in:Int(offset)..<min(data.count,Int(offset)+size))}
        let nodes=project.nodes+project.pages.flatMap(\.nodes)+(project.studio?.states.flatMap(\.nodes) ?? [])
        for (kind,names) in [("assets",Set(nodes.map(\.asset).filter{!$0.isEmpty})),("fonts",Set(nodes.map(\.font).filter{!$0.isEmpty}))]{for name in names{let file=root.appendingPathComponent(kind).appendingPathComponent(name);if FileManager.default.fileExists(atPath:file.path){try zip.addEntry(with:kind+"/"+name,fileURL:file,compressionMethod:.deflate)}}}
    }
    static let pbx="""
    // !$*UTF8*$!
    { archiveVersion = 1; classes = {}; objectVersion = 56; objects = {
    000000000000000000000001 = {isa = PBXProject; buildConfigurationList = 000000000000000000000020; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; knownRegions = (en, Base); mainGroup = 000000000000000000000002; productRefGroup = 000000000000000000000003; projectDirPath = ""; projectRoot = ""; targets = (000000000000000000000004); };
    000000000000000000000002 = {isa = PBXGroup; children = (000000000000000000000005, 000000000000000000000006, 000000000000000000000007, 000000000000000000000003); sourceTree = "<group>"; };
    000000000000000000000003 = {isa = PBXGroup; children = (000000000000000000000008); name = Products; sourceTree = "<group>"; };
    000000000000000000000004 = {isa = PBXNativeTarget; buildConfigurationList = 000000000000000000000021; buildPhases = (000000000000000000000010, 000000000000000000000011, 000000000000000000000012); buildRules = (); dependencies = (); name = QwelApp; productName = QwelApp; productReference = 000000000000000000000008; productType = "com.apple.product-type.application"; };
    000000000000000000000005 = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = QwelApp.swift; sourceTree = "<group>"; };
    000000000000000000000006 = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Design.swift; sourceTree = "<group>"; };
    000000000000000000000007 = {isa = PBXFileReference; lastKnownFileType = folder; path = Resources; sourceTree = "<group>"; };
    000000000000000000000008 = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = QwelApp.app; sourceTree = BUILT_PRODUCTS_DIR; };
    000000000000000000000009 = {isa = PBXBuildFile; fileRef = 000000000000000000000005; };
    00000000000000000000000A = {isa = PBXBuildFile; fileRef = 000000000000000000000006; };
    00000000000000000000000B = {isa = PBXBuildFile; fileRef = 000000000000000000000007; };
    000000000000000000000010 = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (000000000000000000000009, 00000000000000000000000A); runOnlyForDeploymentPostprocessing = 0; };
    000000000000000000000011 = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
    000000000000000000000012 = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (00000000000000000000000B); runOnlyForDeploymentPostprocessing = 0; };
    000000000000000000000020 = {isa = XCConfigurationList; buildConfigurations = (000000000000000000000022, 000000000000000000000023); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
    000000000000000000000021 = {isa = XCConfigurationList; buildConfigurations = (000000000000000000000024, 000000000000000000000025); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
    000000000000000000000022 = {isa = XCBuildConfiguration; buildSettings = {SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SWIFT_VERSION = 5.0; }; name = Debug; };
    000000000000000000000023 = {isa = XCBuildConfiguration; buildSettings = {SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SWIFT_VERSION = 5.0; }; name = Release; };
    000000000000000000000024 = {isa = XCBuildConfiguration; buildSettings = {CODE_SIGN_STYLE = Automatic; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = Info.plist; PRODUCT_BUNDLE_IDENTIFIER = com.qwel.exported; PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = "1,2"; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; }; name = Debug; };
    000000000000000000000025 = {isa = XCBuildConfiguration; buildSettings = {CODE_SIGN_STYLE = Automatic; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = Info.plist; PRODUCT_BUNDLE_IDENTIFIER = com.qwel.exported; PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = "1,2"; SWIFT_OPTIMIZATION_LEVEL = "-O"; }; name = Release; };
    }; rootObject = 000000000000000000000001; }
    """
}
