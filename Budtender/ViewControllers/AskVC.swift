//
//  AskVC.swift
//  Budtender
//
//  Created by raptor on 24/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import UIKit
import ImagePicker
import SwiftValidators

class AskVC: CommonVC {
    @IBOutlet weak var question: UITextView!
    @IBOutlet weak var photo: UIImageView!

    @IBAction func onPhotoAction(_ sender: UITapGestureRecognizer) {
        let imagePicker = ImagePickerController()
        imagePicker.delegate = self
        imagePicker.imageLimit = 1
        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func onBackAcntion(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func onSubmitAction(_ sender: UIBarButtonItem) {
        if Validator.isEmpty().apply(question.text) {
            view.makeToast("Please input question", position: .center)
            question.becomeFirstResponder()
        } else {
            dismissKeyboard()

            var param: [String: Any] = [
                "a": getString(.authToken)!,
                "uid": getInt(.userId),
                "b": question.text!
            ]
            if photo.image != #imageLiteral(resourceName: "camera"), let img = UIImageJPEGRepresentation(photo.image!, 0.5) {
                param["i"] = "data:image/jpeg;base64,\(img.base64EncodedString(options: .lineLength64Characters))"
            }
            post(url: "/api_sendquestion.php", param: param) { _ in
                let alertVC = UIAlertController(
                    title: nil,
                    message: "Thank you for your question, it will be reviewed and may appear soon.",
                    preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
}

extension AskVC: ImagePickerDelegate {
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.resetAssets()
    }

    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.dismiss(animated: true, completion: nil)
        if !images.isEmpty {
            photo.image = images.first
        }
    }

    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

