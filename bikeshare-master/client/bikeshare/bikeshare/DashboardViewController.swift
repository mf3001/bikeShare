//
//  DashboardViewController.swift
//  bikeshare
//
//  Created by houlianglv on 5/5/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController, UITableViewDelegate,
    UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    var requests: [AnyObject] = []
    var selectedTransaction: AnyObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell3")
        // Do any additional setup after loading the view.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? TransactionViewController{
            vc.transction = self.selectedTransaction
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        getMyRequestsJSON()
    }

    private func getMyRequestsJSON(){
        let urlstring = serverDomain + "/getMyRequests"
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
        return requests.count
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedTransaction = self.requests[indexPath.row]
        self.performSegueWithIdentifier("goto_transaction", sender: self)
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell3")! as UITableViewCell
        let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let clientUsername:String = prefs.stringForKey("USERNAME")! as String
        print(indexPath.row)
        let ownerName = self.requests[indexPath.row]["bike"]!!["owner"]!!["username"] as! String
        let userName = self.requests[indexPath.row]["user"]!!["username"] as! String
        var cellName = ""
        if clientUsername == ownerName {
            cellName = userName
        }else{
            cellName = ownerName
        }
        cell.textLabel?.text = cellName
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
