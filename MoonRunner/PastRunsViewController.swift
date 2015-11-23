//
//  PastRunsViewController.swift
//  MoonRunner
//
//  Created by Santo Chen on 11/22/15.
//  Copyright © 2015 Zedenem. All rights reserved.
//

import UIKit
import CoreData

class PastRunsViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var run = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Past Runs"
        tableView.registerClass(UITableViewCell.self,
            forCellReuseIdentifier: "Cell")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Run")
        
        //3
        do {
            let results = try managedContext!.executeFetchRequest(fetchRequest)
            run = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func tableView(tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
            print (run.count)
            return run.count
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath
        indexPath: NSIndexPath) -> UITableViewCell {
            
            let cell =
            tableView.dequeueReusableCellWithIdentifier("Cell")
            
            let oneRun = run[indexPath.row]
            
            cell!.textLabel!.text =
                oneRun.valueForKey("timestamp") as? String
            
            return cell!
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
