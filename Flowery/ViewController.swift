//
//  ViewController.swift
//  Flowery
//
//  Created by Abdelrahman Shehab on 4/16/20.
//  Copyright © 2020 Abdelrahman Shehab. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController {

    @IBOutlet weak var flowerImageView: UIImageView!
    @IBOutlet weak var infoView: UIVisualEffectView!
    @IBOutlet weak var flowerLabel: UILabel!

    let flowerImagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    override func viewDidLoad() {
        super.viewDidLoad()
        flowerImagePicker.delegate = self
        infoView.layer.cornerRadius = 10
        infoView.clipsToBounds = true

    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {

        let optionMenu = UIAlertController(title: "Photo Source", message: "Need to choose the source which you want to pick", preferredStyle: .actionSheet)

        optionMenu.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            self.flowerImagePicker.sourceType = .camera
            self.flowerImagePicker.allowsEditing = false
            self.present(self.flowerImagePicker, animated: true, completion: nil)
        }))

        optionMenu.addAction(UIAlertAction(title: "Photo Liberery", style: .default, handler: { (action) in
            self.flowerImagePicker.sourceType = .photoLibrary
            self.flowerImagePicker.allowsEditing = true
            self.present(self.flowerImagePicker, animated: true, completion: nil)
        }))

        optionMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(optionMenu, animated: true, completion: nil)
    }

    //MARK: - Detection Method

    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Error in Loading CoreML Model!")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model Failed To Process Image!")
            }
            guard let classifiaction = results.first else {return}
            print(classifiaction.identifier)
            DispatchQueue.main.async {
                self.navigationItem.title = classifiaction.identifier.capitalized
                self.requestInfo(flowerName: classifiaction.identifier)
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch  {
            print(error)
        }
    }

    //MARK: - HTTP Get Method

    func requestInfo(flowerName: String) {

        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500",
        ]

        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result{
                case let .success(value):

                    let flowerJSON : JSON = JSON(value)
                    let pageid = flowerJSON["query"]["pageids"][0].stringValue
                    // Show the description of Picked Image form WIKI
                    let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                    // Show Image of Picked Image from WIKI
                    let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue

                    // Rendering in Views
                    self.flowerLabel.text = flowerDescription
                    self.flowerImageView.sd_setImage(with: URL(string: flowerImageURL))
                case let .failure(error):
                    print(error)
            }
        }
    }

}

//MARK: - UIImage Picker Methods

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userImagePicked = info[.originalImage] as? UIImage{
            flowerImageView.image = userImagePicked
            guard let convertedCiimage = CIImage(image: userImagePicked) else {
                fatalError("Could Not Convert UIImage to CIImage!")
            }
            detect(image: convertedCiimage)
        }

        flowerImagePicker.dismiss(animated: true, completion: nil)
    }
}
