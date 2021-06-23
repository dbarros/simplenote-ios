import Foundation
import CoreData

@objc
class SharedStorageMigrator: NSObject {
    /// Database Migration
    /// To be able to share data with app extensions, the CoreData database needs to be migrated to an app group
    /// Must run before Simperium is setup

    @objc
    func performMigrationIfNeeded() {
        // Confirm if the app group DB exists
        guard SharedStorageMigrator.migrationNeeded else {
            NSLog("Core Data Migration not required")
            return
        }

        migrateCoreDataToAppGroup()
    }

    static var migrationNeeded: Bool {
        FileManager.default.fileExists(atPath: CoreDataManager.legacyStorageURL.path) && !FileManager.default.fileExists(atPath: CoreDataManager.groupStorageURL.path)
    }

    func migrateCoreDataToAppGroup() {
        // Testing prints
        // TODO: Remove prints later
        print("oldDb exists \(FileManager.default.fileExists(atPath: CoreDataManager.legacyStorageURL.path))")
        print(CoreDataManager.legacyStorageURL.path)
        print("newDb exists \(FileManager.default.fileExists(atPath: CoreDataManager.groupStorageURL.path))")
        print(CoreDataManager.groupStorageURL.path)

        NSLog("Database needs migration to app group")
        NSLog("Beginning database migration")

        do {
            try migrateCoreDataStore()
            NSLog("Database migration successful!!")
        } catch {
            NSLog("Could not migrate database to app group")
            NSLog(error.localizedDescription)
        }
    }

    private func migrateCoreDataStore() throws {
        try createAppGroupDirectory()
        try migrateCoreDataFiles()
    }

    private func createAppGroupDirectory() throws {
        let destinationURL = FileManager.default.groupDirectory
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: false, attributes: nil)
    }

    private func migrateCoreDataFiles() throws {
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(atPath: fileManager.documentsURL.path)
            try files.forEach { (file) in
                let oldPath = fileManager.documentsURL.appendingPathComponent(file)
                let newPath = fileManager.groupDocumentsDirectory.appendingPathComponent(file)
                try fileManager.copyItem(at: oldPath, to: newPath)
            }
        } catch {
            // TODO: if migration fails confirm the new dir is deleted
            NSLog("Could not migrate core data files")
            NSLog(error.localizedDescription)
        }
    }
}
