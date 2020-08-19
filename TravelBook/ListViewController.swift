//
//  ListViewController.swift
//  TravelBook
//
//  Created by Pelinsu Celebi on 18.08.2020.
//  Copyright © 2020 Pelinsu Celebi. All rights reserved.
//

import UIKit
import CoreData

class ListViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    var nameArray = [String]()
    var idArray = [UUID]()
    
    var chosenTitle = ""
    var chosenTitleID : UUID?
    
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewWillAppear(_ animated: Bool){
        
        NotificationCenter.default.addObserver(self,selector: #selector(getData), name: NSNotification.Name("newPlace"),object: nil)
        
    }
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        getData()
    }
    
    @objc func addButtonClicked() {
        
        chosenTitle = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
        
    }
    
   @objc func getData() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetchRequest)
            if results.count>0{
                
                self.nameArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false) //to ensure no duplicates
                
                
                for result in results as! [NSManagedObject]{
                    
                    if let title = result.value(forKey: "name") as? String{
                        
                        self.nameArray.append(title)
                        
                    }
                    if let id = result.value(forKey: "id") as? UUID{
                        
                        self.idArray.append(id)
                    }
                    tableView.reloadData()
                    
                    
                }
                
            }
            
        } catch {
            
            print("Error")
        }
        
    
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = nameArray[indexPath.row]
        chosenTitleID = idArray[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedTitleID = chosenTitleID
            
        }
    }
    
}

