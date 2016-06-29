//
//  BikeInfoViewController.swift
//  bikeshare
//
//  Created by houlianglv on 5/12/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit

class BikeInfoViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var messageView: UITextView!
    @IBOutlet weak var imageView: UIImageView!

    var bid: Int?
    var fromDate: NSDate?
    var toDate: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageView.text = "Hi, May I rent your bike?"
        self.messageView.layer.borderColor = UIColor.grayColor().CGColor
        self.messageView.layer.borderWidth = CGFloat(1)
        self.messageView.layer.cornerRadius = CGFloat(5)
        // Do any additional setup after loading the view.
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.getBikeInfo()
    }

    private func getBikeInfo(){
        let urlstring = serverDomain + "/getBike/" + String(self.bid!)
        let url = NSURL(string: urlstring.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
        print(url)

        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            if let bike = data{
                print(NSString(data: bike, encoding: NSUTF8StringEncoding))
                do {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(bike, options: .AllowFragments)
                    if let result = jsonResult["result"] as? Dictionary<String, AnyObject> {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.addressLabel.text = result["address"] as? String
                            self.nameLabel.text = result["model"] as? String
                            self.cityLabel.text = result["city"] as? String
                            self.priceLabel.text = String(result["price"] as! Double)
                            self.detailLabel.text = result["details"] as? String
                            self.ownerLabel.text = result["owner"]!["username"] as? String

                            if result["photos"]?.count > 0{
                                let imageURL = result["photos"]![0]?["url"] as! String
                                self.downLoadImage(imageURL)
                            }

                        }
                    }
                    print(jsonResult)
                } catch {
                    print("error serializing JSON: \(error)")
                }
            }
        }
        task.resume()
    }

    private func downLoadImage(imageURL: String){
        let url: NSURL = NSURL(string: imageURL)!
        print(url)
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                print(response?.suggestedFilename ?? "")
                print("Download Finished")
                self.imageView.image = UIImage(data: data)
            }
        }.resume()
        
    }

    private func processDateToString(date: NSDate) -> String{
        let RFC3339DateFormatter = NSDateFormatter()
        RFC3339DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 14400)

        return RFC3339DateFormatter.stringFromDate(date)
    }

    //actions

    @IBAction func onSendRequestTapped(sender: AnyObject) {
        print("hello world")
        let from_date = processDateToString(self.fromDate!)
        let to_date = processDateToString(self.toDate!)
        let bid = self.bid
        let message = self.messageView.text

        let request = NSMutableURLRequest(URL: NSURL(string: serverDomain + "/sendRequest")!)
        request.HTTPMethod = "POST"
        let payload = "bid=\(bid!)&from_date=" + from_date + "&to_date=" + to_date + "&message=" + message
        request.HTTPBody = payload.dataUsingEncoding(NSUTF8StringEncoding)
        let session = NSURLSession.sharedSession()

        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response: \(response)")
            let strData = NSString(data: (data)!, encoding: NSUTF8StringEncoding)
            print("Body: \(strData)")

            if let httpResponse = response as? NSHTTPURLResponse {
                if(httpResponse.statusCode == 200){
                    //send request successfully
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        let actionSheetController: UIAlertController = UIAlertController(title: "Success", message: "You have made the request successfully", preferredStyle: .Alert)
                        let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                            self.navigationController?.popViewControllerAnimated(true)
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





    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
