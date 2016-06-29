//
//  MessagesViewController.swift
//  bikeshare
//
//  Created by houlianglv on 5/5/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit

class MessagesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var messageTableView: UITableView!

    var requests: [AnyObject] = []
    var selectedRid: Int?
    var selectedStatus: String?
    var username: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageTableView.delegate = self
        self.messageTableView.dataSource = self
        self.messageTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        getAllRequestJSON()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? MessageViewController{
            vc.rid = self.selectedRid
            vc.status = self.selectedStatus
            vc.username = self.username
        }
    }

    private func getAllRequestJSON(){
        let urlstring = serverDomain + "/getRequests"
        let url = NSURL(string: urlstring.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            if let result = data{
                print(NSString(data: result, encoding: NSUTF8StringEncoding))
                do {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(result, options: .AllowFragments)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.requests.removeAll()
                        for request in jsonResult["result"] as! [Dictionary<String, AnyObject>] {
                            self.requests.append(request)
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(),{
                        self.messageTableView.reloadData()
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

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.requests.count;
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("You selected cell #\(indexPath.row)!")
        self.selectedRid = self.requests[indexPath.row]["rid"] as? Int
        self.selectedStatus = self.requests[indexPath.row]["status"] as? String
        self.username = self.requests[indexPath.row]["user"]!!["username"] as? String
        self.performSegueWithIdentifier("goto_request", sender: self)
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.messageTableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        let username = self.requests[indexPath.row]["user"]!!["username"] as! String
        let status = "status: " + (self.requests[indexPath.row]["status"] as! String)
        let fromDate = "from: " + (self.requests[indexPath.row]["from_date"] as! String)
        let toDate = "to: " + (self.requests[indexPath.row]["to_date"] as! String)
        let text = username + "    " + status + "    " + fromDate + "    " + toDate
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        cell.textLabel!.text = text
        return cell
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
