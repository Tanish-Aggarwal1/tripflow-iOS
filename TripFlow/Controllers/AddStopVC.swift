import UIKit
import PhotosUI

/// Author: Joann Monteiro
/// Modal form for adding a new Stop to a trip: collects a name, category,
/// optional notes, and an optional photo (via PHPicker), then saves via
/// DatabaseManager and dismisses.
class AddStopVC: UIViewController {

    /// Id of the trip this stop belongs to. Set by TripDetailVC before presenting.
    var tripId: Int64?

    /// Position this stop should be inserted at (end of the current list). Set by TripDetailVC.
    var nextSortOrder: Int = 0

    /// Stop name text entry.
    @IBOutlet weak var nameField: UITextField!
    /// Picks one of the fixed category options.
    @IBOutlet weak var categoryPicker: UIPickerView!
    /// Optional free-text notes about the stop.
    @IBOutlet weak var notesField: UITextField!
    /// Shows a thumbnail of the picked photo, if any.
    @IBOutlet weak var photoPreview: UIImageView!

    /// Fixed set of stop categories shown in categoryPicker.
    private let categories = ["Food", "Sightseeing", "Hotel", "Other"]

    /// Filename (not full path) of the photo saved to Documents, if the user picked one.
    private var photoFilename: String?

    /// Sets up the nav bar (Cancel/Save), picker/text field delegates, and keyboard dismissal.
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Stop"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
        nameField.delegate = self
        notesField.delegate = self
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing)))
    }

    /// Dismisses the form without saving.
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    /// Presents the system photo picker, limited to a single image.
    @IBAction func choosePhotoTapped(_ sender: UIButton) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    /// Validates the name, inserts the stop into the database, then dismisses.
    @objc private func saveTapped() {
        guard let tripId else { return }

        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            let alert = UIAlertController(title: "Stop name required", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let category = categories[categoryPicker.selectedRow(inComponent: 0)]
        let notes = notesField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        DatabaseManager.shared.insertStop(
            tripId: tripId,
            name: name,
            category: category,
            notes: (notes?.isEmpty ?? true) ? nil : notes,
            photoPath: photoFilename,
            sortOrder: nextSortOrder
        )
        dismiss(animated: true)
    }

    /// Writes `image` as JPEG into the app's Documents directory under a unique
    /// filename and returns that filename (not the full path — the sandbox's
    /// Documents URL can change between installs, so only the filename is
    /// stored; readers rebuild the full path themselves at read time).
    private func savePhotoToDocuments(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = "stop-\(UUID().uuidString).jpg"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: destinationURL)
            return filename
        } catch {
            print("AddStopVC: failed to save photo - \(error)")
            return nil
        }
    }
}

extension AddStopVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        categories.count
    }

    /// Category label for row.
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        categories[row]
    }
}

extension AddStopVC: UITextFieldDelegate {
    /// Dismisses the keyboard when the user taps Return in a text field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AddStopVC: PHPickerViewControllerDelegate {
    /// Loads the picked image (if any), previews it, and saves it to Documents.
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.photoPreview.image = image
                self.photoFilename = self.savePhotoToDocuments(image)
            }
        }
    }
}
