//
//  ProfileViewController.swift
//  bikeshare
//
//  Created by houlianglv on 5/5/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit
import Foundation

class ProfileViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!
     
    
    @IBOutlet weak var firstNameText: UITextField!
    
    @IBOutlet weak var lastNameText: UITextField!
    
    
    @IBOutlet weak var emailText: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        
        let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/getProfile")!)
        request.HTTPMethod = "GET"
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response: \(response)")
            let strData = NSString(data: (data)!, encoding: NSUTF8StringEncoding)!
            print("Body: \(strData)")
            

            
            
            if let httpResponse = response as? NSHTTPURLResponse {
                if(httpResponse.statusCode == 200){
                    //sign up successfully
                    //all ui change must happen in main thread. I think the issue is that async http request is in different thread.
                    //so use this method to push code back to main thread
                    print("response success")
                    let jsonData: NSData = data! /* get your json data */
                    do{
                        let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as! NSDictionary
                        print ("jsonDict: \(jsonDict)")
                        
                        let username_str = jsonDict["result"]!["user"]!!["username"] as! String
                        print("username______:\(username_str)")
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.usernameLabel.text = jsonDict["result"]!["user"]!!["username"] as? String
                            self.firstNameText.placeholder = jsonDict["result"]!["user"]!!["firstname"] as? String
                            self.lastNameText.placeholder = jsonDict["result"]!["user"]!!["lastname"] as? String
                            self.emailText.placeholder = jsonDict["result"]!["user"]!!["email"] as? String
                        }
                        
                    }
                    catch{
                        print(">>>>>")
                    }
                }
            } else {
                assertionFailure("unexpected response")
            }
            
        })
        task.resume()
        
        
    }
    
    
    @IBAction func BasicInfoSaveBtn(sender: AnyObject) {
        let firstName = firstNameText.text
        let lastName = lastNameText.text
        let email = emailText.text
        
    }
    
    @IBAction func logoutBtn(sender: AnyObject) {
        let appDomain = NSBundle.mainBundle().bundleIdentifier
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
        self.navigationController?.popViewControllerAnimated(true)
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
