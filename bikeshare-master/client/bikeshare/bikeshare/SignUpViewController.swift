//
//  SignUpViewController.swift
//  bikeshare
//
//  Created by houlianglv on 4/16/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit




class SignUpViewController: UIViewController {

    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var firstNameText: UITextField!
    @IBOutlet weak var lastNameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var confirmPwdText: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    @IBAction func signupTapped(sender: UIButton) {
        //sign up
        if(passwordText.text != confirmPwdText.text){
            //Create the AlertController
            let actionSheetController: UIAlertController = UIAlertController(title: "Alert", message: "confirmation password doesn't match the password", preferredStyle: .Alert)

            //Create and add the Cancel action
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                //Do some stuff
            }
            actionSheetController.addAction(cancelAction)

            //Present the AlertController
            self.presentViewController(actionSheetController, animated: true, completion: nil)
            return
        }

        let username = usernameText.text!
        let password = passwordText.text!
        let email = emailText.text!
        let firstName = firstNameText.text!
        let lastName = lastNameText.text!
        let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/register")!)
        request.HTTPMethod = "POST"
        let payload = "username=\(username)&password=\(password)&email=\(email)&firstname=\(firstName)&lastname=\(lastName)"
        request.HTTPBody = payload.dataUsingEncoding(NSUTF8StringEncoding)
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
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        //Create the AlertController
                        let actionSheetController: UIAlertController = UIAlertController(title: "Success", message: "You have registered successfully", preferredStyle: .Alert)
                        //Create and add the Cancel action
                        let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
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

    @IBAction func gotoSignIn(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
