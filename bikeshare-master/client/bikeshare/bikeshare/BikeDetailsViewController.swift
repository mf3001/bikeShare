//
//  BikeDetailsViewController.swift
//  bikeshare
//
//  Created by Derrick on 5/12/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit



class BikeDetailsViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var bikeModelField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var cityField: UITextField!
    @IBOutlet weak var stateField: UITextField!
    @IBOutlet weak var countryField: UITextField!
    @IBOutlet weak var postCodeField: UITextField!
    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var availabilitySwitch: UISwitch!
    @IBOutlet weak var detailsFiled: UITextView!
    
    
    @IBOutlet weak var imageView: UIImageView!
    
     let imagePicker = UIImagePickerController()
    
    @IBAction func selectPhoto(sender: AnyObject) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    

    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .ScaleAspectFit
            imageView.image = pickedImage
            
            
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func UploadRequest()
    {
        let temp_bid = self.currentBike!["bid"]! as! Int
        let url = NSURL(string: serverDomain + "/upload/" + String(temp_bid))
        
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        
        let boundary = generateBoundaryString()
        
        //define the multipart request type
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if (imageView.image == nil)
        {
            return
        }
        
        let image_data = UIImagePNGRepresentation(imageView.image!)
        
        
        if(image_data == nil)
        {
            return
        }
        
        
        let body = NSMutableData()
        
        let fname = "photo_" + String(temp_bid) + ".jpg"
        let mimetype = "image/jpeg"
        
        //define the data post parameter
        
        body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Disposition:form-data; name=\"test\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("hi\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        
        body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Disposition:form-data; name=\"file\"; filename=\"\(fname)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Type: \(mimetype)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(image_data!)
        body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        body.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        
        
        request.HTTPBody = body
        
        
        
        let session = NSURLSession.sharedSession()
        
        
        let task = session.dataTaskWithRequest(request) {
            (
            let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print(dataString)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        
        task.resume()
        
        
    }
    
    
    func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    

    

    
    
    var currentBike : Dictionary<String, AnyObject>?
    var lat: Float?
    var lng: Float?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        // Do any additional setup after loading the view.
        
        if (currentBike?.count != 0){
            dispatch_async(dispatch_get_main_queue(),{
                print("currentBike \(self.currentBike)")
                self.bikeModelField?.text = self.currentBike!["model"] as? String
                self.addressField?.text = self.currentBike!["address"] as? String
                self.cityField?.text = self.currentBike?["city"] as? String
                self.stateField?.text = self.currentBike?["state"] as? String
                self.countryField?.text = self.currentBike?["country"] as? String
                self.postCodeField?.text = self.currentBike?["postcode"] as? String
                self.priceField?.text = (self.currentBike!["price"] as? Float)?.description
                self.availabilitySwitch?.on = (self.currentBike!["status"] as? Bool)!
                self.detailsFiled?.text = self.currentBike!["details"] as? String

            })
        }
        
    }
    
    private func addBike(){
        
        let bikeModel = self.bikeModelField.text!
        let address =  self.addressField.text!
        let city = self.cityField.text!
        let state = self.stateField.text!
        let country = self.countryField.text!
        let postcode = self.postCodeField.text!
        let price = (self.priceField.text! as NSString).floatValue
        let availability = self.availabilitySwitch.on
        let details = self.detailsFiled.text!
        let s_lat = lat!
        let s_lng = lng!
        
        
        let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/addBike")!)
        request.HTTPMethod = "POST"
        
        let payload = "model=\(bikeModel)&address=\(address)&city=\(city)&state=\(state)&country=\(country)&postcode=\(postcode)&price=\(price)&available=\(availability)&details=\(details)&lat=\(s_lat)&lon=\(s_lng)"
        let payloadWithoutSpace = payload.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        request.HTTPBody = payloadWithoutSpace!.dataUsingEncoding(NSUTF8StringEncoding)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response: \(response)")
            let strData = NSString(data: (data)!, encoding: NSUTF8StringEncoding)
            print("Body: \(strData)")
            
            if let httpResponse = response as? NSHTTPURLResponse {
                if(httpResponse.statusCode == 200){
                    //sign up successfully
                    //all ui change must happen in main thread. I think the issue is that async http request is in different thread.
                    //so use this method to push code back to main thread
                    if let result = data{
                        print(NSString(data: result, encoding: NSUTF8StringEncoding))
                        do {
                            let jsonResult = try NSJSONSerialization.JSONObjectWithData(result, options: .AllowFragments)
                            dispatch_async(dispatch_get_main_queue()) {
                                self.currentBike!["bid"] = jsonResult["result"]!!["bid"]
                                self.UploadRequest()
                            }
                        } catch {
                            print("error serializing JSON: \(error)")
                        }
                    }
                    
                    
                    
                    print("Saved!!!!!")
                }
            } else {
                assertionFailure("unexpected response")
            }
        })
        task.resume()
    }
    
    
    private func updateBike(){
        
        let bikeModel = self.bikeModelField.text!
        let address =  self.addressField.text!
        let city = self.cityField.text!
        let state = self.stateField.text!
        let country = self.countryField.text!
        let postcode = self.postCodeField.text!
        let price = (self.priceField.text! as NSString).floatValue
        let availability = self.availabilitySwitch.on
        let details = self.detailsFiled.text!
        let bid = self.currentBike!["bid"]!
        let s_lat = lat!
        let s_lng = lng!
        
        
        let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/editBike/" + "\(bid)")!)
        request.HTTPMethod = "POST"
        
        let payload = "model=\(bikeModel)&address=\(address)&city=\(city)&state=\(state)&country=\(country)&postcode=\(postcode)&price=\(price)&available=\(availability)&details=\(details)&lat=\(s_lat)&lon=\(s_lng)"
        let payloadWithoutSpace = payload.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        request.HTTPBody = payloadWithoutSpace!.dataUsingEncoding(NSUTF8StringEncoding)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response: \(response)")
            let strData = NSString(data: (data)!, encoding: NSUTF8StringEncoding)
            print("Body: \(strData)")
            
            if let httpResponse = response as? NSHTTPURLResponse {
                if(httpResponse.statusCode == 200){
                    //sign up successfully
                    //all ui change must happen in main thread. I think the issue is that async http request is in different thread.
                    //so use this method to push code back to main thread
                    self.UploadRequest()
                    print("Saved!!!!!")
                }
            } else {
                assertionFailure("unexpected response")
            }
        })
        task.resume()
    }
    
    private func get_coordinate(addressALL: String){
        
        
        let encodedAddress = addressALL.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        let request = NSMutableURLRequest(URL: NSURL(string: "http://maps.googleapis.com/maps/api/geocode/json?address=" + encodedAddress!)!)
        request.HTTPMethod = "GET"
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response: \(response)")
            let strData = NSString(data: (data)!, encoding: NSUTF8StringEncoding)!
            print("Body: \(strData)")
            
            if let httpResponse = response as? NSHTTPURLResponse {
                if(httpResponse.statusCode == 200){
                    print("response success")
                    let jsonData: NSData = data! /* get your json data */
                    do{
                        let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
                        self.lat = jsonDict["results"]!![0]["geometry"]!!["location"]!!["lat"] as? Float
                        self.lng = jsonDict["results"]!![0]["geometry"]!!["location"]!!["lng"] as? Float
                        if (self.currentBike?.count == 0 ){
                            self.addBike()
                        }
                        else{
                            self.updateBike()
                        }

                        //self.usernameLabel.text = jsonDict["result"]!["user"]!!["username"] as? String
                        
                    }
                    catch{
                        print(">>>>> exception catched during geocoding")
                    }
                }
            } else {
                assertionFailure("unexpected response")
            }
            
        })
        task.resume()
        
    }
    
    @IBAction func editBike(sender: AnyObject) {
        let address =  self.addressField.text!
        let city = self.cityField.text!
        let state = self.stateField.text!
        
        get_coordinate(address + "," + city + ", " + state)

        

        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}