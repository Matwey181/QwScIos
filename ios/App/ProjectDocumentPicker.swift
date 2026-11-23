import SwiftUI
import UniformTypeIdentifiers

struct ProjectDocumentPicker:UIViewControllerRepresentable {
    var picked:(URL)->Void
    var cancelled:()->Void
    func makeCoordinator()->Coordinator{Coordinator(self)}
    func makeUIViewController(context:Context)->UIDocumentPickerViewController {
        let project=UTType(importedAs:"com.matwey181.qwel.project",conformingTo:.zip)
        let picker=UIDocumentPickerViewController(forOpeningContentTypes:[project,.json,.zip,.data],asCopy:true)
        picker.allowsMultipleSelection=false
        picker.shouldShowFileExtensions=true
        picker.delegate=context.coordinator
        return picker
    }
    func updateUIViewController(_ controller:UIDocumentPickerViewController,context:Context){context.coordinator.parent=self}
    final class Coordinator:NSObject,UIDocumentPickerDelegate {
        var parent:ProjectDocumentPicker
        init(_ parent:ProjectDocumentPicker){self.parent=parent}
        func documentPicker(_ controller:UIDocumentPickerViewController,didPickDocumentsAt urls:[URL]){
            guard let url=urls.first else{parent.cancelled();return}
            parent.picked(url)
        }
        func documentPickerWasCancelled(_ controller:UIDocumentPickerViewController){parent.cancelled()}
    }
}
