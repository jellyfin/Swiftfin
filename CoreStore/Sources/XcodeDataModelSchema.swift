//
//  XcodeDataModelSchema.swift
//  CoreStore
//
//  Copyright © 2018 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import CoreData
import Foundation


// MARK: - XcodeDataModelSchema

/**
 The `XcodeDataModelSchema` describes a model version declared in a single *.xcdatamodeld file.
 ```
 CoreStoreDefaults.dataStack = DataStack(
     XcodeDataModelSchema(modelName: "MyAppV1", bundle: .main)
 )
 ```
 */
public final class XcodeDataModelSchema: DynamicSchema {
    
    /**
     Creates a `XcodeDataModelSchema` for each of the models declared in the specified (.xcdatamodeld) model file.
     - parameter modelName: the name of the (.xcdatamodeld) model file. If not specified, the application name (CFBundleName) will be used if it exists, or "CoreData" if it the bundle name was not set.
     - parameter bundle: an optional bundle to load .xcdatamodeld models from. If not specified, the main bundle will be used.
     - parameter migrationChain: the `MigrationChain` that indicates the sequence of model versions to be used as the order for progressive migrations. If not specified, will default to a non-migrating data stack.
     - returns: a tuple containing all `XcodeDataModelSchema` for the models declared in the specified .xcdatamodeld file, and the current model version string declared or inferred from the file.
     */
    public static func from(
        modelName: XcodeDataModelFileName,
        bundle: Bundle = Bundle.main,
        migrationChain: MigrationChain = nil
    ) -> (
        allSchema: [XcodeDataModelSchema],
        currentModelVersion: ModelVersion
    ) {

        guard let modelFilePath = bundle.path(forResource: modelName, ofType: "momd") else {
            
            // For users migrating from very old Xcode versions: Old xcdatamodel files are not contained inside xcdatamodeld (with a "d"), and will thus fail this check. If that was the case, create a new xcdatamodeld file and copy all contents into the new model.
            let foundModels = bundle
                .paths(forResourcesOfType: "momd", inDirectory: nil)
                .map({ ($0 as NSString).lastPathComponent })
            Internals.abort("Could not find \"\(modelName).momd\" from the bundle \"\(bundle.bundleIdentifier ?? "<nil>")\". Other model files in bundle: \(foundModels.coreStoreDumpString)")
        }
        
        let modelFileURL = URL(fileURLWithPath: modelFilePath)
        let versionInfoPlistURL = modelFileURL.appendingPathComponent("VersionInfo.plist", isDirectory: false)
        
        guard let versionInfo = NSDictionary(contentsOf: versionInfoPlistURL),
            let versionHashes = versionInfo["NSManagedObjectModel_VersionHashes"] as? [String: AnyObject] else {
                
                Internals.abort("Could not load \(Internals.typeName(NSManagedObjectModel.self)) metadata from path \"\(versionInfoPlistURL)\".")
        }
        
        let modelVersions = Set(versionHashes.keys)
        let modelVersionHints = migrationChain.leafVersions
        let currentModelVersion: String
        if let plistModelVersion = versionInfo["NSManagedObjectModel_CurrentVersionName"] as? String,
            modelVersionHints.isEmpty || modelVersionHints.contains(plistModelVersion) {
            
            currentModelVersion = plistModelVersion
        }
        else if let resolvedVersion = modelVersions.intersection(modelVersionHints).first {
            
            Internals.log(
                .warning,
                message: "The \(Internals.typeName(MigrationChain.self)) leaf versions do not include the model file's current version. Resolving to version \"\(resolvedVersion)\"."
            )
            currentModelVersion = resolvedVersion
        }
        else if let resolvedVersion = modelVersions.first ?? modelVersionHints.first {
            
            if !modelVersionHints.isEmpty {
                
                Internals.log(
                    .warning,
                    message: "The \(Internals.typeName(MigrationChain.self)) leaf versions do not include any of the model file's embedded versions. Resolving to version \"\(resolvedVersion)\"."
                )
            }
            currentModelVersion = resolvedVersion
        }
        else {
            
            Internals.abort("No model files were found in URL \"\(modelFileURL)\".")
        }
        var allSchema: [XcodeDataModelSchema] = []
        for modelVersion in modelVersions {
            
            let fileURL = modelFileURL.appendingPathComponent("\(modelVersion).mom", isDirectory: false)
            allSchema.append(XcodeDataModelSchema(modelName: modelVersion, modelVersionFileURL: fileURL))
        }
        return (allSchema, currentModelVersion)
    }
    
    /**
     Initializes an `XcodeDataModelSchema` from an *.xcdatamodeld version name and its containing `Bundle`.
     ```
     CoreStoreDefaults.dataStack = DataStack(
         XcodeDataModelSchema(modelName: "MyAppV1", bundle: .main)
     )
     ```
     - parameter modelName: the model version, typically the file name of an *.xcdatamodeld file (without the file extension)
     - parameter bundle: the `Bundle` that contains the .xcdatamodeld's "momd" file. If not specified, the `Bundle.main` will be searched.
     */
    public convenience init(
        modelName: ModelVersion,
        bundle: Bundle = Bundle.main
    ) {

        guard let modelFilePath = bundle.path(forResource: modelName, ofType: "momd") else {
            
            // For users migrating from very old Xcode versions: Old xcdatamodel files are not contained inside xcdatamodeld (with a "d"), and will thus fail this check. If that was the case, create a new xcdatamodeld file and copy all contents into the new model.
            let foundModels = bundle
                .paths(forResourcesOfType: "momd", inDirectory: nil)
                .map({ ($0 as NSString).lastPathComponent })
            Internals.abort("Could not find \"\(modelName).momd\" from the bundle \"\(bundle.bundleIdentifier ?? "<nil>")\". Other model files in bundle: \(foundModels.coreStoreDumpString)")
        }
        
        let modelFileURL = URL(fileURLWithPath: modelFilePath)
        let fileURL = modelFileURL.appendingPathComponent("\(modelName).mom", isDirectory: false)
        self.init(modelName: modelName, modelVersionFileURL: fileURL)
    }
    
    /**
     Initializes an `XcodeDataModelSchema` from an *.xcdatamodeld file URL.
     ```
     CoreStoreDefaults.dataStack = DataStack(
         XcodeDataModelSchema(modelName: "MyAppV1", modelVersionFileURL: fileURL)
     )
     ```
     - parameter modelName: the model version, typically the file name of an *.xcdatamodeld file (without the file extension)
     - parameter modelVersionFileURL: the file URL that points to the .xcdatamodeld's "momd" file.
     */
    public required init(
        modelName: ModelVersion,
        modelVersionFileURL: URL
    ) {

        Internals.assert(
            NSManagedObjectModel(contentsOf: modelVersionFileURL) != nil,
            "Could not find the \"\(modelName).mom\" version file for the model at URL \"\(modelVersionFileURL)\"."
        )
        
        self.modelVersion = modelName
        self.modelVersionFileURL = modelVersionFileURL
    }
    
    
    // MARK: DynamicSchema
    
    public let modelVersion: ModelVersion
    
    public func rawModel() -> NSManagedObjectModel {
    
        if let cachedRawModel = self.cachedRawModel {
            
            return cachedRawModel
        }
        if let rawModel = NSManagedObjectModel(contentsOf: self.modelVersionFileURL) {
            
            self.cachedRawModel = rawModel
            return rawModel
        }
        Internals.abort("Could not create an \(Internals.typeName(NSManagedObjectModel.self)) from the model at URL \"\(self.modelVersionFileURL)\".")
    }
    
    
    // MARK: Internal
    
    internal let modelVersionFileURL: URL
    
    private lazy var rootModelFileURL: URL = Internals.with { [unowned self] in
     
        return self.modelVersionFileURL.deletingLastPathComponent()
    }
    
    
    // MARK: Private
    
    private weak var cachedRawModel: NSManagedObjectModel?
}
