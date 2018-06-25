//
//  ViewController.swift
//  WhatFlower
//
//  Created by Adam Moore on 5/10/18.
//  Copyright © 2018 Adam Moore. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikiPediaURL = "https://en.wikipedia.org/w/api.php"
    
    var flowerName = ""
    
    var parameters = [String: String]()
    

    let imagePicker = UIImagePickerController()
    
    @IBAction func camera(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var flowerDescription: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flowerDescription.text = ""
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // *** This is for if editing is disabled, i.e., use the original image.
//        let userPickedImage = info[UIImagePickerControllerOriginalImage]
        
        // *** This is for if editing is enabled.
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CIImage.")
            }
            
//            imageView.image = userPickedImage
            
            detect(flowerImage: ciImage)
            
            parameters = [
                    
                "format" : "json",
                "action" : "query",
                "prop" : "extracts|pageimages",
                "exintro" : "",
                "explaintext" : "",
                "titles" : flowerName,
                "indexpageids" : "",
                "redirects" : "1",
                "pithumbsize" : "500"
                    
            ]
            
            getFlowerData(url: wikiPediaURL, parameters: parameters)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(flowerImage: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            
            fatalError("Flower model failed to load.")
            
        }
        
        let request = VNCoreMLRequest(model: model) { (theRequest, theError) in
            
            guard let results = theRequest.results as? [VNClassificationObservation] else {
                
                fatalError("Image could not be processed.")
                
            }
            
            if let firstResult = results.first {
                
                self.flowerName = firstResult.identifier.capitalized
                self.navigationItem.title = self.flowerName
                
            }
            
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
            
            try handler.perform([request])
            
        } catch {
            
            print(error)
            
        }
        
        
    }
    
    
    func getFlowerData(url: String, parameters: [String: String]) {
        
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON { (response) in
            
            if response.result.isSuccess {
                
                print("Got flower data.")
                
                let flowerJSON: JSON = JSON(response.result.value!)
                
                self.getFlowerInfo(fromJSON: flowerJSON)
                
            } else {
                
                print("There was an error getting the data.")
                
            }
            
        }
        
    }
    
    func getFlowerInfo(fromJSON: JSON) {
        
        let pageID = fromJSON["query"]["pageids"][0]

        if let pageIDAsString = pageID.string {

            guard let description = fromJSON["query"]["pages"][pageIDAsString]["extract"].string else { return }
            
            guard let thumbnailImage = fromJSON["query"]["pages"][pageIDAsString]["thumbnail"]["source"].string else { return }
            
            print(description)
            
            flowerDescription.text = description
            
            self.imageView.sd_setImage(with: URL(string: thumbnailImage))

        }

    }

    
    
    
    
    
}













