//
//  LoginViewController.swift
//  bikeshare
//
//  Created by houlianglv on 4/16/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit


class LoginViewController: UIViewController {


    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var passwordText: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("login view")

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    @IBAction func loginTapped(sender: UIButton) {
        //authentication code
        let username = usernameText.text!
        let password = passwordText.text!
        if(username == "" || password == ""){
            //Create the AlertController
            let actionSheetController: UIAlertController = UIAlertController(title: "Alert", message: "Login failed", preferredStyle: .Alert)

            //Create and add the Cancel action
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                //Do some stuff
            }
            actionSheetController.addAction(cancelAction)

            //Present the AlertController
            self.presentViewController(actionSheetController, animated: true, completion: nil)

        }else{
            let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/userLogin")!)
            request.HTTPMethod = "POST"
            let payload = "username=\(username)&password=\(password)"
            request.HTTPBody = payload.dataUsingEncoding(NSUTF8StringEncoding)
            let session = NSURLSession.sharedSession()

            let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                print("Response: \(response)")
                let strData = NSString(data: (data)!, encoding: NSUTF8StringEncoding)
                print("Body: \(strData)")

                if let httpResponse = response as? NSHTTPURLResponse {
                    if(httpResponse.statusCode == 200){
                        //sign in successfully
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
                            prefs.setObject(username, forKey: "USERNAME")
                            prefs.setBool(true, forKey: "ISLOGGEDIN")
                            prefs.synchronize()
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }

                    }else{
                        NSOperationQueue.mainQueue().addOperationWithBlock{
                            //Create the AlertController
                            let actionSheetController: UIAlertController = UIAlertController(title: "Login failed", message: "Login failed. Please input valid username or password", preferredStyle: .Alert)
                            //Create and add the Cancel action
                            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in }
                            actionSheetController.addAction(cancelAction)
                            //Present the AlertController
                            self.presentViewController(actionSheetController, animated: true, completion: nil)
                        }
                    }
                } else {
                    assertionFailure("unexpected response")
                }
                
                
            })
            task.resume()


        }

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
