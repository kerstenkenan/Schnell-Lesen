//
//  BenutzerViewController.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 04.03.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import UIKit
import CoreData

class BenutzerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var namensListeTableView: UITableView!
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    lazy var frc : NSFetchedResultsController<Benutzer>? = {
        var resultController : NSFetchedResultsController<Benutzer>?
        let request : NSFetchRequest<Benutzer> = Benutzer.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "datum", ascending: false)]
        if let context = container?.viewContext {
            resultController = NSFetchedResultsController<Benutzer>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            resultController?.delegate = self
            do {
                try resultController?.performFetch()
            } catch let err {
                print("NSFetchedResultsController couldn't fetch any results: \(err)")
            }
        }
        return resultController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        namensListeTableView.dataSource = self
        namensListeTableView.delegate = self
        nameTextField.delegate = self
    }
    
    @IBAction func addButtonPushed(_ sender: Any) {
        addUser()
    }
    
    func addUser() {
        var schonVorhanden = false
        if let context = container?.viewContext {
            frc?.fetchedObjects?.forEach({ (benutzer) in
                if benutzer.name?.lowercased() == nameTextField.text?.lowercased() {
                    schonVorhanden = true
                }
                if benutzer.ausgewaehlt {
                    benutzer.ausgewaehlt = false
                }
            })
            try? context.save()
        }
        
        if nameTextField.text == "" || schonVorhanden {
            return
        } else {
            if let name = nameTextField.text {
                if let context = container?.viewContext {
                    let benutzer = Benutzer(context: context)
                    benutzer.name = name
                    benutzer.datum = NSDate()
                    benutzer.ausgewaehlt = true
                    deselectAllOthers(except: benutzer)
                    try? context.save()
                }
            }
        }
        namensListeTableView.reloadData()
        nameTextField.text = nil
    }
    
    func deselectAllOthers(except user: Benutzer) {
        frc?.fetchedObjects?.forEach({ (benutzer) in
            if benutzer != user {
                benutzer.ausgewaehlt = false
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            addUser()
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc?.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Benutzer", for: indexPath) as! BenutzerTableViewCell
        if let obj = frc?.object(at: indexPath) {
            cell.textLabel?.text = obj.name
            if obj.ausgewaehlt {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let context = container?.viewContext {
            let benutzer = frc?.object(at: indexPath)
            if let user = benutzer {
                if let cell = tableView.cellForRow(at: indexPath) {
                    if cell.accessoryType == .none {
                        cell.accessoryType = .checkmark
                        user.ausgewaehlt = true
                        deselectAllOthers(except: user)
                    } else {
                        cell.accessoryType = .none
                        user.ausgewaehlt = false
                    }
                }
            }
            try? context.save()
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let context = container?.viewContext {
                let benutzer = frc?.object(at: indexPath)
                if let user = benutzer {
                    context.delete(user)
                    print("deletion successfull")
                } else {
                    print("deletion failed")
                }
                try? context.save()
            }
        }
    }
}

extension BenutzerViewController {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let range = Range(range, in: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: range, with: string)
        
        return updatedText.count <= 16
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            namensListeTableView.deleteRows(at: [indexPath!], with: .fade)
            break
        case .insert:
            namensListeTableView.insertRows(at: [newIndexPath!], with: .fade)
            let newCell = namensListeTableView.cellForRow(at: newIndexPath!)
            newCell?.accessoryType = .checkmark
            namensListeTableView.reloadData()
        default: break
        }
    }
}
