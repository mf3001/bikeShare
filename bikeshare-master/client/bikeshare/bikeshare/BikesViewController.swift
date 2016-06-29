//
//  BikesViewController.swift
//  bikeshare
//
//  Created by houlianglv on 5/5/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit



class BikesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    
    @IBOutlet weak var tableView: UITableView!

    
// These strings will be the data for the table view cells
    let animals: [String] = ["Horse", "Cow", "Camel", "Sheep", "Goat"]
    
    let cellReuseIdentifier = "cell"
    
    var bikeNames: [String] = []
    
    var allBikes: [Dictionary<String, AnyObject>] = []
    
    var currentBike: Dictionary<String, AnyObject>?
    
    

    
//    override func viewDidLoad() {
//        super.viewDidLoad()
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        // It is possible to do the following three things in the Interface Builder
        // rather than in code if you prefer.

        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        ///////////////////
        
        
        let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/getAllBikes")!)
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
                        self.allBikes = (jsonDict["result"]! as? [Dictionary<String, AnyObject>])! //as! [NSDictionary]
                        //let bikeName_str = self.allBikes[0]["model"]
                        print("bike___count___:\(self.allBikes.count)")
                        //self.usernameLabel.text = jsonDict["result"]!["user"]!!["username"] as? String

                        dispatch_async(dispatch_get_main_queue(),{
                            self.tableView.reloadData()
                        })
                    }
                    catch{
                        print(">>>>> exception catched")
                    }
                }
            } else {
                assertionFailure("unexpected response")
            }
            
        })
        task.resume()
        
        


        ///////////////////
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // number of rows in table view
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print ("allBikes count:\(self.allBikes.count)")
        //return self.animals.count
        return self.allBikes.count
    }
    
    // create a cell for each table view row
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier) as UITableViewCell!
        
        //cell.textLabel?.text = self.animals[indexPath.row]
        cell.textLabel?.text = self.allBikes[indexPath.row]["model"] as! String
        print("loading>>>>>")
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        self.currentBike = self.allBikes[indexPath.row]
        self.performSegueWithIdentifier("goto_bikeDetails", sender: self)
        print("You tapped cell number \(indexPath.row).")
//        dispatch_async(dispatch_get_main_queue(),{
//            self.tableView.reloadData()
//        })
    }
    
    
    @IBAction func addBike(sender: AnyObject) {
        
        self.currentBike = [:]
        self.performSegueWithIdentifier("goto_bikeDetails", sender: self)
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? BikeDetailsViewController{
            print("prepare for detail segue")
            vc.currentBike = self.currentBike
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
//
//    @IBAction func onTestTapped(sender: UIButton) {
//        testBtn.setTitle("tapped", forState: UIControlState.Normal)
//    }
}
