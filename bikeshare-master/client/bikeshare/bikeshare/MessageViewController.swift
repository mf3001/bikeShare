//
//  MessageViewController.swift
//  bikeshare
//
//  Created by houlianglv on 5/12/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController, UITableViewDelegate,
    UITableViewDataSource {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var approveBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!

    var messages: [AnyObject] = []
    var rid: Int?
    var status: String?
    var username: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell2")
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let userName: String = prefs.stringForKey("USERNAME")! as String
        if userName == self.username {
            self.approveBtn.hidden = true
        }else if self.status == "pending" {
            self.approveBtn.setTitle("Approve", forState: .Normal)
        }else if self.status == "approved" {
            self.approveBtn.backgroundColor = UIColor.blueColor()
            self.approveBtn.setTitle("Complete", forState: .Normal)
        }else if self.status == "rejected" {
            self.approveBtn.backgroundColor = UIColor.redColor()
            self.approveBtn.setTitle("Rejected", forState: .Normal)
            self.approveBtn.enabled = false
        }else if self.status == "completed" {
            self.approveBtn.backgroundColor = UIColor.greenColor()
            self.approveBtn.setTitle("Completed", forState: .Normal)
            self.approveBtn.enabled = false
        }
        getMessagesJSON()
    }

    private func getMessagesJSON(){

        let urlstring = serverDomain + "/showMessages/" + String(self.rid!)
        let url = NSURL(string: urlstring.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            if let result = data{
                print(NSString(data: result, encoding: NSUTF8StringEncoding))
                do {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(result, options: .AllowFragments)
                    print(jsonResult)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.messages.removeAll()
                        for message in jsonResult["result"] as! [Dictionary<String, AnyObject>] {
                            self.messages.append(message)
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(),{
                        self.tableView.reloadData()
                    })
                } catch {
                    print("error serializing JSON: \(error)")
                }
            }
        }
        task.resume()

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell2")! as UITableViewCell
        let userName = self.messages[indexPath.row]["owner"]!!["username"] as! String
        let content = self.messages[indexPath.row]["message"] as! String
        cell.textLabel?.text = userName + ": " + content
        return cell
    }

    //actions
    
    @IBAction func onApproveTapped(sender: AnyObject) {
        if self.status == "pending" {
            let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/respondRequest")!)
            request.HTTPMethod = "POST"
            let payload = "rid=\(self.rid!)&respond=approved"
            request.HTTPBody = payload.dataUsingEncoding(NSUTF8StringEncoding)
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in

                print("Response: \(response)")
                let strData = NSString(data: (data)!, encoding: NSUTF8StringEncoding)
                print("Body: \(strData)")

                if let httpResponse = response as? NSHTTPURLResponse {
                    if(httpResponse.statusCode == 200){
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            //Create the AlertController
                            let actionSheetController: UIAlertController = UIAlertController(title: "Success", message: "You have approved the request!", preferredStyle: .Alert)
                            //Create and add the Cancel action
                            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                                self.dismissViewControllerAnimated(true, completion: nil)
                                self.approveBtn.backgroundColor = UIColor.blueColor()
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
        }else if self.status == "approved" {
            let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/respondRequest")!)
            request.HTTPMethod = "POST"
            let payload = "rid=\(self.rid!)&respond=completed"
            request.HTTPBody = payload.dataUsingEncoding(NSUTF8StringEncoding)
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in

                print("Response: \(response)")
                let strData = NSString(data: (data)!, encoding: NSUTF8StringEncoding)
                print("Body: \(strData)")

                if let httpResponse = response as? NSHTTPURLResponse {
                    if(httpResponse.statusCode == 200){
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            //Create the AlertController
                            let actionSheetController: UIAlertController = UIAlertController(title: "Success", message: "You have completed the transaction!", preferredStyle: .Alert)
                            //Create and add the Cancel action
                            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                                self.dismissViewControllerAnimated(true, completion: nil)
                                self.approveBtn.backgroundColor = UIColor.greenColor()
                                self.approveBtn.setTitle("Completed", forState: .Normal)
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

    }


    @IBAction func onSendTapped(sender: AnyObject) {
        if self.textField.text != nil && self.textField.text?.characters.count > 0{
            self.sendMessage(self.textField.text!)
        }
    }

    private func sendMessage(message: String){
        let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/sendMsg")!)
        request.HTTPMethod = "POST"
        let payload = "rid=\(self.rid!)&message=" + message
        request.HTTPBody = payload.dataUsingEncoding(NSUTF8StringEncoding)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in

            print("Response: \(response)")
            let strData = NSString(data: (data)!, encoding: NSUTF8StringEncoding)
            print("Body: \(strData)")

            if let httpResponse = response as? NSHTTPURLResponse {
                if(httpResponse.statusCode == 200){
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.textField.text = ""
                    }
                    self.getMessagesJSON()
                }
            } else {
                assertionFailure("unexpected response")
            }
        })
        task.resume()
        
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
